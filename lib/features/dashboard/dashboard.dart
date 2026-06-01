import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/daily_activity_model.dart';
import '../../core/models/employee_details.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/policy_service.dart';
import '../policy/policy_list_page.dart';
import '../onboarding/welcome_modal.dart';
import 'dashboard_auth.dart';
import 'dashboard_employee_provider.dart';
import '../../core/utils/logout_handler.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});
  @override
  ConsumerState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard>
    with TickerProviderStateMixin {
  late AnimationController _punchController;
  late AnimationController _breathingController;
  late Timer _timer;

  bool _isCheckingLocation = false;
  bool _isInsideOffice = false;
  String? _geoError;

  // Daily activity data
  DailyActivityData? _todayActivity;
  bool _loadingTodayActivity = false;

  // Punch action loading states
  bool _isPunchingIn = false;
  bool _isPunchingOut = false;
  bool _isLunchIn = false;
  bool _isLunchOut = false;
  bool _isBreakIn = false;
  bool _isBreakOut = false;

  bool _handledEmployeeError = false;

  /// Returns true only for actual authentication/authorization errors
  bool _isAuthError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('unauthorized') ||
        lower.contains('unauthenticated') ||
        lower.contains('token') ||
        lower.contains('401') ||
        lower.contains('not authenticated') ||
        lower.contains('token_mismatch');
  }

  double _actionSplit = 0.5;

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
    _punchController = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _breathingController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this)
          ..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dashboardEmployeeProvider.notifier).load();
      _evaluateGeofenceOnceIfNeeded();
      _fetchTodayActivity();
      _checkFirstTimePermissions();
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

  Future<void> _showPolicyDialog({
    required String title,
    required String message,
    required String primaryText,
    required VoidCallback onPrimary,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient header
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.policy_outlined, color: Color(0xFF4338CA)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  message,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Later',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4338CA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onPrimary();
                          },
                          child: Text(
                            primaryText,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> isInsideOfficeArea({
    required double userLat,
    required double userLng,
    required double officeLat,
    required double officeLng,
    required int radius,
    required String radiusUnit,
  }) async {
    final d =
        Geolocator.distanceBetween(userLat, userLng, officeLat, officeLng);
    final allow = _radiusToMeters(radius, radiusUnit);
    return d <= allow;
  }

  Future _evaluateGeofenceOnceIfNeeded() async {
    if (!mounted) return; // Check if widget is still mounted
    final details = ref.read(dashboardEmployeeProvider).details;
    if (details == null) return;

    final isWFO = details.todayWorkLocation.toLowerCase() == 'work_from_office';
    if (!isWFO) {
      if (mounted) {
        setState(() {
          _isInsideOffice = false;
          _geoError = null;
        });
      }
      return;
    }
    await _fetchAndEvaluateLocation(details.officeLocation);
  }

  Future _fetchAndEvaluateLocation(OfficeLocation? office) async {
    if (office == null) {
      if (mounted) {
        setState(() {
          _isInsideOffice = false;
          _geoError = 'Office location not configured';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingLocation = true;
        _geoError = null;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _geoError = 'Location services are disabled';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isCheckingLocation = false;
              _geoError = 'Location permission denied';
            });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _geoError = 'Location permission permanently denied';
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      final inside = await isInsideOfficeArea(
        userLat: pos.latitude,
        userLng: pos.longitude,
        officeLat: double.tryParse(office.latitude) ?? 0,
        officeLng: double.tryParse(office.longitude) ?? 0,
        radius: office.radius,
        radiusUnit: office.radiusUnit,
      );

      if (mounted) {
        setState(() {
          _isInsideOffice = inside;
          _isCheckingLocation = false;
          _geoError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _geoError = 'Unable to get location';
        });
      }
    }
  }

  Future _refreshAll() async {
    if (!mounted) return; // Check if widget is still mounted
    await ref.read(dashboardEmployeeProvider.notifier).load();
    await _evaluateGeofenceOnceIfNeeded();
    await _fetchTodayActivity();
  }

  Future<void> _checkFirstTimePermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shouldShowPermissions =
          prefs.getBool('show_permissions_after_dashboard') ?? false;

      if (shouldShowPermissions) {
        // Clear the flag
        await prefs.remove('show_permissions_after_dashboard');

        // Show permissions dialog after a short delay
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          _showPermissionsDialog();
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WelcomeModal(),
    );
  }

  Future<void> _fetchTodayActivity() async {
    if (!mounted) return;

    setState(() {
      _loadingTodayActivity = true;
    });

    try {
      final user = await AuthService.getSavedUser();
      if (user == null || user.employeeId.isEmpty) {
        return;
      }

      final secure = await AuthService.getSecure();
      if (secure == null || secure.isEmpty) {
        return;
      }

      final dailyActivity = await AttendanceService.fetchDailyActivity(
        empId: user.employeeId,
        date: DateTime.now(),
        secure: secure,
      );

      if (!mounted) return;

      if (dailyActivity != null && dailyActivity.success) {
        setState(() {
          _todayActivity = dailyActivity.data;
        });
      } else {
        setState(() {
          _todayActivity = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todayActivity = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTodayActivity = false;
        });
      }
    }
  }

  // Punch In with loading state
  Future _handlePunchInTap(EmployeeDetailsData? details) async {
    if (_isPunchingIn) return; // Prevent multiple taps

    try {
      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee info not loaded')));
        return;
      }

      final todayWorkingStatus =
          (details.todayWorkingStatus ?? 'not_present').toLowerCase();
      if (todayWorkingStatus != 'not_present') {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status: ${details.todayWorkingStatus}')));
        return;
      }

      final workLocationStatus =
          details.todayWorkLocation.toLowerCase() == 'work_from_office'
              ? 'WFO'
              : 'WFH';
      final requiresOfficePresence = workLocationStatus == 'WFO';
      if (requiresOfficePresence && !_isInsideOffice) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Be inside office area to punch in')));
        return;
      }

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }

      // Set loading state
      setState(() {
        _isPunchingIn = true;
      });

      double lat = 0, lng = 0;
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        if (requiresOfficePresence) {
          setState(() {
            _isPunchingIn = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location required for WFO')));
          return;
        }
      }

      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final punchInTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final res = await AuthService.punchIn(
        todayDate: todayDate,
        punchInTime: punchInTime,
        empId: empId,
        secure: secure,
        punchInLat: lat,
        punchInLong: lng,
        workLocationStatus: workLocationStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
        await ref.read(dashboardEmployeeProvider.notifier).load();
        await _evaluateGeofenceOnceIfNeeded();
        await _fetchTodayActivity();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Punch in failed')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunchingIn = false;
        });
      }
    }
  }

  // NEW: Confirm and perform Punch Out (shows confirm dialog + spinner while API runs)
  Future _confirmAndPunchOut(EmployeeDetailsData? details) async {
    // Check mandatory policies before allowing punch out
    final ok = await _ensurePoliciesRead();
    if (!ok) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool loading = false;
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Confirm Punch Out'),
            content: SizedBox(
              height: 48,
              child: loading
                  ? Row(children: const [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('Punching out...'))
                    ])
                  : const Text('Are you sure you want to Punch Out?'),
            ),
            actions: [
              if (!loading)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey), // gray border
                    foregroundColor: Colors.grey[800], // text color
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorRed, // solid red background
                  foregroundColor: Colors.white, // white text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // rounded corners
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: loading
                    ? null
                    : () async {
                        setDialogState(() => loading = true);
                        try {
                          await _handlePunchOutTap(details);
                        } catch (_) {
                          // handled by snackbar
                        } finally {
                          if (mounted) {
                            setDialogState(() => loading = false);
                            Navigator.of(context).pop(true);
                          } else {
                            Navigator.of(context).pop(true);
                          }
                        }
                      },
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Yes'),
              ),
            ],
          );
        });
      },
    );

    return confirmed == true;
  }

  Future<bool> _ensurePoliciesRead() async {
    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null ||
          secure == null ||
          user.employeeId.isEmpty ||
          secure.isEmpty) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return false;
      }

      // Fetch policy list and employee_info read flags
      final resp = await PolicyService.getPolicyList(
          employeeId: user.employeeId, secure: secure);
      if (!mounted) return false;
      if (resp['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(resp['message']?.toString() ??
                'Unable to verify policy status')));
        return false;
      }

      final info = Map<String, dynamic>.from(resp['employee_info'] ?? {});
      final List data = resp['data'] as List? ?? const [];

      bool privacyUnread =
          (info['privacy_policy_read']?.toString().toLowerCase() ?? 'unread') ==
              'unread';
      bool termsUnread =
          (info['terms_and_conditions']?.toString().toLowerCase() ??
                  'unread') ==
              'unread';

      if (!privacyUnread && !termsUnread) return true;

      // Helper to find policy map by type
      Map<String, dynamic>? _findByType(String type) {
        final subjMatch = type == 'privacy_policy' ? 'privacy' : 'terms';
        for (final e in data) {
          final m = Map<String, dynamic>.from(e as Map);
          final s = (m['subject'] ?? '').toString().toLowerCase();
          if (s.contains(subjMatch)) return m;
        }
        return null;
      }

      // If both unread, navigate to list so user can read both
      if (privacyUnread && termsUnread) {
        await _showPolicyDialog(
          title: 'Action Required',
          message:
              'Please read and accept Privacy Policy and Terms & Conditions before punching out.',
          primaryText: 'Read Now',
          onPrimary: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyPolicyListPage()),
            );
          },
        );
        return false;
      }

      // If a single policy is unread, direct user to that detail page
      final unreadType =
          privacyUnread ? 'privacy_policy' : 'terms_and_conditions';
      final label = privacyUnread ? 'Privacy Policy' : 'Terms & Conditions';
      final item = _findByType(unreadType);

      await _showPolicyDialog(
        title: 'Action Required',
        message: 'You have not read the $label.',
        primaryText: 'Read $label',
        onPrimary: () {
          if (item != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CompanyPolicyDetailsPage(policy: item)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyPolicyListPage()),
            );
          }
        },
      );

      return false;
    } catch (_) {
      return false;
    }
  }

  // Punch Out handler with loading state
  Future _handlePunchOutTap(EmployeeDetailsData? details) async {
    if (_isPunchingOut) return; // Prevent multiple taps

    try {
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee info not loaded')));
        }
        return;
      }

      // Set loading state
      setState(() {
        _isPunchingOut = true;
      });

      // Only when already punched in
      final todayWorkingStatus =
          (details.todayWorkingStatus ?? 'not_present').toLowerCase();
      final isPunchedIn = todayWorkingStatus != 'not_present';
      if (!isPunchedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not punched in yet')));
        }
        return;
      }

      // Geofence check for WFO
      final isWFO =
          details.todayWorkLocation.toLowerCase() == 'work_from_office';
      if (isWFO) {
        final office = details.officeLocation;
        if (office == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Office location not configured')));
          }
          return;
        }

        if (mounted) {
          setState(() {
            _isCheckingLocation = true;
            _geoError = null;
          });
        }

        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            if (mounted) {
              setState(() {
                _isCheckingLocation = false;
                _geoError = 'Location services are disabled';
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Location services are disabled')));
            }
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              if (mounted) {
                setState(() {
                  _isCheckingLocation = false;
                  _geoError = 'Location permission denied';
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Location permission denied')));
              }
              return;
            }
          }
          if (permission == LocationPermission.deniedForever) {
            if (mounted) {
              setState(() {
                _isCheckingLocation = false;
                _geoError = 'Location permission permanently denied';
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Location permission permanently denied')));
            }
            return;
          }

          final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.best);
          final inside = await isInsideOfficeArea(
            userLat: pos.latitude,
            userLng: pos.longitude,
            officeLat: double.tryParse(office.latitude) ?? 0,
            officeLng: double.tryParse(office.longitude) ?? 0,
            radius: office.radius,
            radiusUnit: office.radiusUnit,
          );

          if (mounted) {
            setState(() {
              _isInsideOffice = inside;
              _isCheckingLocation = false;
              _geoError = inside ? null : 'Outside office area';
            });
          }

          if (!inside) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('You are not in office location')));
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isCheckingLocation = false;
              _geoError = 'Unable to get location';
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to get location')));
          }
          return;
        }
      }

      // Build dynamic body
      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }

      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final punchOutTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final res = await AuthService.punchOut(
        todayDate: todayDate,
        punchOutTime: punchOutTime,
        empId: empId,
        secure: secure,
      );

      if (mounted) {
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Complete Today Work')));
          // Reload to get todayWorkingStatus
          await ref.read(dashboardEmployeeProvider.notifier).load();
          await _fetchTodayActivity();
          setState(() {}); // ensure rebuild
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  res.message.isNotEmpty ? res.message : 'Punch out failed')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Punch out failed')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunchingOut = false;
        });
      }
    }
  }

  // Lunch In/Out and Break handlers
  Future _handleLunchInTap(EmployeeDetailsData? details) async {
    if (_isLunchIn) return; // Prevent multiple taps

    try {
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee info not loaded')));
        }
        return;
      }

      setState(() {
        _isLunchIn = true;
      });

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }
      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lunchInTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final res = await AuthService.lunchIn(
        todayDate: todayDate,
        lunchInTime: lunchInTime,
        empId: empId,
        secure: secure,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
        await ref.read(dashboardEmployeeProvider.notifier).load();
        await _fetchTodayActivity();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lunch in failed')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLunchIn = false;
        });
      }
    }
  }

  Future _handleLunchOutTap(EmployeeDetailsData? details) async {
    if (_isLunchOut) return; // Prevent multiple taps

    try {
      if (details == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee info not loaded')));
        return;
      }

      setState(() {
        _isLunchOut = true;
      });

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }
      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final lunchOutTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final res = await AuthService.lunchOut(
        todayDate: todayDate,
        lunchOutTime: lunchOutTime,
        empId: empId,
        secure: secure,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
        await ref.read(dashboardEmployeeProvider.notifier).load();
        await _fetchTodayActivity();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lunch out failed')));
    } finally {
      if (mounted) {
        setState(() {
          _isLunchOut = false;
        });
      }
    }
  }

  Future _handleBreakInTap(EmployeeDetailsData? details) async {
    if (_isBreakIn) return; // Prevent multiple taps

    try {
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee info not loaded')));
        }
        return;
      }

      setState(() {
        _isBreakIn = true;
      });

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }
      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final breakInTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final res = await AuthService.breakIn(
        breakDate: todayDate,
        breakInTime: breakInTime,
        empId: empId,
        secure: secure,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
        await ref.read(dashboardEmployeeProvider.notifier).load();
        await _fetchTodayActivity();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Break in failed')));
    } finally {
      if (mounted) {
        setState(() {
          _isBreakIn = false;
        });
      }
    }
  }

  Future _handleBreakOutTap(EmployeeDetailsData? details) async {
    if (_isBreakOut) return; // Prevent multiple taps

    try {
      if (details == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Employee info not loaded')));
        return;
      }

      setState(() {
        _isBreakOut = true;
      });

      final user = await AuthService.getSavedUser();
      final empId = user?.employeeId ?? '';
      final secure = await AuthService.getSecure() ?? '';
      if (!mounted) return;
      if (empId.isEmpty || secure.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Missing employee credentials')));
        return;
      }
      final now = DateTime.now();
      final todayDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final breakOutTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final res = await AuthService.breakOut(
        breakDate: todayDate,
        breakOutTime: breakOutTime,
        empId: empId,
        secure: secure,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(res.message)));
        await ref.read(dashboardEmployeeProvider.notifier).load();
        await _fetchTodayActivity();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Break out failed')));
    } finally {
      if (mounted) {
        setState(() {
          _isBreakOut = false;
        });
      }
    }
  }

  String _formatApiTime(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == 'null') {
      return '0h 0m 0s';
    }

    // Handle different time formats from API
    if (timeString.contains(':')) {
      // Format like "02:30" or "02:30:00"
      final parts = timeString.split(':');
      print(parts);
      if (parts.length >= 2) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final second = 0;
        return '${hours}h ${minutes}m ${second}s';
      }
    }

    // If it's already in the right format or unknown format, return as is
    if (timeString.contains('h') && timeString.contains('m')) {
      return timeString;
    }

    // Default fallback
    return timeString.isNotEmpty ? timeString : '0h 0m';
  }

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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(enhancedDashboardProvider);
    final notifier = ref.read(enhancedDashboardProvider.notifier);
    final emp = ref.watch(dashboardEmployeeProvider);
    final details = emp.details;

    if (!_handledEmployeeError &&
        (emp.error != null && emp.error!.isNotEmpty)) {
      _handledEmployeeError = true;
      // Only force-logout on actual auth errors, not generic network/server errors
      if (_isAuthError(emp.error!)) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await LogoutHandler.handleUnauthorizedResponse(context, ref);
        });
      }
    }

    // Derive statuses
    final todayWorkingStatus =
        (details?.todayWorkingStatus ?? 'not_present').toLowerCase();
    final isPunchedIn = todayWorkingStatus != 'not_present' &&
        todayWorkingStatus != 'punch_out';
    final isLunch = details?.lunchStatus == 'ongoing';
    final isOnBreak = details?.breakStatus == 'ongoing';
    final isWorkComplete = todayWorkingStatus == 'punch_out';

    return Scaffold(
      backgroundColor: _surfaceColor,
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: _primaryPurple,
        child: SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Column(
            children: [
              // Simple greeting only
              _buildPrimaryHeader(details, emp.loading, emp.error),
              const SizedBox(height: 15),
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
                    : (details?.todayWorkingStatus ??
                            (isPunchedIn ? 'present' : 'not_present'))
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
                requiresOfficePresence:
                    (details?.todayWorkLocation.toLowerCase() ==
                        'work_from_office'),
                details: details,
                workCompleted: isWorkComplete,
              ),
              // const SizedBox(height: 15),
              // _buildOfficeAddressCard(details),
              // const SizedBox(height: 24),
              // _buildActionGrid(isPunchedIn: isPunchedIn, details: details),
              const SizedBox(height: 24),
              _buildTodayMetrics(
                  data.totalTiffinTime, data.totalBreakTime, data),
              const SizedBox(height: 24),
              _buildTodayTasks(),
              const SizedBox(height: 24),
              _buildRecentActivity(data.activities),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryHeader(
      EmployeeDetailsData? details, bool loading, String? error) {
    final status = details?.status ?? '—';
    final isActive = (status.toLowerCase() == 'active');
    final name = details?.name?.isNotEmpty == true ? details!.name : '—';
    final empId =
        details?.employeeId?.isNotEmpty == true ? details!.employeeId : '—';
    final designation = details?.designationName?.isNotEmpty == true
        ? details!.designationName
        : '';

    return Container(
      margin: const EdgeInsets.all(20).copyWith(top: 15, bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_primaryPurple, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _primaryPurple.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
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
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: loading
                      ? Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : details?.profileImg != null &&
                              details!.profileImg!.isNotEmpty
                          ? Image.network(
                              details.profileImg!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if network image fails
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 36),
                                );
                              },
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 36),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_getGreeting(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500)),
                          Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: (isActive ? _accentGreen : _errorRed)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: (isActive ? _accentGreen : _errorRed)
                                        .withValues(alpha: 0.3))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              // const SizedBox(width: 6),
                              const SizedBox(width: 4),
                              Text(
                                  isActive
                                      ? 'Active'
                                      : (status.isNotEmpty ? status : '—'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(loading ? 'Loading...' : name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text(
                          designation.isEmpty ? empId : '$designation • $empId',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ]),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(_getCurrentDate(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: _accentOrange.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(
                      details?.todayWorkLocation.replaceAll('_', ' ') ??
                          'Remote',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
            ]),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: _errorRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _errorRed.withValues(alpha: 0.3))),
                child: Text(error,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          ],
        ],
      ),
    );
  }

  Widget _buildOfficeAddressCard(EmployeeDetailsData? details) {
    final loc = details?.officeLocation;
    final locationText = loc == null
        ? 'No office location assigned'
        : '${loc.locationName} (${loc.locationType})';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20).copyWith(bottom: 0, right: 0),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _accentOrange.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: _accentOrange.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5))
          ]),
      child: Column(
        children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: _accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.location_on_rounded,
                    color: _accentOrange, size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Office Location',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textLight,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(locationText,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textDark))
                ])),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _accentGreen.withValues(alpha: 0.3),
                          width: 1)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: _accentGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('HQ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accentGreen,
                            letterSpacing: 0.5))
                  ])),
            ),
          ]),
          Row(
            children: [
              Spacer(),
              InkWell(
                onTap: () async {
                  if (!mounted) return; // Check if widget is still mounted
                  final details = ref.read(dashboardEmployeeProvider).details;
                  if (details != null) {
                    await _fetchAndEvaluateLocation(details.officeLocation);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(15),
                        topLeft: Radius.circular(7)),
                    color: _accentOrange.withValues(alpha: 0.3),
                    border: Border.all(
                        color: _accentOrange.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    "Refresh",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfileHeader(DashboardEmployeeState employeeState) {
    final details = employeeState.details;
    final loading = employeeState.loading;
    final error = employeeState.error;

    final status = details?.status ?? '—';
    final isActive = (status.toLowerCase() == 'active');
    final name =
        (details != null && details.name.isNotEmpty) ? details.name : '—';
    final empId = (details != null && details.employeeId.isNotEmpty)
        ? details.employeeId
        : '—';
    final designation = (details != null && details.designationName.isNotEmpty)
        ? details.designationName
        : '';

    return Container(
      // margin: const EdgeInsets.all(20).copyWith(top: 0, bottom: 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF422F90), Color(0xFF5A4FCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF422F90).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: loading
                      ? Container(
                          width: 60,
                          height: 60,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : details?.profileImg != null &&
                              details!.profileImg!.isNotEmpty
                          ? Image.network(
                              details.profileImg!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                );
                              },
                              errorBuilder: (context, e, st) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.white.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 36),
                                );
                              },
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 36),
                            ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: (isActive ? Colors.green : Colors.red)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive
                                    ? 'Active'
                                    : (status.isNotEmpty ? status : '—'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? 'Loading...' : name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      designation.isEmpty ? empId : '$designation • $empId',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  _getCurrentDate(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
              ],
            ),
          ),
          if (error != null && error.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Text(
                error,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: _cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 25,
                offset: const Offset(0, 8))
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () async {
                  if (!mounted) return;
                  final d = details;
                  if (d != null) {
                    await _fetchAndEvaluateLocation(d.officeLocation);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryPurple, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Refresh Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.schedule_rounded, color: _textLight, size: 18),
                    const SizedBox(width: 8),
                    Text(_getCurrentTime(),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                            letterSpacing: -0.5))
                  ]),
                  // Text(
                  //   _getGreeting(),
                  //   style: const TextStyle(
                  //     fontSize: 20,
                  //     fontWeight: FontWeight.w700,
                  //     color: _textDark,
                  //   ),
                  // ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // If day complete, show final text instead of a tappable button
          if (workCompleted)
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: _accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Today Work Complete',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _accentGreen)),
                ),
                const SizedBox(height: 16),
              ],
            )
          else
            Container(
              padding: EdgeInsets.all(35),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isPunchedIn
                      ? [_errorRed, const Color(0xFFFF6B6B)] // 🔴 Punch Out
                      : (canPunchIn
                          ? [_primaryPurple, _primaryDark] // 🟣 Punch In
                          : [Colors.amber, Colors.orange]), // 🟡 On the Way
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      (_isCheckingLocation || _isPunchingIn || _isPunchingOut)
                          ? null
                          : () async {
                              _punchController
                                  .forward()
                                  .then((_) => _punchController.reverse());
                              if (!isPunchedIn) {
                                if (canPunchIn) {
                                  await _handlePunchInTap(details);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Be inside office area to punch in')),
                                    );
                                  }
                                }
                              } else {
                                // show confirm dialog and proceed if confirmed
                                final didConfirm =
                                    await _confirmAndPunchOut(details);
                                // _confirmAndPunchOut will call _handlePunchOutTap itself if Yes pressed
                                if (!didConfirm) {
                                  // user cancelled, nothing to do
                                }
                              }
                            },
                  borderRadius: BorderRadius.circular(70),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show loading indicator when punching
                      if (_isPunchingIn || _isPunchingOut)
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      else
                        Icon(
                          isPunchedIn
                              ? Icons.logout_rounded
                              : (canPunchIn
                                  ? Icons.login_rounded
                                  : Icons.directions_run_rounded),
                          size: 36,
                          color: Colors.white,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _isPunchingIn
                            ? 'Punching In...'
                            : _isPunchingOut
                                ? 'Punching Out...'
                                : isPunchedIn
                                    ? 'Punch Out'
                                    : (canPunchIn ? 'Punch In' : 'On the Way'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isCheckingLocation
                              ? 'CHECKING...'
                              : _isPunchingIn
                                  ? 'PROCESSING...'
                                  : _isPunchingOut
                                      ? 'PROCESSING...'
                                      : isPunchedIn
                                          ? 'TAP TO END'
                                          : (canPunchIn
                                              ? 'Tap To Start'
                                              : 'Going To Office'),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(statusMessage,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ]),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isLunchOngoing = details?.lunchStatus == 'ongoing';
              final isLunchComplete = details?.lunchStatus == 'complete';
              final isBreakOngoing = details?.breakStatus == 'ongoing';
              final canStart =
                  isPunchedIn && !isLunchOngoing && !isBreakOngoing;

              // clamp split to a small adjustable range
              final split = _actionSplit.clamp(0.35, 0.65);
              final leftFlex = (split * 90).round();
              final rightFlex = 90 - leftFlex;

              Widget buildMiniCard({
                required String title,
                required String subtitle,
                required IconData icon,
                required Color color,
                required bool active,
                required bool enabled,
                required bool loading,
                required VoidCallback? onTap,
              }) {
                return SizedBox(
                  width: 140,
                  child: Material(
                    animateColor: true,
                    color: active
                        ? color
                        : enabled
                            ? _cardWhite
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: (enabled && !loading) ? onTap : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : enabled
                                        ? color.withValues(alpha: 0.12)
                                        : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: loading
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        color: active ? Colors.white : color,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      icon,
                                      color: active
                                          ? Colors.white
                                          : enabled
                                              ? color
                                              : Colors.grey,
                                      size: 20,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              loading ? 'Processing...' : title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : enabled
                                        ? _textDark
                                        : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: leftFlex,
                    child: buildMiniCard(
                      title: isBreakOngoing ? 'Break End' : 'Break Time',
                      subtitle: isBreakOngoing
                          ? 'ACTIVE'
                          : (canStart ? 'TAP TO START' : 'UNAVAILABLE'),
                      icon: Icons.coffee_rounded,
                      color: _accentBlue,
                      active: isBreakOngoing,
                      enabled: isPunchedIn,
                      loading: _isBreakIn || _isBreakOut,
                      onTap: () async {
                        if (isBreakOngoing) {
                          await _handleBreakOutTap(details);
                        } else if (canStart) {
                          await _handleBreakInTap(details);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) {
                      final w = constraints.maxWidth;
                      if (w > 0) {
                        setState(() {
                          _actionSplit =
                              (_actionSplit + d.delta.dx / w).clamp(0.35, 0.65);
                        });
                      }
                    },
                    child: Container(
                      width: 10,
                      height: 56,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 2, height: 16, color: _textLight),
                          const SizedBox(height: 4),
                          Container(width: 2, height: 16, color: _textLight),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: rightFlex,
                    child: buildMiniCard(
                      title: isLunchOngoing
                          ? 'Lunch End'
                          : isLunchComplete
                              ? "Today's Lunch Complete"
                              : 'Tiffin Time',
                      subtitle: isLunchOngoing
                          ? 'ACTIVE'
                          : (isLunchComplete
                              ? 'COMPLETED'
                              : (isPunchedIn ? 'TAP TO START' : 'UNAVAILABLE')),
                      icon: Icons.restaurant_rounded,
                      color: _accentOrange,
                      active: isLunchOngoing,
                      enabled: isPunchedIn && !isLunchComplete,
                      loading: _isLunchIn || _isLunchOut,
                      onTap: () async {
                        if (isLunchOngoing) {
                          await _handleLunchOutTap(details);
                        } else if (canStart) {
                          await _handleLunchInTap(details);
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(
      {required bool isPunchedIn, required EmployeeDetailsData? details}) {
    final isLunchOngoing = details?.lunchStatus == 'ongoing';
    final isLunchComplete = details?.lunchStatus == 'complete';
    final isBreakOngoing = details?.breakStatus == 'ongoing';
    final canStartBreakOrLunch =
        isPunchedIn && !isLunchOngoing && !isBreakOngoing;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _textDark)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _buildActionCard(
            isBreakOngoing ? 'Break End' : 'Break Time',
            Icons.coffee_rounded,
            _accentBlue,
            isBreakOngoing,
            isPunchedIn,
            () async {
              if (isBreakOngoing) {
                await _handleBreakOutTap(details);
              } else if (canStartBreakOrLunch) {
                await _handleBreakInTap(details);
              }
            },
            isLoading: _isBreakIn || _isBreakOut,
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _buildActionCard(
            isLunchOngoing
                ? 'Lunch End'
                : isLunchComplete
                    ? 'Today\'s Lunch Complete'
                    : 'Tiffin Time',
            Icons.restaurant_rounded,
            _accentOrange,
            isLunchOngoing,
            isPunchedIn && !isLunchComplete,
            () async {
              if (isLunchOngoing) {
                await _handleLunchOutTap(details);
              } else if (canStartBreakOrLunch) {
                await _handleLunchInTap(details);
              }
            },
            isLoading: _isLunchIn || _isLunchOut,
          )),
        ]),
        const SizedBox(height: 12),
        // Row(children: [
        //   Expanded(child: _buildActionCard('Apply Leave', Icons.event_busy_rounded, _errorRed, false, true, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ApplyLeavePage())))),
        //   const SizedBox(width: 12),
        //   Expanded(child: _buildActionCard('View Reports', Icons.analytics_rounded, _accentGreen, false, true, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePage())))),
        // ]),
        if (!isPunchedIn) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _accentOrange.withValues(alpha: 0.3))),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: _accentOrange, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Punch in first to take breaks or tiffin',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accentOrange)))
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color,
      bool isActive, bool isEnabled, VoidCallback onTap,
      {bool isLoading = false}) {
    return Container(
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5))
      ]),
      child: Material(
        color: isActive
            ? color
            : isEnabled
                ? _cardWhite
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: (isEnabled && !isLoading) ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.25)
                          : isEnabled
                              ? color.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: isLoading
                      ? SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: isActive ? Colors.white : color,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(icon,
                          color: isActive
                              ? Colors.white
                              : isEnabled
                                  ? color
                                  : Colors.grey,
                          size: 26)),
              const SizedBox(height: 16),
              Text(isLoading ? 'Processing...' : title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : isEnabled
                              ? _textDark
                              : Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(
                  isLoading
                      ? 'PLEASE WAIT'
                      : isActive
                          ? 'ACTIVE'
                          : isEnabled
                              ? 'TAP TO START'
                              : 'UNAVAILABLE',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : isEnabled
                              ? _textLight
                              : Colors.grey,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMetrics(Duration tiffin, Duration breaks, PunchData data) {
    // 🔹 Loading State
    if (_loadingTodayActivity) {
      return _buildMetricsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Today's Overview",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark)),
            SizedBox(height: 20),
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      );
    }

    // 🔹 No Data State
    if (_todayActivity == null) {
      return _buildMetricsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Today's Overview",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textDark)),
            SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(Icons.info_outline_rounded, size: 40, color: _textLight),
                  SizedBox(height: 12),
                  Text('No activity data available for today',
                      style: TextStyle(color: _textLight)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 🔹 Data Available
    final activity = _todayActivity!;

    return _buildMetricsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today's Overview",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textDark)),
                    Text(activity.date,
                        style:
                            const TextStyle(fontSize: 12, color: _textLight)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(activity.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  activity.status.toUpperCase(),
                  style: TextStyle(
                      color: _getStatusColor(activity.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 1, color: _borderColor),

          // Work Info
          const SizedBox(height: 16),
          _buildInfoRow("Check In", activity.inTime ?? "Not checked in",
              Icons.login_rounded, _accentGreen),
          const SizedBox(height: 10),
          _buildInfoRow("Check Out", activity.outTime ?? "Not checked out",
              Icons.logout_rounded, _errorRed),
          const SizedBox(height: 10),
          _buildInfoRow("Working Hours", _formatApiTime(activity.workingHours),
              Icons.timer_rounded, _primaryPurple),

          if (activity.isLate && activity.lateBy != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow(
                "Late By", activity.lateBy!, Icons.warning_rounded, _errorRed),
          ],

          const SizedBox(height: 18),
          const Divider(thickness: 1, color: _borderColor),
          const SizedBox(height: 10),

          // Breaks & Lunch
          Text("Breaks & Lunch",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark.withOpacity(0.9))),
          const SizedBox(height: 8),
          _buildInfoRow(
              "Break Duration",
              _formatApiTime(activity.breaks.totalBreakTime),
              Icons.coffee_rounded,
              _accentBlue),
          const SizedBox(height: 10),
          _buildInfoRow(
              "Lunch Duration",
              _formatApiTime(activity.totalLunchTime),
              Icons.restaurant_rounded,
              _accentOrange),

          if (activity.lunchStatus.isNotEmpty &&
              activity.lunchStatus != 'not_started') ...[
            const SizedBox(height: 10),
            _buildInfoRow("Lunch Status", activity.lunchStatus.toUpperCase(),
                Icons.info_rounded, _accentOrange),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 13, color: _textLight)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textDark)),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildTodayMetrics(Duration tiffin, Duration breaks, PunchData data) {
  //   if (_loadingTodayActivity) {
  //     return Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 20),
  //       padding: const EdgeInsets.all(24),
  //       decoration: BoxDecoration(
  //           color: _cardWhite,
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(color: _borderColor),
  //           boxShadow: [
  //             BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.05),
  //                 blurRadius: 15,
  //                 offset: const Offset(0, 5))
  //           ]),
  //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //         const Text('Today\'s Overview',
  //             style: TextStyle(
  //                 fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
  //         const SizedBox(height: 20),
  //         const Center(
  //           child: CircularProgressIndicator(
  //             valueColor: AlwaysStoppedAnimation<Color>(_primaryPurple),
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //       ]),
  //     );
  //   }

  //   if (_todayActivity == null) {
  //     return Container(
  //       margin: const EdgeInsets.symmetric(horizontal: 20),
  //       padding: const EdgeInsets.all(24),
  //       decoration: BoxDecoration(
  //           color: _cardWhite,
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(color: _borderColor),
  //           boxShadow: [
  //             BoxShadow(
  //                 color: Colors.black.withValues(alpha: 0.05),
  //                 blurRadius: 15,
  //                 offset: const Offset(0, 5))
  //           ]),
  //       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //         const Text('Today\'s Overview',
  //             style: TextStyle(
  //                 fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
  //         const SizedBox(height: 20),
  //         const Center(
  //           child: Column(
  //             children: [
  //               Icon(Icons.info_outline_rounded, size: 40, color: _textLight),
  //               SizedBox(height: 12),
  //               Text('No activity data available for today',
  //                   style: TextStyle(color: _textLight)),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //       ]),
  //     );
  //   }

  //   final activity = _todayActivity!;

  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     padding: const EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //         color: _cardWhite,
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(color: _borderColor),
  //         boxShadow: [
  //           BoxShadow(
  //               color: Colors.black.withValues(alpha: 0.05),
  //               blurRadius: 15,
  //               offset: const Offset(0, 5))
  //         ]),
  //     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //       // Header with date and status
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 const Text('Today\'s Overview',
  //                     style: TextStyle(
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.w700,
  //                         color: _textDark)),
  //                 Text(activity.date,
  //                     style: const TextStyle(fontSize: 12, color: _textLight)),
  //               ],
  //             ),
  //           ),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //             decoration: BoxDecoration(
  //               color: _getStatusColor(activity.status).withValues(alpha: 0.1),
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Container(
  //                   width: 8,
  //                   height: 8,
  //                   decoration: BoxDecoration(
  //                     color: _getStatusColor(activity.status),
  //                     shape: BoxShape.circle,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Text(
  //                   activity.status.toUpperCase(),
  //                   style: TextStyle(
  //                     fontSize: 11,
  //                     fontWeight: FontWeight.w600,
  //                     color: _getStatusColor(activity.status),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 20),

  //       // Timing Information
  //       _buildTodayInfoRow('Check In', activity.inTime ?? 'Not checked in',
  //           Icons.login_rounded, _accentGreen),
  //       const SizedBox(height: 12),
  //       _buildTodayInfoRow('Check Out', activity.outTime ?? 'Not checked out',
  //           Icons.logout_rounded, _errorRed),
  //       const SizedBox(height: 12),
  //       _buildTodayInfoRow(
  //           'Working Hours',
  //           _formatApiTime(activity.workingHours),
  //           Icons.timer_rounded,
  //           _primaryPurple),

  //       if (activity.isLate && activity.lateBy != null) ...[
  //         const SizedBox(height: 12),
  //         _buildTodayInfoRow(
  //             'Late By', activity.lateBy!, Icons.warning_rounded, _errorRed),
  //       ],

  //       const SizedBox(height: 16),
  //       const Divider(color: _borderColor),
  //       const SizedBox(height: 16),

  //       // Break and Lunch Information
  //       _buildTodayInfoRow(
  //           'Break Duration',
  //           _formatApiTime(activity.breaks.totalBreakTime),
  //           Icons.coffee_rounded,
  //           _accentBlue),
  //       const SizedBox(height: 12),
  //       _buildTodayInfoRow(
  //           'Lunch Duration',
  //           _formatApiTime(activity.totalLunchTime),
  //           Icons.restaurant_rounded,
  //           _accentOrange),

  //       if (activity.lunchStatus.isNotEmpty &&
  //           activity.lunchStatus != 'not_started') ...[
  //         const SizedBox(height: 12),
  //         _buildTodayInfoRow('Lunch Status', activity.lunchStatus.toUpperCase(),
  //             Icons.info_rounded, _accentOrange),
  //       ],

  //       const SizedBox(height: 16),
  //       // const Divider(color: _borderColor),
  //       // const SizedBox(height: 16),

  //       // Office Information
  //       // Row(
  //       //   children: [
  //       //     Expanded(
  //       //       child: _buildTodayInfoCard(
  //       //           'Office Hours',
  //       //           '${activity.openingTime} - ${activity.closingTime}',
  //       //           Icons.business_rounded,
  //       //           _textLight),
  //       //     ),
  //       //     const SizedBox(width: 12),
  //       //     Expanded(
  //       //       child: _buildTodayInfoCard(
  //       //           'Work Location',
  //       //           activity.workLocationStatus,
  //       //           Icons.location_on_rounded,
  //       //           _primaryPurple),
  //       //     ),
  //       //   ],
  //       // ),
  //     ]),
  //   );
  // }

  Widget _buildTodayInfoRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayInfoCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return _accentGreen;
      case 'absent':
        return _errorRed;
      case 'leave':
        return _accentOrange;
      case 'holiday':
        return _accentBlue;
      default:
        return _textLight;
    }
  }

  Widget _buildTodayTasks() => const SizedBox.shrink();
  Widget _buildRecentActivity(List activities) => const SizedBox.shrink();
}
