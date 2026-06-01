import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/supply_api_service.dart';
import 'supply_service.dart';

class ApplySupplyPage extends ConsumerStatefulWidget {
  const ApplySupplyPage({super.key});

  @override
  ConsumerState<ApplySupplyPage> createState() => _ApplySupplyPageState();
}

class _ApplySupplyPageState extends ConsumerState<ApplySupplyPage> {
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _errorRed = Color(0xFFEF4444);

  final _quantityCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _returnExchangeCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();

  String? _category;
  String? _priority;
  DateTime? _date;
  File? _attachmentFile;
  bool _submitting = false;

  final _categories = const [
    'office_supplies',
    'technology',
    'furniture',
    'stationery',
    'uniforms',
    'breakroom',
    'software',
    'ppe',
    'marketing',
    'decor',
    'travel',
    'gifts',
    'cleaning',
    'wellness',
    'miscellaneous',
  ];

  final _priorities = const [
    'Top Priority',
    'Normal Priority',
  ];

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _amountCtrl.dispose();
    _detailsCtrl.dispose();
    _returnExchangeCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Apply Supply Requisition',
      //       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      //   backgroundColor: _primary,
      //   foregroundColor: Colors.white,
      //   centerTitle: true,
      //   elevation: 0,
      // ),
      backgroundColor: _surface,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            _formCard(),
            _submitBtn(),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_primary, _primaryDark]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _primary.withAlpha(30),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: const Row(children: [
          Icon(Icons.inventory_2_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
              child: Text('Apply Supply Requisition',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)))
        ]),
      );

  Widget _formCard() => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Category',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          _dropdown(
              value: _category,
              items: _categories,
              hint: 'Choose Category',
              onChanged: (v) => setState(() => _category = v)),
          const SizedBox(height: 16),
          const Text('Date',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          _datePicker(
              label: 'Select date',
              selectedDate: _date,
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1));
                if (picked != null) setState(() => _date = picked);
              }),
          const SizedBox(height: 16),
          const Text('Quantity',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          TextFormField(
              controller: _quantityCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec('Enter quantity')),
          const SizedBox(height: 16),
          const Text('Amount (₹)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec('Enter amount')),
          const SizedBox(height: 16),
          const Text('Priority',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          _dropdown(
              value: _priority,
              items: _priorities,
              hint: 'Choose Priority',
              onChanged: (v) => setState(() => _priority = v)),
          const SizedBox(height: 16),
          const Text('Return/Exchange',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          TextField(
              controller: _returnExchangeCtrl,
              decoration: _dec('Enter return/exchange details')),
          const SizedBox(height: 16),
          const Text('Details',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          TextField(
              controller: _detailsCtrl,
              maxLines: 3,
              decoration: _dec('Enter details...')),
          const SizedBox(height: 16),
          const Text('Attachment (Image or PDF)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          _attachmentPicker(),
          const SizedBox(height: 16),
          const Text('Comments (optional)',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _textDark)),
          const SizedBox(height: 8),
          TextField(
              controller: _commentsCtrl,
              maxLines: 2,
              decoration: _dec('Add comments...')),
        ]),
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2)),
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.all(16),
      );

  Widget _dropdown(
          {required String? value,
          required List<String> items,
          required String hint,
          required ValueChanged<String?> onChanged}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            hint: Text(hint, style: const TextStyle(color: Colors.black54)),
            dropdownColor: Colors.white,
            items: items
                .map((e) => DropdownMenuItem(
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

  Widget _datePicker(
          {required String label,
          required DateTime? selectedDate,
          required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border)),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.calendar_today_rounded,
                    color: _primary, size: 20)),
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
                          color:
                              selectedDate == null ? _textLight : _textDark)),
                ])),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _textLight, size: 16),
          ]),
        ),
      );

  Widget _attachmentPicker() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
            onPressed: _pickAttachment,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Choose file')),
        const SizedBox(height: 8),
        Text(
            _attachmentFile == null
                ? 'No file selected'
                : _attachmentFile!.path.split('/').last,
            style: const TextStyle(color: _textLight, fontSize: 12)),
        const SizedBox(height: 4),
        const Text('Allowed: Images (jpg, jpeg, png) or PDF',
            style: TextStyle(color: _textLight, fontSize: 11)),
      ]);

  Future<void> _pickAttachment() async {
    // Suppress lock once when returning from trusted file picker
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('suppress_next_lock', true);
    } catch (_) {}

    final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;
    setState(() => _attachmentFile = File(path));
  }

  Widget _submitBtn() => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
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
                      Text('Submit Requisition',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700))
                    ]),
        ),
      );

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? _errorRed : _textDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  Future<void> _submit() async {
    if (_category == null || _category!.isEmpty)
      return _toast('Please choose a category', error: true);
    if (_date == null) return _toast('Please select date', error: true);
    if (_quantityCtrl.text.trim().isEmpty)
      return _toast('Please enter quantity', error: true);
    if (_amountCtrl.text.trim().isEmpty)
      return _toast('Please enter amount', error: true);
    if (_detailsCtrl.text.trim().isEmpty)
      return _toast('Please enter details', error: true);
    if (_priority == null || _priority!.isEmpty)
      return _toast('Please choose priority', error: true);

    setState(() => _submitting = true);
    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null || secure == null) {
        setState(() => _submitting = false);
        return _toast('Session expired. Please login again.', error: true);
      }

      final res = await SupplyApiService.submitSupply(
        employeeId: user.employeeId,
        date: DateFormat('yyyy-MM-dd').format(_date!),
        category: _category!,
        details: _detailsCtrl.text.trim(),
        quantity: _quantityCtrl.text.trim(),
        amount: _amountCtrl.text.trim(),
        priority: _priority!,
        returnExchange: _returnExchangeCtrl.text.trim(),
        secure: secure,
        attachment: _attachmentFile,
        comments: _commentsCtrl.text.trim().isEmpty
            ? null
            : _commentsCtrl.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        _toast(
            res['message']?.toString() ?? 'Requisition submitted successfully');
        ref.read(supplyServiceProvider.notifier).loadSupply();
        Navigator.pop(context);
      } else {
        _toast(res['message']?.toString() ?? 'Failed to submit requisition',
            error: true);
      }
    } catch (e) {
      if (mounted) _toast('Failed to submit requisition: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
