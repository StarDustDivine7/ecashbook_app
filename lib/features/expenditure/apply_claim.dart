import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/expenditure_api_service.dart';
import 'expenditure_service.dart';

class ApplyClaimPage extends ConsumerStatefulWidget {
  const ApplyClaimPage({super.key});

  @override
  ConsumerState<ApplyClaimPage> createState() => _ApplyClaimPageState();
}

class _ApplyClaimPageState extends ConsumerState<ApplyClaimPage> {
  static const Color _primary = Color(0xFF6366F1); // App primary purple
  static const Color _primaryDark = Color(0xFF4338CA); // App primary dark
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _errorRed = Color(0xFFEF4444);

  final _amountCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  final List<String> _categories = const [
    'travel',
    'accommodation',
    'meals',
    'office_supplies',
    'communication',
    'training',
    'equipment',
    'client_entertainment',
    'shipping',
    'marketing',
    'office_rent',
    'employee_welfare',
    'legal',
    'miscellaneous',
  ];

  final List<String> _paymentMethods = const [
    'cash',
    'upi',
    'card',
    'banking',
  ];

  String? _category;
  String? _paymentMethod;
  DateTime? _date;
  File? _receiptFile;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _detailsCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Apply Expenditure Claim',
      //       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      //   backgroundColor: _primary,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   centerTitle: true,
      // ),
      backgroundColor: _surface,
      resizeToAvoidBottomInset: false,
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              _buildFormCard(),
              _buildSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryDark.withAlpha(30),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.request_quote_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apply Expenditure Claim',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Fill in the details below',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
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
          const Text('Category',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _category,
            items: _categories,
            hint: 'Choose Category',
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 24),
          const Text('Payment Method',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          _buildDropdown(
            value: _paymentMethod,
            items: _paymentMethods,
            hint: 'Choose Payment Method',
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: 24),
          const Text('Claim Date',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          _buildDatePicker(
            label: 'Select date',
            selectedDate: _date,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 24),
          const Text('Amount (₹)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Enter amount'),
          ),
          const SizedBox(height: 24),
          const Text('Details',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsCtrl,
            maxLines: 3,
            decoration: _inputDecoration('Enter details...'),
          ),
          const SizedBox(height: 24),
          const Text('Receipt (Image or PDF)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          _buildReceiptPicker(),
          const SizedBox(height: 24),
          const Text('Comments (optional)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _commentsCtrl,
            maxLines: 2,
            decoration: _inputDecoration('Add comments...'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(color: Colors.black54)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          dropdownColor: Colors.white,
          items: items
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(_toTitleCase(e),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _toTitleCase(String input) {
    final cleaned = input.replaceAll('_', ' ');
    final parts = cleaned.split(' ');
    return parts
        .map((p) {
          if (p.isEmpty) return p;
          final lower = p.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ')
        .trim();
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
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _textLight)),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate == null
                        ? 'Select date'
                        : DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedDate == null ? _textLight : _textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _textLight, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickReceipt,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Choose file'),
        ),
        const SizedBox(height: 8),
        Text(
          _receiptFile == null
              ? 'No file selected'
              : _receiptFile!.path.split('/').last,
          style: const TextStyle(color: _textLight, fontSize: 12),
        ),
        const SizedBox(height: 4),
        const Text('Allowed: Images (jpg, jpeg, png) or PDF',
            style: TextStyle(color: _textLight, fontSize: 11)),
      ],
    );
  }

  Future<void> _pickReceipt() async {
    // Suppress lock once when returning from trusted file picker
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('suppress_next_lock', true);
    } catch (_) {}

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withReadStream: false,
      allowMultiple: false,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.single;
    final path = f.path;
    if (path == null) return;
    setState(() => _receiptFile = File(path));
  }

  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Submit Claim',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _errorRed : _textDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    if (_category == null || _category!.isEmpty) {
      _showSnack('Please choose a category', error: true);
      return;
    }
    if (_paymentMethod == null || _paymentMethod!.isEmpty) {
      _showSnack('Please choose payment method', error: true);
      return;
    }
    if (_date == null) {
      _showSnack('Please select date', error: true);
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      _showSnack('Please enter amount', error: true);
      return;
    }
    if (_detailsCtrl.text.trim().isEmpty) {
      _showSnack('Please enter details', error: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null || secure == null) {
        _showSnack('Session expired. Please login again.', error: true);
        setState(() => _submitting = false);
        return;
      }

      final res = await ExpenditureApiService.submitClaim(
        employeeId: user.employeeId,
        date: DateFormat('yyyy-MM-dd').format(_date!),
        secure: secure,
        category: _category!,
        claimAmount: _amountCtrl.text.trim(),
        details: _detailsCtrl.text.trim(),
        paymentMethod: _paymentMethod!,
        receipt: _receiptFile,
        comments: _commentsCtrl.text.trim().isEmpty
            ? null
            : _commentsCtrl.text.trim(),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        _showSnack(
            res['message']?.toString() ?? 'Claim submitted successfully');
        // Refresh list
        ref.read(expenditureServiceProvider.notifier).loadClaims();
        // Reset
        setState(() {
          _category = null;
          _paymentMethod = null;
          _date = null;
          _amountCtrl.clear();
          _detailsCtrl.clear();
          _commentsCtrl.clear();
          _receiptFile = null;
        });
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(res['message']?.toString() ?? 'Failed to submit claim',
            error: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to submit claim: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
