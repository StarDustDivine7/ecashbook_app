import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/leave_api_service.dart';
import 'leave_service.dart';

class ApplyLeavePage extends ConsumerStatefulWidget {
  const ApplyLeavePage({super.key});

  @override
  ConsumerState<ApplyLeavePage> createState() => _ApplyLeavePageState();
}

class _ApplyLeavePageState extends ConsumerState<ApplyLeavePage> {
  // Premium Design Colors
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  bool _isMultipleDays = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedLeaveType = 'Casual';
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  final List<String> _leaveTypes = [
    'Sick',
    'Casual',
    'Annual',
    'Maternity',
    'Paternity',
    'Emergency',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     'Apply for Leave',
      //     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      //   ),
      //   backgroundColor: _primaryPurple,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      backgroundColor: _surfaceColor,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 24,
        ),
        child: Column(
          children: [
            // Header Card
            _buildHeaderCard(),

            // Form Card
            _buildFormCard(),

            // Submit Button
            _buildSubmitButton(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPurple, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply for Leave',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Fill in the details below',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave Type Dropdown
          const Text(
            'Leave Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLeaveType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                dropdownColor: Colors.white,
                items: _leaveTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLeaveType = newValue;
                      print(_selectedLeaveType.toString());
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Duration Type Section
          const Text(
            'Duration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),

          // MODERN RADIO BUTTONS - FIXED DEPRECATED WARNINGS
          Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                // Single Day Leave Option
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMultipleDays = false;
                      _toDate = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: !_isMultipleDays
                                  ? _primaryPurple
                                  : _borderColor,
                              width: 2,
                            ),
                          ),
                          child: !_isMultipleDays
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _primaryPurple,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Single Day Leave',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: _borderColor),

                // Multiple Days Leave Option
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMultipleDays = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isMultipleDays
                                  ? _primaryPurple
                                  : _borderColor,
                              width: 2,
                            ),
                          ),
                          child: _isMultipleDays
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _primaryPurple,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Multiple Days Leave',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Date Selection
          const Text(
            'Select Dates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),

          // From Date
          _buildDatePicker(
            label: _isMultipleDays ? 'From Date' : 'Leave Date',
            selectedDate: _fromDate,
            onTap: () => _selectDate(context, true),
          ),

          if (_isMultipleDays) ...[
            const SizedBox(height: 16),
            // To Date
            _buildDatePicker(
              label: 'To Date',
              selectedDate: _toDate,
              onTap: () => _selectDate(context, false),
            ),
          ],

          const SizedBox(height: 24),

          // Reason Section
          const Text(
            'Reason for Leave',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason for leave...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryPurple, width: 2),
              ),
              filled: true,
              fillColor: _surfaceColor,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: _primaryPurple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate == null
                        ? 'Select date'
                        : _formatDate(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedDate == null ? _textLight : _textDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitLeaveRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Submit Leave Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          isFromDate ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _primaryPurple,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = pickedDate;
          if (_isMultipleDays &&
              (_toDate == null || _toDate!.isBefore(_fromDate!))) {
            _toDate = null;
          }
        } else {
          if (pickedDate.isBefore(_fromDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('To date cannot be before from date'),
                backgroundColor: _errorRed,
              ),
            );
            return;
          }
          _toDate = pickedDate;
        }
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    print('🔵 ========== SUBMIT BUTTON CLICKED ==========');

    // Validation
    if (_fromDate == null) {
      print('❌ Validation Failed: Date not selected');
      _showErrorMessage('Please select a date');
      return;
    }

    if (_isMultipleDays && _toDate == null) {
      print('❌ Validation Failed: To date not selected for multiple days');
      _showErrorMessage('Please select to date');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      print('❌ Validation Failed: Reason is empty');
      _showErrorMessage('Please enter reason for leave');
      return;
    }

    if (_selectedLeaveType.isEmpty) {
      print('❌ Validation Failed: Leave type not selected');
      _showErrorMessage('Please select leave type');
      return;
    }

    print('✅ All validations passed');

    setState(() {
      _isLoading = true;
    });

    try {
      // Get empId and secure from AuthService
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();

      print('📦 Retrieved from AuthService:');
      print('   user: ${user?.employeeId}');
      print('   secure: ${secure?.substring(0, 20)}...');

      if (user == null || secure == null) {
        print('❌ Session data missing');
        _showErrorMessage('Session expired. Please login again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final empId = user.employeeId;

      // Determine toDate (same as fromDate for single day leave)
      final toDate = _isMultipleDays ? _toDate! : _fromDate!;

      // Call API (send leaveType in lowercase)
      final result = await LeaveApiService.applyLeave(
        empId: empId,
        fromDate: _fromDate!,
        toDate: toDate,
        reason: _reasonController.text.trim(),
        leaveType: _selectedLeaveType.toLowerCase(),
        secure: secure,
      );

      print('📨 API Response:');
      print('   Success: ${result['success']}');
      print('   Message: ${result['message']}');
      print('   Data: ${result['data']}');

      if (!mounted) return;

      if (result['success'] == true) {
        // Add to local state for UI update
        final newRequest = LeaveRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          employeeId: empId,
          employeeName: user.name,
          isMultipleDays: _isMultipleDays,
          fromDate: _fromDate!,
          toDate: _isMultipleDays ? _toDate : null,
          reason: _reasonController.text.trim(),
          appliedDate: DateTime.now(),
        );

        ref.read(leaveServiceProvider.notifier).applyLeave(newRequest);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ??
                        'Leave request submitted successfully!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _textDark,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Reset form
        setState(() {
          _isMultipleDays = false;
          _fromDate = null;
          _toDate = null;
          _selectedLeaveType = 'Casual';
          _reasonController.clear();
        });

        // Navigate back after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        _showErrorMessage(
            result['message'] ?? 'Failed to submit leave request');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to submit leave request: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _errorRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
