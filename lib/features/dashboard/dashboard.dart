import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../attendance/attendance.dart';
import '../leave/apply_leave.dart';
import 'dashboard_auth.dart';
import 'dashboard_employee_provider.dart';
import '../../core/models/employee_details.dart';
import '../../core/services/auth_service.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});
  @override
  ConsumerState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> with TickerProviderStateMixin {
  late AnimationController _punchController;
  late AnimationController _breathingController;
  late Timer _timer;

  bool _isCheckingLocation = false;
  bool _isInsideOffice = false;
  String? _geoError;

  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _punchController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _breathingController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dashboardEmployeeProvider.notifier).load();
      _evaluateGeofenceOnceIfNeeded();
    });
  }

  @override
  void dispose() {
    _punchController.dispose();
    _breathingController.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Geofence helpers (uses distanceBetween meters)
  double _radiusToMeters(int radius, String unit) {
    switch (unit.toLowerCase()) {
      case 'meter':
      case 'meters':
        return radius.toDouble();
      case 'km':
      case 'kilometer':
      case 'kilometers':
        return radius * 1000.0;
      default:
        return radius.toDouble();
    }
  }

  Future<bool> isInsideOfficeArea({
    required double userLat,
    required double userLng,
    required double officeLat,
    required double officeLng,
    required int radius,
    required String radiusUnit,
  }) async {
    final d = Geolocator.distanceBetween(userLat, userLng, officeLat, officeLng);
    final allow = _radiusToMeters(radius, radiusUnit);
    return d <= allow;
  }

  Future _evaluateGeofenceOnceIfNeeded() async {
    final details = ref.read(dashboardEmployeeProvider).details;
    if (details == null) return;

    final isWFO = details.todayWorkLocation.toLowerCase() == 'work_from_office';
    if (!isWFO) {
      setState(() {
        _isInsideOffice = false;
        _geoError = null;
      });
      return;
    }
    await _fetchAndEvaluateLocation(details.officeLocation);
  }

  Future _fetchAndEvaluateLocation(OfficeLocation? office) async {
    if (office == null) {
      setState(() {
        _isInsideOffice = false;
        _geoError = 'Office location not configured';
      });
      return;
    }

    setState(() {
      _isCheckingLocation = true;
      _geoError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isCheckingLocation = false;
          _geoError = 'Location services are disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isCheckingLocation = false;
            _geoError = 'Location permission denied';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isCheckingLocation = false;
          _geoError = 'Location permission permanently denied';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final inside = await isInsideOfficeArea(
        userLat: pos.latitude,
        userLng: pos.longitude,
        officeLat: double.tryParse(office.latitude) ?? 0,
        officeLng: double.tryParse(office.longitude) ?? 0,
        radius: office.radius,
        radiusUnit: office.radiusUnit,
      );

      setState(() {
        _isInsideOffice = inside;
        _isCheckingLocation = false;
        _geoError = null;
      });
    } catch (e) {
      setState(() {
        _isCheckingLocation = false;
        _geoError = 'Unable to get location';
      });
    }
  }

  Future _refreshAll() async {
    await ref.read(dashboardEmployeeProvider.notifier).load();
    await _evaluateGeofenceOnceIfNeeded();
  }

  // Punch In (unchanged)
  Future _handlePunchInTap(EmployeeDetailsData? details) async {
    try {
      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee info not loaded')));
        return;
      }

      final todayWorkingStatus = (details.todayWorkingStatus ?? 'not_present').toLowerCase();
      if (todayWorkingStatus != 'not_present') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: ${details.todayWorkingStatus}')));
        return;
      }

      final workLocationStatus = details.todayWorkLocation.toLowerCase() == 'work_from_office' ? 'WFO' : 'WFH';
      final requiresOfficePresence = workLocationStatus == 'WFO';
      if (requiresOfficePresence && !_isInsideOffice) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Be inside office area to punch in')));
        return;
      }

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing employee credentials')));
        return;
      }

      double lat = 0, lng = 0;
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        if (requiresOfficePresence) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location required for WFO')));
          return;
        }
      }

      final now = DateTime.now();
      final todayDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final punchInTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final res = await AuthService.punchIn(
        todayDate: todayDate,
        punchInTime: punchInTime,
        empId: empId,
        secure: secure,
        punchInLat: lat,
        punchInLong: lng,
        workLocationStatus: workLocationStatus,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message)));
      await ref.read(dashboardEmployeeProvider.notifier).load();
      await _evaluateGeofenceOnceIfNeeded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch in failed')));
    }
  }

  // NEW: Punch Out handler
  Future _handlePunchOutTap(EmployeeDetailsData? details) async {
    try {
      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee info not loaded')));
        return;
      }

      // Only when already punched in
      final todayWorkingStatus = (details.todayWorkingStatus ?? 'not_present').toLowerCase();
      final isPunchedIn = todayWorkingStatus != 'not_present';
      if (!isPunchedIn) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not punched in yet')));
        return;
      }

      // Geofence check for WFO
      final isWFO = details.todayWorkLocation.toLowerCase() == 'work_from_office';
      if (isWFO) {
        final office = details.officeLocation;
        if (office == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Office location not configured')));
          return;
        }

        setState(() {
          _isCheckingLocation = true;
          _geoError = null;
        });

        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            setState(() {
              _isCheckingLocation = false;
              _geoError = 'Location services are disabled';
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled')));
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              setState(() {
                _isCheckingLocation = false;
                _geoError = 'Location permission denied';
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
              return;
            }
          }
          if (permission == LocationPermission.deniedForever) {
            setState(() {
              _isCheckingLocation = false;
              _geoError = 'Location permission permanently denied';
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied')));
            return;
          }

          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
          final inside = await isInsideOfficeArea(
            userLat: pos.latitude,
            userLng: pos.longitude,
            officeLat: double.tryParse(office.latitude) ?? 0,
            officeLng: double.tryParse(office.longitude) ?? 0,
            radius: office.radius,
            radiusUnit: office.radiusUnit,
          );

          setState(() {
            _isInsideOffice = inside;
            _isCheckingLocation = false;
            _geoError = inside ? null : 'Outside office area';
          });

          if (!inside) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not in office location')));
            return;
          }
        } catch (e) {
          setState(() {
            _isCheckingLocation = false;
            _geoError = 'Unable to get location';
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to get location')));
          return;
        }
      }

      // Build dynamic body
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing employee credentials')));
        return;
      }

      final now = DateTime.now();
      final todayDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final punchOutTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final res = await AuthService.punchOut(
        todayDate: todayDate,
        punchOutTime: punchOutTime,
        empId: empId,
        secure: secure,
      );

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete Today Work')));
        // Reload to get todayWorkingStatus
        await ref.read(dashboardEmployeeProvider.notifier).load();
        setState(() {}); // ensure rebuild
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isNotEmpty ? res.message : 'Punch out failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punch out failed')));
    }
  }

  // Lunch In/Out and Break handlers remain as-is...

  String _formatDuration(Duration d) => '${d.inHours}h ${d.inMinutes % 60}m';

  String _getCurrentTime() {
    final now = DateTime.now();
    final h = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final m = now.minute.toString().padLeft(2, '0');
    final p = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(enhancedDashboardProvider);
    final notifier = ref.read(enhancedDashboardProvider.notifier);
    final emp = ref.watch(dashboardEmployeeProvider);
    final details = emp.details;

    // Derive statuses
    final todayWorkingStatus = (details?.todayWorkingStatus ?? 'not_present').toLowerCase();
    final isPunchedIn = todayWorkingStatus != 'not_present' && todayWorkingStatus != 'punch_out';
    final isLunch = todayWorkingStatus == 'lunch';
    final isOnBreak = data.isOnBreak;
    final isWorkComplete = todayWorkingStatus == 'punch_out';

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: _primaryPurple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              children: [
                _buildPrimaryHeader(details, emp.loading, emp.error),
                const SizedBox(height: 24),
                _buildOfficeAddressCard(details),
                const SizedBox(height: 24),

                // Punch card shows "Today Work Complete" when status == punch_out
                _buildPunchCard(
                  isPunchedIn,
                  isWorkComplete
                      ? 'WORK COMPLETE'
                      : isLunch
                      ? 'ON TIFFIN'
                      : isOnBreak
                      ? 'ON BREAK'
                      : isPunchedIn
                      ? 'WORKING'
                      : 'TAP TO START',
                  isWorkComplete
                      ? 'TODAY WORK COMPLETE'
                      : (details?.todayWorkingStatus ?? (isPunchedIn ? 'present' : 'not_present'))
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  isWorkComplete
                      ? _textLight
                      : isLunch
                      ? _accentOrange
                      : isOnBreak
                      ? _accentBlue
                      : isPunchedIn
                      ? _accentGreen
                      : _textLight,
                  notifier,
                  requiresOfficePresence: (details?.todayWorkLocation.toLowerCase() == 'work_from_office'),
                  details: details,
                  workCompleted: isWorkComplete,
                ),

                const SizedBox(height: 24),
                _buildActionGrid(isPunchedIn: isPunchedIn, isLunch: isLunch, isOnBreak: isOnBreak, notifier: notifier),
                const SizedBox(height: 24),
                _buildTodayMetrics(data.totalTiffinTime, data.totalBreakTime, data),
                const SizedBox(height: 24),
                _buildTodayTasks(),
                const SizedBox(height: 24),
                _buildRecentActivity(data.activities),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryHeader(EmployeeDetailsData? details, bool loading, String? error) {
    final status = details?.status ?? '—';
    final isActive = (status.toLowerCase() == 'active');
    final name = details?.name?.isNotEmpty == true ? details!.name : '—';
    final empId = details?.employeeId?.isNotEmpty == true ? details!.employeeId : '—';
    final designation = details?.designationName?.isNotEmpty == true ? details!.designationName : '';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryPurple, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _primaryPurple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))]),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_getGreeting(), style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(loading ? 'Loading...' : name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  Text(designation.isEmpty ? empId : '$designation • $empId',
                      overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: (isActive ? _accentGreen : _errorRed).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isActive ? _accentGreen : _errorRed).withValues(alpha: 0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: isActive ? _accentGreen : _errorRed, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(isActive ? 'Active' : (status.isNotEmpty ? status : '—'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(_getCurrentDate(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(details?.todayWorkLocation.replaceAll('_', ' ') ?? 'Remote', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
            ]),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _errorRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: _errorRed.withValues(alpha: 0.3))),
                child: Text(error, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficeAddressCard(EmployeeDetailsData? details) {
    final loc = details?.officeLocation;
    final locationText = loc == null ? 'No office location assigned' : '${loc.locationName} (${loc.locationType})';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentOrange.withValues(alpha: 0.3), width: 1),
          boxShadow: [BoxShadow(color: _accentOrange.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.location_on_rounded, color: _accentOrange, size: 24)),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [const Text('Office Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textLight, letterSpacing: 0.5)), const SizedBox(height: 6), Text(locationText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark))])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentGreen.withValues(alpha: 0.3), width: 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _accentGreen, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('HQ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accentGreen, letterSpacing: 0.5))
            ])),
      ]),
    );
  }

  // Modified to accept workCompleted to switch UI text
  Widget _buildPunchCard(
      bool isPunchedIn,
      String subtitle,
      String statusMessage,
      Color statusColor,
      EnhancedDashboardNotifier notifier, {
        required bool requiresOfficePresence,
        required EmployeeDetailsData? details,
        bool workCompleted = false,
      }) {
    final bool showGeoGate = requiresOfficePresence;
    final bool canPunchIn = showGeoGate ? _isInsideOffice : true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 25, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule_rounded, color: _textLight, size: 18), const SizedBox(width: 8), Text(_getCurrentTime(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _textDark, letterSpacing: -0.5))]),
            ),
          ]),
          const SizedBox(height: 24),

          // If day complete, show final text instead of a tappable button
          if (workCompleted)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: _accentGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Today Work Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _accentGreen)),
                ),
                const SizedBox(height: 16),
              ],
            )
          else
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [isPunchedIn ? _errorRed : _primaryPurple, isPunchedIn ? const Color(0xFFFF6B6B) : _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isCheckingLocation
                      ? null
                      : () async {
                    _punchController.forward().then((_) => _punchController.reverse());
                    if (!isPunchedIn) {
                      if (canPunchIn) {
                        await _handlePunchInTap(details);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Be inside office area to punch in')));
                      }
                    } else {
                      await _handlePunchOutTap(details);
                    }
                  },
                  borderRadius: BorderRadius.circular(70),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(isPunchedIn ? Icons.logout_rounded : Icons.login_rounded, size: 36, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(isPunchedIn ? 'Punch Out' : (canPunchIn ? 'Punch In' : 'On the Way'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                            _isCheckingLocation
                                ? 'CHECKING...'
                                : isPunchedIn
                                ? 'TAP TO START'
                                : (showGeoGate ? 'WITHIN OFFICE AREA REQUIRED' : 'TAP TO START'),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1))),
                  ]),
                ),
              ),
            ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(statusMessage, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid({required bool isPunchedIn, required bool isLunch, required bool isOnBreak, required EnhancedDashboardNotifier notifier}) {
    final canStartBreak = isPunchedIn && !isLunch;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _buildActionCard(isOnBreak ? 'Break End' : 'Break Time', Icons.coffee_rounded, _accentBlue, isOnBreak, canStartBreak || isOnBreak, () async {
                if (isLunch) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End lunch before break')));
                  return;
                }
                if (isOnBreak) {
                  await _handleBreakOutTap(notifier);
                } else {
                  await _handleBreakInTap(notifier);
                }
              })),
          const SizedBox(width: 12),
          Expanded(
              child: _buildActionCard(isLunch ? 'Lunch End' : 'Tiffin Time', Icons.restaurant_rounded, _accentOrange, isLunch, isPunchedIn, () async {
                if (isLunch) {
                  await _handleLunchOutTap();
                } else {
                  await _handleLunchInTap();
                }
              })),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildActionCard('Apply Leave', Icons.event_busy_rounded, _errorRed, false, true, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeavePage())))),
          const SizedBox(width: 12),
          Expanded(child: _buildActionCard('View Reports', Icons.analytics_rounded, _accentGreen, false, true, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePage())))),
        ]),
        if (!isPunchedIn) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _accentOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accentOrange.withValues(alpha: 0.3))),
            child: Row(children: [Icon(Icons.info_outline_rounded, color: _accentOrange, size: 16), const SizedBox(width: 8), const Expanded(child: Text('Punch in first to take breaks or tiffin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accentOrange)))]),
          ),
        ],
      ]),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, bool isActive, bool isEnabled, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Material(
        color: isActive ? color : isEnabled ? _cardWhite : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.25) : isEnabled ? color.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: isActive ? Colors.white : isEnabled ? color : Colors.grey, size: 26)),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isActive ? Colors.white : isEnabled ? _textDark : Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(isActive ? 'ACTIVE' : isEnabled ? 'TAP TO START' : 'UNAVAILABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? Colors.white.withValues(alpha: 0.7) : isEnabled ? _textLight : Colors.grey, letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMetrics(Duration tiffin, Duration breaks, PunchData data) {
    final work = DashboardAuthService.calculateWorkingHours(data);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _borderColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today\'s Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 20),
        _buildMetricRow('Total Work Time', _formatDuration(work), Icons.timer_rounded, _primaryPurple),
        const SizedBox(height: 16),
        _buildMetricRow('Break Duration', _formatDuration(breaks), Icons.coffee_rounded, _accentBlue),
        const SizedBox(height: 16),
        _buildMetricRow('Tiffin Duration', _formatDuration(tiffin), Icons.restaurant_rounded, _accentOrange),
      ]),
    );
  }

  Widget _buildMetricRow(String title, String value, IconData icon, Color color) {
    return Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 16),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textDark))),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildTodayTasks() => const SizedBox.shrink();
  Widget _buildRecentActivity(List activities) => const SizedBox.shrink();

  // Existing Break/Lunch handlers omitted here for brevity (unchanged)
  Future _handleLunchInTap() async {/* existing code */}
  Future _handleLunchOutTap() async {/* existing code */}
  Future _handleBreakInTap(EnhancedDashboardNotifier notifier) async {/* existing code */}
  Future _handleBreakOutTap(EnhancedDashboardNotifier notifier) async {/* existing code */}
}
