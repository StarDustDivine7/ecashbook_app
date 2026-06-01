import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/policy_service.dart';
import '../../shared/header.dart';
import '../../shared/side_menu.dart';
import '../../shared/bottom_menu.dart';
import '../../shared/main_layout.dart';
import '../../features/dashboard/dashboard_employee_provider.dart';
import '../../core/services/auth_service.dart';

class CompanyPolicyListPage extends ConsumerStatefulWidget {
  const CompanyPolicyListPage({super.key});

  @override
  ConsumerState<CompanyPolicyListPage> createState() => _CompanyPolicyListPageState();
}

class _CompanyPolicyListPageState extends ConsumerState<CompanyPolicyListPage> {
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _policies = [];
  Map<String, dynamic> _employeeInfo = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    // Prefer employeeId from dashboard provider for reliability
    var employeeState = ref.read(dashboardEmployeeProvider);
    var empId = employeeState.details?.employeeId;
    var secure = await AuthService.getSecure();
    
    // Debug: print initial auth state
    // ignore: avoid_print
    print('Policy fetch auth check -> empId: ${empId ?? "null"}, secure: ${secure != null ? "present" : "null"}');

    // If missing, try loading employee details and re-check
    if ((empId == null || empId.isEmpty) || (secure == null || secure.isEmpty)) {
      // ignore: avoid_print
      print('Auth missing, attempting to load from dashboard provider...');
      
      await ref.read(dashboardEmployeeProvider.notifier).load();
      employeeState = ref.read(dashboardEmployeeProvider);
      empId = employeeState.details?.employeeId;
      secure = await AuthService.getSecure();
      
      // ignore: avoid_print
      print('After reload -> empId: ${empId ?? "null"}, secure: ${secure != null ? "present" : "null"}');
    }

    Map<String, dynamic> resp;
    if (empId != null && empId.isNotEmpty && secure != null && secure.isNotEmpty) {
      resp = await PolicyService.getPolicyList(employeeId: empId, secure: secure);
    } else {
      // Still missing -> return not authenticated error
      // ignore: avoid_print
      print('ERROR: Authentication failed - empId or secure token is missing');
      
      resp = {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    if (!mounted) return;
    
    // Debug: print full response
    // ignore: avoid_print
    print('Policy API Response -> success: ${resp['success']}, message: ${resp['message']}, data length: ${(resp['data'] as List?)?.length ?? 0}');
    
    if (resp['success'] == true) {
      final List data = resp['data'] as List;
      final list = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
      
      // ignore: avoid_print
      print('Policy list loaded successfully. Count: ${list.length}');
      
      setState(() {
        _policies = list;
        _employeeInfo = Map<String, dynamic>.from(resp['employee_info'] ?? {});
        _loading = false;
        _error = null; // Clear any previous errors
      });
    } else {
      // Check if this is an "empty data" scenario vs actual error
      final message = (resp['message'] ?? '').toString().toLowerCase();
      final isEmptyDataCase = message.contains('no data') || 
                               message.contains('no policies') || 
                               message.contains('not found') ||
                               message.isEmpty;
      
      final isAuthError = message.contains('not authenticated') || 
                         message.contains('unauthorized') ||
                         message.contains('unauthenticated');
      
      // ignore: avoid_print
      print('Policy list fetch failed: ${resp['message']}, empty case: $isEmptyDataCase, auth error: $isAuthError');
      
      if (isEmptyDataCase) {
        // Treat as empty data, not an error
        setState(() {
          _policies = [];
          _employeeInfo = {};
          _loading = false;
          _error = null;
        });
      } else if (isAuthError) {
        // Authentication error - show specific message
        setState(() {
          _error = 'Authentication failed. Please log in again.';
          _loading = false;
        });
      } else {
        // Actual error
        setState(() {
          _error = (resp['message'] ?? 'Failed to load policies').toString();
          _loading = false;
        });
      }
    }
  }

  bool _isUnread(Map<String, dynamic> p) {
    final subject = (p['subject'] ?? '').toString().toLowerCase();
    if (subject.contains('privacy')) {
      return (_employeeInfo['privacy_policy_read']?.toString().toLowerCase() ?? 'unread') == 'unread';
    }
    if (subject.contains('terms')) {
      return (_employeeInfo['terms_and_conditions']?.toString().toLowerCase() ?? 'unread') == 'unread';
    }
    return false;
  }

  Color _priorityColor(Map<String, dynamic> p) {
    return _isUnread(p) ? _accentBlue : _accentGreen;
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_primaryPurple, _primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _primaryPurple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.policy_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Company Policies', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Text('${_policies.length} policies', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
          if (_policies.any(_isUnread))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _accentOrange, borderRadius: BorderRadius.circular(20)),
              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final isUnread = _isUnread(p);
    final subject = (p['subject'] ?? '').toString();
    final content = (p['content'] ?? '').toString().replaceAll('\n', ' ');
    final date = (p['created_at'] ?? '').toString().split(' ').first;
    final color = _priorityColor(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread ? _primaryPurple.withValues(alpha: 0.02) : _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUnread ? _primaryPurple.withValues(alpha: 0.3) : _borderColor, width: isUnread ? 1.5 : 1),
        boxShadow: [
          BoxShadow(color: isUnread ? _primaryPurple.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyPolicyDetailsPage(policy: p),
              ),
            );
            if (changed == true) {
              if (!mounted) return;
              await _fetch();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 5, height: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 16),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: isUnread ? [_primaryPurple, _primaryDark] : [_textLight, _textLight.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                  border: isUnread ? Border.all(color: _primaryPurple.withValues(alpha: 0.3), width: 2) : null,
                ),
                child: Center(
                  child: Text(subject.isNotEmpty ? subject.substring(0, 2).toUpperCase() : 'CP', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600, color: isUnread ? _primaryPurple : _textDark)),
                    ),
                    if (isUnread)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _accentOrange, borderRadius: BorderRadius.circular(8)),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      )
                    else
                      Icon(Icons.check_circle_rounded, color: _accentGreen, size: 16),
                    Text(date, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isUnread ? _primaryPurple : _textLight)),
                  ]),
                  const SizedBox(height: 6),
                  Text(content, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _textLight, height: 1.3)),
                ]),
              ),
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(width: 10, height: 10, decoration: BoxDecoration(gradient: LinearGradient(colors: [_accentBlue, _primaryPurple], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(5))),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
    //  appBar: const Header(pageTitle: 'Company Policies', showBackButton: false),
     // drawer: const SideMenu(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _policies.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.policy_outlined,
                                      size: 80,
                                      color: _textLight.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'No Policies Found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'There are currently no company policies available.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetch,
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _policies.length,
                                  itemBuilder: (context, index) => _buildCard(_policies[index]),
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
      // bottomNavigationBar: BottomMenuBar(
      //   currentIndex: 4,
      //   onTap: (index) {
      //     Navigator.pushReplacement(
      //       context,
      //       MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
      //     );
      //   },
      // ),
    );
  }
}

class CompanyPolicyDetailsPage extends StatefulWidget {
  final Map<String, dynamic> policy;
  const CompanyPolicyDetailsPage({super.key, required this.policy});

  @override
  State<CompanyPolicyDetailsPage> createState() => _CompanyPolicyDetailsPageState();
}

class _CompanyPolicyDetailsPageState extends State<CompanyPolicyDetailsPage> {
  bool accepted = false;

  String _determineType(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('terms')) return 'terms_and_conditions';
    if (s.contains('privacy')) return 'privacy_policy';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final subject = (widget.policy['subject'] ?? '').toString();
    final content = (widget.policy['content'] ?? '').toString();
    final date = (widget.policy['created_at'] ?? '').toString();
    final type = _determineType(subject);
    final typeLabel = type == 'terms_and_conditions'
        ? 'Terms and Conditions'
        : (type == 'privacy_policy' ? 'Privacy Policy' : 'Policy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.policy_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text(date.split(' ').first),
              ]),
              const SizedBox(height: 12),
              Text(
                content,
                style: const TextStyle(fontSize: 14, height: 1.4),
                softWrap: true,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: accepted,
                onChanged: (v) => setState(() => accepted = v ?? false),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'I have read and accept the ' + typeLabel,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 6),
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Colors.blueGrey.withValues(alpha: 0.1),
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
              //     ),
              //     child: Text('You are accepting: ' + typeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              //   ),
              // ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: accepted
                      ? () async {
                          // type already determined above
                          if (type.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Unknown policy type')),
                            );
                            return;
                          }
                          final user = await AuthService.getSavedUser();
                          final secure = await AuthService.getSecure();
                          if (user == null || secure == null || user.employeeId.isEmpty || secure.isEmpty) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Not authenticated')),
                            );
                            return;
                          }
                          // Debug: print request payload
                          // ignore: avoid_print
                          print('Updating policy read status -> empId: ' + user.employeeId + ', type: ' + type + ' (' + typeLabel + '), status: true');
                          final resp = await PolicyService.updatePolicyReadStatus(
                            employeeId: user.employeeId,
                            secure: secure,
                            type: type,
                            status: true,
                          );
                          // Debug: print response status
                          // ignore: avoid_print
                          print('Update response -> success: ' + (resp['success'] == true).toString() + ', message: ' + (resp['message']?.toString() ?? '') + ', type: ' + type + ' (' + typeLabel + ')');
                          if (!mounted) return;
                          if (resp['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(typeLabel + ' accepted')),
                            );
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(resp['message']?.toString() ?? 'Update failed')),
                            );
                          }
                        }
                      : null,
                  child: Text('Confirm ' + typeLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
          ),
        ],
      ),
      ),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: 4,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
          );
        },
      ),
    );
  }
}
