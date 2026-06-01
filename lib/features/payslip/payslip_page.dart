import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ecashbook_app/core/services/auth_service.dart';
import 'package:ecashbook_app/core/services/payslip_api_service.dart';
import 'package:ecashbook_app/features/payslip/payslip_pdf.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart'
    show SaveFileDialogParams, FlutterFileDialog;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  // ✅ Colors
  final Color _primaryColor = const Color(0xFF6366F1);
  final Color _textDark = const Color(0xFF1F2937);
  final Color _textGray = const Color(0xFF6B7280);
  final Color _backgroundGray = const Color(0xFFF9FAFB);

  String selectedMonth = '';
  String selectedYear = '';

  bool isGenerating = false;
  bool isDownloading = false;
  bool hasPayslipData = false;

  bool _apiLoading = false;
  Map<String, dynamic>? _payslipVisible; // parsed visible_data for summary UI
  Map<String, dynamic>? _companyInfo;
  String? _errorMessage;
  int? _errorStatus;
  bool _canDownload = false;

  // Showing raw response for now

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  List<String> get years {
    final currentYear = DateTime.now().year;
    return List.generate(10, (index) {
      final startYear = currentYear - index;
      if (startYear < 2020) return null;
      return '$startYear-${startYear + 1}';
    }).whereType<String>().toList();
  }

  String _extractStartingYear(String financialYear) {
    if (financialYear.isEmpty) return '';
    final parts = financialYear.split('-');
    if (parts.isEmpty) return '';
    final startYear = int.tryParse(parts[0]);
    return startYear != null ? startYear.toString() : '';
  }

  @override
  void initState() {
    super.initState();
  }

  Widget _kv2Row(String t1, String v1, String t2, String v2) {
    return Row(
      children: [
        Expanded(child: _kv(t1, v1)),
        const SizedBox(width: 16),
        Expanded(child: _kv(t2, v2)),
      ],
    );
  }

// Future<void> _downloadPayslipPdf(
//     BuildContext context, Uint8List bytes, String fileName) async {
//   // Show option popup
//   final choice = await showDialog<String>(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: const Text('Download Payslip'),
//       content: const Text('Choose how to get your payslip:'),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, 'local'),
//           child: const Text('Download Locally'),
//         ),
//         TextButton(
//           onPressed: () => Navigator.pop(context, 'share'),
//           child: const Text('Share'),
//         ),
//       ],
//     ),
//   );

//   if (choice == null) return;

//   try {
//     if (choice == 'share') {
//       await Printing.sharePdf(bytes: bytes, filename: fileName);
//       print('Payslip shared successfully.');
//       return;
//     }

//     // If Download Locally
//     if (Platform.isAndroid) {
//       // Request permission for storage
//       var status = await Permission.storage.status;
//       if (!status.isGranted) {
//         status = await Permission.storage.request();
//         if (!status.isGranted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                   'Storage permission denied. Cannot save payslip locally.'),
//             ),
//           );
//           print('Storage permission denied by user.');
//           return;
//         }
//       }
//     }

//     // Get proper directory
//     Directory? dir;
//     if (Platform.isAndroid) {
//       dir = await getExternalStorageDirectory();
//       // Move to Downloads folder
//       String newPath = "";
//       List<String> paths = dir!.path.split("/");
//       for (int i = 1; i < paths.length; i++) {
//         String folder = paths[i];
//         if (folder == "Android") break;
//         newPath += "/" + folder;
//       }
//       newPath += "/Download";
//       dir = Directory(newPath);
//     } else if (Platform.isIOS) {
//       dir = await getApplicationDocumentsDirectory();
//     }

//     if (dir == null) {
//       // Fallback: save to temporary directory if we couldn't resolve target dir
//       final tmpDir = await getTemporaryDirectory();
//       if (!tmpDir.existsSync()) tmpDir.createSync(recursive: true);
//       final file = File('${tmpDir.path}/$fileName');
//       await file.writeAsBytes(bytes, flush: true);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Payslip saved to temporary location: ${file.path}')),
//       );
//       print('Payslip saved temporarily at ${file.path}');

//       final result = await OpenFilex.open(file.path);
//       if (result.type != ResultType.done) {
//         print('Failed to open file automatically, consider sharing.');
//       } else {
//         print('File opened successfully.');
//       }
//     } else {
//       if (!dir.existsSync()) dir.createSync(recursive: true);

//       final file = File('${dir.path}/$fileName');
//       await file.writeAsBytes(bytes, flush: true);

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Payslip saved to: ${file.path}')),
//       );
//       print('Payslip saved locally at ${file.path}');

//       // Open the saved file
//       final result = await OpenFilex.open(file.path);
//       if (result.type != ResultType.done) {
//         print('Failed to open file automatically, consider sharing.');
//       } else {
//         print('File opened successfully.');
//       }
//     }
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Failed to save/share payslip: $e')),
//     );
//     print('Error saving/sharing payslip: $e');
//   }
// }

  Future<void> _downloadPayslipPdf(
      Map<String, dynamic> visible, Map<String, dynamic>? companyInfo) async {
    try {
      setState(() => isDownloading = true);
      final bytes =
          await PayslipPdf.generate(visible: visible, companyInfo: companyInfo);
      String _safe(String input) => input
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      final rawName =
          'Payslip-${visible['payslip_no'] ?? visible['month'] ?? 'payslip'}';
      final safeName = _safe(rawName);
      final fileName = '$safeName.pdf';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading…')),
      );

      Directory? targetDir;
      if (Platform.isAndroid) {
        // Use SAF to save to Downloads; no legacy WRITE perms needed on Android 10+
        await FileSaver.instance
            .saveFile(name: fileName, bytes: bytes, mimeType: MimeType.pdf);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to Downloads')),
        );
        // Try to open via share sheet since path is managed by SAF
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return;
      } else if (Platform.isIOS) {
        targetDir = await getApplicationDocumentsDirectory();
      } else {
        targetDir =
            await getDownloadsDirectory() ?? await getTemporaryDirectory();
      }

      if (targetDir == null) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
        return;
      }

      final file = File('${targetDir.path}/$fileName'.replaceAll(' ', '_'));
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to: ${file.path}')),
      );

      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open/share payslip: $e')),
      );
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  bool get canGeneratePayslip =>
      selectedMonth.isNotEmpty && selectedYear.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundGray,
      // ✅ REMOVED: AppBar header completely
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month/Year Selection
              _buildPeriodSelector(),

              const SizedBox(height: 20),

              // Generate Payslip Button (triggers API)
              _buildGenerateButton(),
              const SizedBox(height: 12),
              if (_apiLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.blueGrey.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: const [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Loading payslip...'),
                  ]),
                )
              else if (_errorMessage != null)
                _buildErrorBox(_errorMessage!, _errorStatus)
              else if (_payslipVisible != null)
                _buildPayslipSummaryCard(_payslipVisible!, _companyInfo),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _canDownload &&
              _payslipVisible != null &&
              _errorMessage == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: isDownloading || _payslipVisible == null
                        ? null
                        : () async {
                            try {
                              setState(() => isDownloading = true);

                              // 🔹 Generate PDF
                              final Uint8List bytes = await PayslipPdf.generate(
                                visible: _payslipVisible!,
                                companyInfo: _companyInfo,
                              );

                              // 🔹 Safe filename
                              String _safe(String input) => input
                                  .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
                                  .replaceAll(RegExp(r'\s+'), '_');

                              final rawName =
                                  'Payslip-${_payslipVisible!['payslip_no'] ?? _payslipVisible!['month'] ?? 'payslip'}';

                              final fileName = '${_safe(rawName)}.pdf';

                              // 🔥 Save directly to Downloads
                              final params = SaveFileDialogParams(
                                data: bytes,
                                fileName: fileName,
                              );

                              final filePath = await FlutterFileDialog.saveFile(
                                  params: params);

                              // ✅ Success message
                              if (mounted && filePath != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Downloaded to: $filePath'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to download PDF: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => isDownloading = false);
                              }
                            }
                          },
                    icon: isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      isDownloading ? 'Preparing PDF...' : 'Download Payslip',
                    ),
                  ),
                ),
              ),
            )
          // ? SafeArea(
          //     child: Padding(
          //       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          //       child: SizedBox(
          //         width: double.infinity,
          //         height: 56,
          //         child: ElevatedButton.icon(
          //           style: ElevatedButton.styleFrom(
          //             backgroundColor: _primaryColor,
          //             foregroundColor: Colors.white,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(16),
          //             ),
          //             elevation: 0,
          //           ),
          //           onPressed: isDownloading || _payslipVisible == null
          //               ? null
          //               : () async {
          //                   try {
          //                     setState(() => isDownloading = true);
          //                     // Generate PDF bytes from the visible payslip data
          //                     final Uint8List bytes = await PayslipPdf.generate(
          //                         visible: _payslipVisible!,
          //                         companyInfo: _companyInfo);
          //                     // Build a safe filename
          //                     String _safe(String input) => input
          //                         .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          //                         .replaceAll(RegExp(r'\s+'), '_');
          //                     final rawName =
          //                         'Payslip-${_payslipVisible!['payslip_no'] ?? _payslipVisible!['month'] ?? 'payslip'}';
          //                     final fileName = '${_safe(rawName)}.pdf';
          //                     await _downloadPayslipPdf(
          //                         _payslipVisible!, _companyInfo);
          //                   } catch (e) {
          //                     if (mounted) {
          //                       ScaffoldMessenger.of(context).showSnackBar(
          //                         SnackBar(
          //                             content:
          //                                 Text('Failed to prepare PDF: $e')),
          //                       );
          //                     }
          //                   } finally {
          //                     if (mounted) {
          //                       setState(() => isDownloading = false);
          //                     }
          //                   }
          //                 },
          //           icon: isDownloading
          //               ? const SizedBox(
          //                   width: 20,
          //                   height: 20,
          //                   child: CircularProgressIndicator(
          //                       strokeWidth: 2, color: Colors.white),
          //                 )
          //               : const Icon(Icons.download_rounded),
          //           label: Text(isDownloading
          //               ? 'Preparing PDF...'
          //               : 'Download Payslip'),
          //         ),
          //       ),
          //     ),
          //   )
          : null,
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text('Select Pay Period',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _buildDropdown(
                label: 'Month',
                value: selectedMonth.isEmpty ? null : selectedMonth,
                hint: 'Select Month',
                items: months,
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value ?? '';
                    _payslipVisible = null;
                    _companyInfo = null;
                    _errorMessage = null;
                    _errorStatus = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                label: 'Financial Year',
                value: selectedYear.isEmpty
                    ? null
                    : (int.tryParse(selectedYear) != null
                        ? '$selectedYear-${int.parse(selectedYear) + 1}'
                        : null),
                hint: 'Select Year',
                items: years,
                onChanged: (value) {
                  setState(() {
                    selectedYear = _extractStartingYear(value ?? '');
                    _payslipVisible = null;
                    _companyInfo = null;
                    _errorMessage = null;
                    _errorStatus = null;
                  });
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: _textGray)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: const TextStyle(color: Colors.black54)),
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.white,
            items: items
                .map((String item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item,
                          style: const TextStyle(color: Colors.black87)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedMonth.isNotEmpty && selectedYear.isNotEmpty
              ? _primaryColor
              : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: canGeneratePayslip && !_apiLoading ? _callPayslipApi : null,
        icon: _apiLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8)),
                ),
              )
            : const Icon(Icons.receipt_long_rounded, size: 20),
        label: Text(
          _apiLoading ? 'Loading...' : 'Generate Payslip',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

// ... rest of the code ...

  int _monthNameToNumber(String name) {
    final idx = months.indexWhere((m) => m.toLowerCase() == name.toLowerCase());
    return (idx >= 0) ? (idx + 1) : 0;
  }

  String _buildFinancialYear(String yearStart) {
    final y = int.tryParse(yearStart) ?? DateTime.now().year;
    return '$y-${y + 1}';
  }

  Future<void> _callPayslipApi() async {
    try {
      setState(() {
        _apiLoading = true;
        _payslipVisible = null;
        _companyInfo = null;
        _errorMessage = null;
        _errorStatus = null;
      });

      final monthNum = _monthNameToNumber(selectedMonth);
      if (monthNum == 0 || selectedYear.isEmpty) {
        throw Exception('Please select month and year');
      }
      final financialYear =
          _buildFinancialYear(selectedYear); // e.g. '2025-2026'

      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure() ?? '';

      final respMap = await PayslipApiService.fetchPayslipDetails(
        empId: user?.employeeId ?? '',
        financialYear: financialYear,
        month: monthNum.toString().padLeft(2, '0'),
        secure: secure,
      );

      final statusVal = respMap['status'];
      final bool isSuccess =
          statusVal == 'success' || respMap['success'] == true;

      if (isSuccess) {
        final data = (respMap['data'] is Map)
            ? Map<String, dynamic>.from(respMap['data'] as Map)
            : <String, dynamic>{};
        final payslip = (data['payslip'] is Map)
            ? Map<String, dynamic>.from(data['payslip'] as Map)
            : <String, dynamic>{};
        final salaryDetails = (payslip['salary_details'] is Map)
            ? Map<String, dynamic>.from(payslip['salary_details'] as Map)
            : <String, dynamic>{};
        final visible = (salaryDetails['visible_data'] is Map)
            ? Map<String, dynamic>.from(salaryDetails['visible_data'] as Map)
            : <String, dynamic>{};
        final company = (data['company_info'] is Map)
            ? Map<String, dynamic>.from(data['company_info'] as Map)
            : <String, dynamic>{};

        if (mounted) {
          setState(() {
            _payslipVisible = visible.isNotEmpty ? visible : null;
            _companyInfo = company.isNotEmpty ? company : null;
            _apiLoading = false;
            _canDownload =
                (respMap['status_code'] == 200) && _payslipVisible != null;
          });
        }
      } else {
        final msg =
            (respMap['message'] ?? 'Failed to fetch payslip').toString();
        final code = respMap['status'] is int
            ? respMap['status'] as int
            : (respMap['status_code'] ?? respMap['code']) as int?;
        if (mounted) {
          setState(() {
            _errorMessage = msg;
            _errorStatus = code;
            _apiLoading = false;
            _canDownload = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _apiLoading = false;
          _canDownload = false;
        });
      }
    }
  }

  Widget _buildErrorBox(String message, int? code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code == 422 ? 'Validation error' : 'Request failed',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipSummaryCard(
      Map<String, dynamic> visible, Map<String, dynamic>? companyInfo) {
    final emp = (visible['employee_details'] is Map)
        ? Map<String, dynamic>.from(visible['employee_details'] as Map)
        : <String, dynamic>{};
    final finalCal = (visible['final_salary_calculation'] is Map)
        ? Map<String, dynamic>.from(visible['final_salary_calculation'] as Map)
        : <String, dynamic>{};
    final sal = (visible['salary_details'] is Map)
        ? Map<String, dynamic>.from(visible['salary_details'] as Map)
        : <String, dynamic>{};
    final monthDetails = (visible['month_details'] is Map)
        ? Map<String, dynamic>.from(visible['month_details'] as Map)
        : <String, dynamic>{};
    final attendance = (visible['attendance_details'] is Map)
        ? Map<String, dynamic>.from(visible['attendance_details'] as Map)
        : <String, dynamic>{};

    String str(dynamic v) => v == null ? '-' : v.toString();
    final inr = NumberFormat.decimalPattern('en_IN');
    String money(dynamic v) {
      if (v == null) return '-';
      final numVal = (v is num) ? v : num.tryParse(v.toString());
      return numVal == null ? '-' : '₹ ${inr.format(numVal)}';
    }

    String monthLabel(dynamic m) {
      final txt = str(m);
      final n = int.tryParse(txt);
      if (n == null || n < 1 || n > 12) return txt;
      return months[n - 1];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.deepPurple),
              ),
              const SizedBox(width: 10),
              const Text(
                'Payslip Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          if (companyInfo != null && companyInfo['comp_name'] != null)
            Text(
              str(companyInfo['comp_name']),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black54),
            ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade300, thickness: 1),

          // 🔹 Payslip Info
          const SizedBox(height: 12),
          _infoRow(Icons.numbers, 'Payslip No', str(visible['payslip_no'])),
          const SizedBox(height: 6),
          _infoRow(Icons.calendar_today_rounded, 'Month',
              '${monthLabel(visible['month'])} (${str(visible['financial_year'])})'),

          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade300),

          // 🔹 Employee Info
          const SizedBox(height: 12),
          _infoRow(Icons.person_rounded, 'Employee',
              '${str(emp['name'])} (${str(emp['employee_id'])})'),
          const SizedBox(height: 6),
          _infoRow(Icons.apartment_rounded, 'Department / Designation',
              '${str(emp['dept_name'])} / ${str(emp['designation_name'])}'),

          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade300),

          // 🔹 Salary Info
          const SizedBox(height: 12),
          const Text("Salary Details",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          _infoRow(Icons.payments_rounded, 'Gross Salary',
              money(sal['gross_salary'])),
          const SizedBox(height: 6),
          _infoRow(Icons.trending_up_rounded, 'Total Additions',
              money(sal['total_addition'])),
          const SizedBox(height: 6),

          // 💰 Highlight Net Salary
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurpleAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Net Salary: ${money(finalCal['net_salary'])}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          Divider(color: Colors.grey.shade300),

          // 🔹 Attendance Overview
          const Text("Attendance Overview",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          _attendanceRow(
              'Working Days',
              str(monthDetails['total_working_days'] ?? '-'),
              'Holidays',
              str(monthDetails['total_holidays'] ?? '-')),
          _attendanceRow('Weekends', str(monthDetails['total_weekends'] ?? '-'),
              'Present', str(attendance['total_present'] ?? '-')),
          _attendanceRow(
              'On Time',
              str(attendance['total_present_on_time'] ?? '-'),
              'Late',
              str(attendance['total_present_late'] ?? '-')),
          _attendanceRow(
              'Early Logout',
              str(attendance['total_early_logout'] ?? '-'),
              'Leaves',
              str(attendance['total_leave_approved'] ?? '-')),
          const SizedBox(height: 6),
          _infoRow(Icons.access_time_rounded, 'Overtime',
              str(attendance['total_overtime_hours'] ?? '-')),

          if (visible['notes'] != null) ...[
            const SizedBox(height: 16),
            Text('Notes: ${str(visible['notes'])}',
                style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.deepPurple),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }

  Widget _attendanceRow(
      String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text("$label1: ",
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                Expanded(
                  child: Text(value1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text("$label2: ",
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black54)),
                Expanded(
                  child: Text(value2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildPayslipSummaryCard(
  //     Map<String, dynamic> visible, Map<String, dynamic>? companyInfo) {
  //   final emp = (visible['employee_details'] is Map)
  //       ? Map<String, dynamic>.from(visible['employee_details'] as Map)
  //       : <String, dynamic>{};
  //   final finalCal = (visible['final_salary_calculation'] is Map)
  //       ? Map<String, dynamic>.from(visible['final_salary_calculation'] as Map)
  //       : <String, dynamic>{};
  //   final sal = (visible['salary_details'] is Map)
  //       ? Map<String, dynamic>.from(visible['salary_details'] as Map)
  //       : <String, dynamic>{};
  //   final monthDetails = (visible['month_details'] is Map)
  //       ? Map<String, dynamic>.from(visible['month_details'] as Map)
  //       : <String, dynamic>{};
  //   final attendance = (visible['attendance_details'] is Map)
  //       ? Map<String, dynamic>.from(visible['attendance_details'] as Map)
  //       : <String, dynamic>{};

  //   String str(dynamic v) => v == null ? '-' : v.toString();
  //   final inr = NumberFormat.decimalPattern('en_IN');
  //   String money(dynamic v) {
  //     if (v == null) return '-';
  //     final numVal = (v is num) ? v : num.tryParse(v.toString());
  //     return numVal == null ? '-' : 'Rs. ${inr.format(numVal)}';
  //   }

  //   String monthLabel(dynamic m) {
  //     final txt = str(m);
  //     final n = int.tryParse(txt);
  //     if (n == null || n < 1 || n > 12) return txt;
  //     return months[n - 1];
  //   }

  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey.shade300),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.03),
  //           blurRadius: 10,
  //           offset: const Offset(0, 2),
  //         )
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const Icon(Icons.receipt_long_rounded, color: Colors.black87),
  //             const SizedBox(width: 8),
  //             const Text(
  //               'Payslip Summary',
  //               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //             ),
  //             const Spacer(),
  //             if (companyInfo != null && companyInfo['comp_name'] != null)
  //               Text(
  //                 str(companyInfo['comp_name']),
  //                 style: const TextStyle(fontWeight: FontWeight.w500),
  //               ),
  //           ],
  //         ),
  //         const SizedBox(height: 10),
  //         Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //           decoration: BoxDecoration(
  //             color: Colors.grey.shade100,
  //             borderRadius: BorderRadius.circular(6),
  //             border: Border.all(color: Colors.grey.shade300),
  //           ),
  //           child: const Text(
  //             'Details',
  //             style: TextStyle(fontWeight: FontWeight.w600),
  //           ),
  //         ),
  //         const SizedBox(height: 10),
  //         _kv2Row('Payslip No', str(visible['payslip_no']), 'Financial Year',
  //             str(visible['financial_year'])),
  //         const SizedBox(height: 6),
  //         _kv('Month', monthLabel(visible['month'])),
  //         const Divider(height: 20),
  //         _kv2Row(
  //             'Employee',
  //             '${str(emp['name'])} (${str(emp['employee_id'])})',
  //             'Dept / Designation',
  //             '${str(emp['dept_name'])} / ${str(emp['designation_name'])}'),
  //         const Divider(height: 20),
  //         _kv2Row('Gross Salary', money(sal['gross_salary']), 'Total Additions',
  //             money(sal['total_addition'])),
  //         const SizedBox(height: 6),
  //         _kv('Net Salary', money(finalCal['net_salary']), highlight: true),
  //         const Divider(height: 24),
  //         // Responsive vertical layout
  //         _kv2Row(
  //             'Working Days',
  //             str(monthDetails['total_working_days'] ?? '-'),
  //             'Holidays',
  //             str(monthDetails['total_holidays'] ?? '-')),
  //         const SizedBox(height: 6),
  //         _kv2Row('Weekends', str(monthDetails['total_weekends'] ?? '-'),
  //             'Present', str(attendance['total_present'] ?? '-')),
  //         const SizedBox(height: 6),
  //         _kv2Row('On time', str(attendance['total_present_on_time'] ?? '-'),
  //             'Late', str(attendance['total_present_late'] ?? '-')),
  //         const SizedBox(height: 6),
  //         _kv2Row('Early Logout', str(attendance['total_early_logout'] ?? '-'),
  //             'Leaves', str(attendance['total_leave_approved'] ?? '-')),
  //         const SizedBox(height: 6),
  //         _kv('Overtime', str(attendance['total_overtime_hours'] ?? '-')),
  //         const SizedBox(height: 10),
  //         if (visible['notes'] != null)
  //           Text('Notes: ${str(visible['notes'])}',
  //               style: TextStyle(color: _textGray)),
  //       ],
  //     ),
  //   );
  // }

  Widget _kv(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: _textGray),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? _primaryColor : _textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
