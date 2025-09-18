import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'payslip_service.dart';

class PayslipPage extends StatefulWidget {
  const PayslipPage({super.key});

  @override
  State<PayslipPage> createState() => _PayslipPageState();
}

class _PayslipPageState extends State<PayslipPage> {
  // ✅ UPDATED: Use your app's primary color instead of blue
  final Color _primaryColor = const Color(0xFF6366F1); // Change this to your primary color
  final Color _accentGreen = const Color(0xFF10B981);
  final Color _textDark = const Color(0xFF1F2937);
  final Color _textGray = const Color(0xFF6B7280);
  final Color _errorRed = const Color(0xFFEF4444);
  final Color _backgroundGray = const Color(0xFFF9FAFB);

  String selectedMonth = '';
  String selectedYear = '';

  bool isGenerating = false;
  bool isDownloading = false;
  bool hasPayslipData = false;

  PayslipData? currentPayslip;
  String? downloadedFilePath;

  final PayslipService _payslipService = PayslipService();

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> years = ['2025', '2024', '2023', '2022', '2021', '2020'];

  // Check if Generate button should be enabled
  bool get canGeneratePayslip => selectedMonth.isNotEmpty && selectedYear.isNotEmpty;

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

              // Generate Payslip Button
              _buildGenerateButton(),

              // Show payslip card only if data exists
              if (hasPayslipData && currentPayslip != null) ...[
                const SizedBox(height: 20),
                _buildPayslipCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
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
          // ✅ CENTERED: Select Pay Period title
          Center(
            child: Text(
              'Select Pay Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Month',
                  value: selectedMonth.isEmpty ? null : selectedMonth,
                  hint: 'Select Month',
                  items: months,
                  onChanged: (value) {
                    setState(() {
                      selectedMonth = value ?? '';
                      // Reset payslip data when month changes
                      _resetPayslipData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Year',
                  value: selectedYear.isEmpty ? null : selectedYear,
                  hint: 'Select Year',
                  items: years,
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value ?? '';
                      // Reset payslip data when year changes
                      _resetPayslipData();
                    });
                  },
                ),
              ),
            ],
          ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textGray,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint, style: TextStyle(color: _textGray)),
            isExpanded: true,
            underline: const SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
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
          backgroundColor: canGeneratePayslip ? _primaryColor : Colors.grey.shade400, // ✅ UPDATED
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: canGeneratePayslip && !isGenerating ? _generatePayslip : null,
        icon: isGenerating
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
          ),
        )
            : const Icon(Icons.receipt_long_rounded, size: 20),
        label: Text(
          isGenerating ? 'Generating...' : 'Generate Payslip',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPayslipCard() {
    if (currentPayslip == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
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
          // Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1), // ✅ UPDATED
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: _primaryColor, // ✅ UPDATED
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payslip for ${currentPayslip!.month} ${currentPayslip!.year}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: TextStyle(
                        fontSize: 14,
                        color: _textGray,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Employee Details
          _buildSection(
            'Employee Details',
            [
              _buildDetailRow('Name', currentPayslip!.employeeName),
              _buildDetailRow('Pay Period', '${currentPayslip!.month} ${currentPayslip!.year}'),
            ],
          ),

          const SizedBox(height: 20),

          // Earnings
          _buildSection(
            'Earnings',
            [
              _buildDetailRow('Basic Salary', '₹${_formatCurrency(currentPayslip!.basicSalary)}'),
              _buildDetailRow('HRA', '₹${_formatCurrency(currentPayslip!.hra)}'),
              _buildDetailRow('Conveyance', '₹${_formatCurrency(currentPayslip!.conveyance)}'),
              _buildDetailRow('Medical', '₹${_formatCurrency(currentPayslip!.medical)}'),
              _buildDetailRow('Special Bonus', '₹${_formatCurrency(currentPayslip!.specialBonus)}'),
              const Divider(),
              _buildDetailRow(
                'Total Earnings',
                '₹${_formatCurrency(currentPayslip!.totalEarnings)}',
                isTotal: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Deductions
          _buildSection(
            'Deductions',
            [
              _buildDetailRow('EPF', '₹${_formatCurrency(currentPayslip!.epf)}'),
              _buildDetailRow('Professional Tax', '₹${_formatCurrency(currentPayslip!.professionalTax)}'),
              _buildDetailRow('ESI', '₹${_formatCurrency(currentPayslip!.esi)}'),
              const Divider(),
              _buildDetailRow(
                'Total Deductions',
                '₹${_formatCurrency(currentPayslip!.totalDeductions)}',
                isTotal: true,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Net Salary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Net Payable',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹${_formatCurrency(currentPayslip!.netPayable)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _backgroundGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? _textDark : _textGray,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Download Button
        SizedBox(
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
            onPressed: isDownloading ? null : _downloadPDF,
            icon: isDownloading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
              ),
            )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              isDownloading ? 'Downloading...' : 'Download PDF',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ✅ FIXED: Share Button - Enabled after payslip generation (not download)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor, // ✅ Always use primary color when enabled
              side: BorderSide(color: _primaryColor), // ✅ Always use primary color when enabled
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: hasPayslipData && currentPayslip != null ? _sharePDF : null, // ✅ FIXED: Enable after generation
            icon: const Icon(Icons.share_rounded, size: 20),
            label: const Text(
              'Share PDF', // ✅ Simple text
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // ✅ UPDATED: Reset payslip data AND downloadedFilePath when month/year changes
  void _resetPayslipData() {
    setState(() {
      hasPayslipData = false;
      currentPayslip = null;
      downloadedFilePath = null; // ✅ RESET download path so share button disables
    });
  }

  // ✅ GENERATE PAYSLIP FROM SERVICE
  Future<void> _generatePayslip() async {
    if (!canGeneratePayslip) return;

    setState(() {
      isGenerating = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Get payslip data from service
      final payslipData = await _payslipService.getPayslip(
        selectedMonth,
        int.parse(selectedYear),
      );

      if (payslipData != null) {
        setState(() {
          currentPayslip = payslipData;
          hasPayslipData = true;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: _accentGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Payslip generated successfully',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: _textDark,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('No payslip data found for the selected period');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: _errorRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to generate payslip: $e',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  // ✅ DOWNLOAD PDF WITH NOTIFICATION
  Future<void> _downloadPDF() async {
    if (currentPayslip == null) return;

    setState(() {
      isDownloading = true;
    });

    try {
      // Request storage permission
      await _requestStoragePermission();

      final pdf = await _generatePDF();
      final bytes = await pdf.save();

      // Save file universally
      final savedPath = await _saveFileUniversally(bytes);

      downloadedFilePath = savedPath;

      // ✅ SHOW DOWNLOAD NOTIFICATION IN NOTIFICATION PANEL
      await _showDownloadNotification(savedPath);

      // Show in-app success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_done_rounded,
                  color: _accentGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PDF downloaded successfully',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _textDark,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: _accentGreen,
              onPressed: () async {
                await _openPDF(savedPath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: _errorRed, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to download PDF: $e',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading = false;
        });
      }
    }
  }

  // ✅ SHOW ANDROID NOTIFICATION
  Future<void> _showDownloadNotification(String filePath) async {
    try {
      const platform = MethodChannel('com.ecashbook.app/notifications');
      await platform.invokeMethod('showDownloadNotification', {
        'title': 'Download Complete',
        'message': 'Payslip for ${currentPayslip!.month} ${currentPayslip!.year} has been downloaded',
        'filePath': filePath,
        'fileName': 'Payslip_${currentPayslip!.month}_${currentPayslip!.year}.pdf',
      });
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  // ✅ UNIVERSAL PERMISSION REQUEST
  Future<void> _requestStoragePermission() async {
    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkVersion = androidInfo.version.sdkInt;

    if (sdkVersion >= 33) { // Android 13+
      List<Permission> permissions = [
        Permission.photos,
        Permission.videos,
      ];

      for (Permission permission in permissions) {
        final status = await permission.request();
        if (status.isGranted) {
          return;
        }
      }

      final manageStatus = await Permission.manageExternalStorage.request();
      if (!manageStatus.isGranted) {
        throw Exception('Storage permission required for downloads');
      }
    } else {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
    }
  }

  // ✅ UNIVERSAL FILE SAVING
  Future<String> _saveFileUniversally(List<int> bytes) async {
    final fileName = 'Payslip_${currentPayslip!.month}_${currentPayslip!.year}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      if (sdkVersion >= 30) {
        return await _saveToMediaStore(bytes, fileName);
      } else {
        return await _saveToDownloads(bytes, fileName);
      }
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  Future<String> _saveToMediaStore(List<int> bytes, String fileName) async {
    try {
      const platform = MethodChannel('com.ecashbook.app/file_operations');
      final result = await platform.invokeMethod('saveToDownloads', {
        'fileName': fileName,
        'bytes': bytes,
        'mimeType': 'application/pdf',
      });
      return result as String;
    } catch (e) {
      debugPrint('MediaStore save failed, using fallback: $e');
      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  Future<String> _saveToDownloads(List<int> bytes, String fileName) async {
    final downloadsDirectory = Directory('/storage/emulated/0/Download');

    if (await downloadsDirectory.exists()) {
      final file = File('${downloadsDirectory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } else {
      final directory = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYSLIP',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Pay Period: ${currentPayslip!.month} ${currentPayslip!.year}',
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.blue600),
                  ),
                  pw.Text(
                    'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Employee Details
            _buildPDFSection('Employee Details', [
              ['Name', currentPayslip!.employeeName],
              ['Pay Period', '${currentPayslip!.month} ${currentPayslip!.year}'],
            ]),

            pw.SizedBox(height: 20),

            // Earnings
            _buildPDFSection('Earnings', [
              ['Basic Salary', '₹${_formatCurrency(currentPayslip!.basicSalary)}'],
              ['HRA', '₹${_formatCurrency(currentPayslip!.hra)}'],
              ['Conveyance', '₹${_formatCurrency(currentPayslip!.conveyance)}'],
              ['Medical', '₹${_formatCurrency(currentPayslip!.medical)}'],
              ['Special Bonus', '₹${_formatCurrency(currentPayslip!.specialBonus)}'],
              ['Total Earnings', '₹${_formatCurrency(currentPayslip!.totalEarnings)}'],
            ]),

            pw.SizedBox(height: 20),

            // Deductions
            _buildPDFSection('Deductions', [
              ['EPF', '₹${_formatCurrency(currentPayslip!.epf)}'],
              ['Professional Tax', '₹${_formatCurrency(currentPayslip!.professionalTax)}'],
              ['ESI', '₹${_formatCurrency(currentPayslip!.esi)}'],
              ['Total Deductions', '₹${_formatCurrency(currentPayslip!.totalDeductions)}'],
            ]),

            pw.SizedBox(height: 20),

            // Net Salary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Net Payable',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '₹${_formatCurrency(currentPayslip!.netPayable)}',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFSection(String title, List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: rows.map((row) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(row[0], style: pw.TextStyle(color: PdfColors.grey600)),
                    pw.Text(
                      row[1],
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _sharePDF() async {
    if (currentPayslip == null) return;

    try {
      // ✅ GENERATE PDF DYNAMICALLY FOR SHARING
      final pdf = await _generatePDF();
      final bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Payslip_${currentPayslip!.month}_${currentPayslip!.year}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: _errorRed, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to share PDF',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _errorRed,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openPDF(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, color: _errorRed, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to open PDF',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _errorRed,
          ),
        );
      }
    }
  }
}
