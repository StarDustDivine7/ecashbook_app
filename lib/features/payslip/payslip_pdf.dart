import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PayslipPdf {
  static Future<Uint8List> generate({
    required Map<String, dynamic> visible,
    Map<String, dynamic>? companyInfo,
  }) async {
    final doc = pw.Document();

    final emp = (visible['employee_details'] is Map)
        ? Map<String, dynamic>.from(visible['employee_details'] as Map)
        : <String, dynamic>{};
    final finalCal = (visible['final_salary_calculation'] is Map)
        ? Map<String, dynamic>.from(visible['final_salary_calculation'] as Map)
        : <String, dynamic>{};

    pw.ImageProvider? logoProvider;
    pw.ImageProvider? avatarProvider;

    final logoUrl = companyInfo?['comp_logo']?.toString();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        logoProvider = await networkImage(logoUrl);
      } catch (_) {}
    }

    final empPhotoUrl = (emp['photo'] ??
            emp['profile_photo'] ??
            emp['profile_image'] ??
            emp['avatar'] ??
            emp['image'])
        ?.toString();

    if (empPhotoUrl != null && empPhotoUrl.isNotEmpty) {
      try {
        avatarProvider = await networkImage(empPhotoUrl);
      } catch (_) {}
    }

    // ✅ SAFE STRING (NO UNICODE)
    String s(dynamic v) {
      if (v == null) return '-';
      final text = v.toString();

      return text
          .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // remove unicode
          .replaceAll('₹', 'Rs.')
          .replaceAll('rs.', 'Rs.');
    }

    // ✅ SAFE MONEY
    String money(dynamic v) {
      final txt = s(v);
      if (txt == '-' || txt.isEmpty) return txt;
      return 'Rs. $txt';
    }

    String monthName(dynamic m) {
      final names = const [
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
      final txt = s(m);
      final n = int.tryParse(txt);
      if (n == null || n < 1 || n > 12) return txt;
      return names[n - 1];
    }

    pw.Widget kv(String k, String v) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                s(k),
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.Text(s(v), style: const pw.TextStyle(fontSize: 10)),
          ],
        );

    pw.Widget divider() => pw.Container(height: 1, color: PdfColors.grey300);

    List<pw.TableRow> _kvRows(Map<String, dynamic> items) {
      return items.entries.map((e) {
        return pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(
              s(e.key.toString().replaceAll('_', ' ').toUpperCase()),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                s(e.value).replaceAll('₹', 'Rs.'),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ),
        ]);
      }).toList();
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Payslip',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('Payslip Number: ${s(visible['payslip_no'])}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                        'Payslip Month & Year: ${monthName(visible['month'])}',
                        style: const pw.TextStyle(fontSize: 10)),
                    if (logoProvider != null) pw.SizedBox(height: 6),
                    if (logoProvider != null)
                      pw.SizedBox(
                          width: 56, height: 56, child: pw.Image(logoProvider)),
                    if (avatarProvider != null) pw.SizedBox(height: 6),
                    if (avatarProvider != null)
                      pw.SizedBox(
                          width: 56,
                          height: 56,
                          child: pw.Image(avatarProvider)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    s(companyInfo?['comp_name'] ?? 'Company'),
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  if (companyInfo?['comp_email'] != null)
                    pw.Text('Email: ${s(companyInfo?['comp_email'])}',
                        style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          divider(),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              children: [
                kv('Employee', '${s(emp['name'])} (${s(emp['employee_id'])})'),
                kv('Department', s(emp['dept_name'])),
                kv('Designation', s(emp['designation_name'])),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text('Details',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    ..._kvRows({
                      'Basic Salary': money(finalCal['basic_salary']),
                      'HRA': money(finalCal['hra']),
                    }),
                  ],
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    ..._kvRows({
                      'PF': money(finalCal['provident_fund']),
                      'TDS': money(finalCal['tds']),
                    }),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          divider(),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.green100,
            child: pw.Row(
              children: [
                pw.Expanded(
                    child: pw.Text('Net Salary',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Text(money(finalCal['net_salary']),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          if (finalCal['in_words'] != null)
            pw.Text(
              'Net Salary (in Words): ${s(finalCal['in_words'])}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'This is a computer generated payslip. No signature is required.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }
}


// import 'dart:typed_data';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:printing/printing.dart';

// class PayslipPdf {
//   static Future<Uint8List> generate({
//     required Map<String, dynamic> visible,
//     Map<String, dynamic>? companyInfo,
//   }) async {
//     final doc = pw.Document();

//     final emp = (visible['employee_details'] is Map)
//         ? Map<String, dynamic>.from(visible['employee_details'] as Map)
//         : <String, dynamic>{};
//     final finalCal = (visible['final_salary_calculation'] is Map)
//         ? Map<String, dynamic>.from(visible['final_salary_calculation'] as Map)
//         : <String, dynamic>{};

//     pw.ImageProvider? logoProvider;
//     pw.ImageProvider? avatarProvider;
//     final logoUrl = companyInfo?['comp_logo']?.toString();
//     if (logoUrl != null && logoUrl.isNotEmpty) {
//       try {
//         logoProvider = await networkImage(logoUrl);
//       } catch (_) {}
//     }
//     // Try common employee photo keys
//     final empPhotoUrl = (
//           emp['photo'] ??
//           emp['profile_photo'] ??
//           emp['profile_image'] ??
//           emp['avatar'] ??
//           emp['image']
//         )
//         ?.toString();
//     if (empPhotoUrl != null && empPhotoUrl.isNotEmpty) {
//       try {
//         avatarProvider = await networkImage(empPhotoUrl);
//       } catch (_) {}
//     }

//     String s(dynamic v) => v == null ? '-' : v.toString();
//     String money(dynamic v) {
//       final txt = s(v);
//       if (txt == '-' || txt.isEmpty) return txt;
//       return 'Rs. $txt';
//     }
//     String monthName(dynamic m) {
//       final names = const [
//         'January','February','March','April','May','June',
//         'July','August','September','October','November','December'
//       ];
//       final txt = s(m);
//       final n = int.tryParse(txt);
//       if (n == null || n < 1 || n > 12) return txt;
//       return names[n-1];
//     }

//     pw.Widget kv(String k, String v) => pw.Row(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Expanded(
//                 child: pw.Text(k,
//                     style:
//                         pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
//             pw.Text(v, style: const pw.TextStyle(fontSize: 10)),
//           ],
//         );

//     pw.Widget divider() => pw.Container(height: 1, color: PdfColors.grey300);

//     // Earnings and Deductions tables
//     List<pw.TableRow> _kvRows(Map<String, dynamic> items) {
//       return items.entries
//           .map((e) => pw.TableRow(children: [
//                 pw.Padding(
//                     padding: const pw.EdgeInsets.all(6),
//                     child: pw.Text(
//                         e.key.toString().replaceAll('_', ' ').toUpperCase(),
//                         style: const pw.TextStyle(fontSize: 9))),
//                 pw.Padding(
//                     padding: const pw.EdgeInsets.all(6),
//                     child: pw.Align(
//                         alignment: pw.Alignment.centerRight,
//                         child: pw.Text(s(e.value),
//                             style: const pw.TextStyle(fontSize: 9)))),
//               ]))
//           .toList();
//     }

//     doc.addPage(
//       pw.MultiPage(
//         pageTheme: pw.PageTheme(
//           margin: const pw.EdgeInsets.all(24),
//         ),
//         build: (context) => [
//           // Header
//           pw.Row(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               // Left block: Title + details + avatar below
//               pw.Expanded(
//                 child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Text('Payslip',
//                           style: pw.TextStyle(
//                               fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                       pw.SizedBox(height: 2),
//                       pw.Text('Payslip Number: ${s(visible['payslip_no'])}',
//                           style: const pw.TextStyle(fontSize: 10)),
//                       pw.Text('Payslip Month & Year: ${monthName(visible['month'])}',
//                           style: const pw.TextStyle(fontSize: 10)),
//                       // Company logo below month/year
//                       if (logoProvider != null) pw.SizedBox(height: 6),
//                       if (logoProvider != null)
//                         pw.SizedBox(width: 56, height: 56,
//                             child: pw.Image(logoProvider, fit: pw.BoxFit.contain)),
//                       // Optional: employee avatar below
//                       if (avatarProvider != null) pw.SizedBox(height: 6), 
//                       if (avatarProvider != null)
//                         pw.SizedBox(width: 56, height: 56,
//                             child: pw.Image(avatarProvider, fit: pw.BoxFit.cover)),
//                     ]),
//               ),
//               // Company block on right (text only)
//               pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//                 pw.Text(companyInfo?['comp_name']?.toString() ?? 'Company',
//                     style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
//                 if (companyInfo?['comp_bill_addone'] != null)
//                   pw.Text(s(companyInfo?['comp_bill_addone']),
//                       style: const pw.TextStyle(fontSize: 9)),
//                 if (companyInfo?['comp_bill_addtwo'] != null)
//                   pw.Text(s(companyInfo?['comp_bill_addtwo']),
//                       style: const pw.TextStyle(fontSize: 9)),
//                 if (companyInfo?['comp_bill_city'] != null ||
//                     companyInfo?['comp_bill_state'] != null)
//                   pw.Text(
//                     [
//                       companyInfo?['comp_bill_city'],
//                       companyInfo?['comp_bill_state']
//                     ]
//                         .where((e) => e != null && e.toString().isNotEmpty)
//                         .map((e) => e.toString())
//                         .join(', '),
//                     style: const pw.TextStyle(fontSize: 9),
//                   ),
//                 if (companyInfo?['comp_bill_country'] != null)
//                   pw.Text(s(companyInfo?['comp_bill_country']),
//                       style: const pw.TextStyle(fontSize: 9)),
//                 if (companyInfo?['comp_email'] != null)
//                   pw.Text('Email: ${s(companyInfo?['comp_email'])}',
//                       style: const pw.TextStyle(fontSize: 9)),
//                 if (companyInfo?['comp_bill_gst_no'] != null)
//                   pw.Text('GSTIN: ${s(companyInfo?['comp_bill_gst_no'])}',
//                       style: const pw.TextStyle(fontSize: 9)),
//                 if (companyInfo?['comp_pan_no'] != null)
//                   pw.Text('PAN: ${s(companyInfo?['comp_pan_no'])}',
//                       style: const pw.TextStyle(fontSize: 9)),
//               ]),
//             ],
//           ),
//           pw.SizedBox(height: 8),
//           divider(),
//           pw.SizedBox(height: 8),

//           // Employee info grid box
//           pw.Container(
//             decoration: pw.BoxDecoration(
//               border: pw.Border.all(color: PdfColors.grey300),
//               borderRadius: pw.BorderRadius.circular(4),
//             ),
//             padding: const pw.EdgeInsets.all(8),
//             child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Row(children: [
//                     pw.Expanded(child: kv('Employee', '${s(emp['name'])} (${s(emp['employee_id'])})')),
//                     pw.SizedBox(width: 12),
//                     pw.Expanded(child: pw.SizedBox()),
//                   ]),
//                   pw.Row(children: [
//                     pw.Expanded(child: kv('Department', s(emp['dept_name']))),
//                     pw.SizedBox(width: 12),
//                     pw.Expanded(child: kv('Designation', s(emp['designation_name']))),
//                   ]),
//                   pw.Row(children: [
//                     pw.Expanded(child: kv('Joining Date', s(emp['joining_date']))),
//                     pw.SizedBox(width: 12),
//                     pw.Expanded(child: kv('EPF No', s(emp['epf_no']))),
//                   ]),
//                   if (emp['email'] != null || emp['phone'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('Email', s(emp['email']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('Phone', s(emp['phone']))),
//                     ]),
//                   if (emp['bank_name'] != null || emp['account_number'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('Bank Name', s(emp['bank_name']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('Account No', s(emp['account_number']))),
//                     ]),
//                   if (emp['ifsc'] != null || emp['pan_number'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('IFSC Code', s(emp['ifsc']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('PAN No', s(emp['pan_number']))),
//                     ]),
//                   if (emp['uan'] != null || emp['aadhaar'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('UAN', s(emp['uan']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('Aadhaar', s(emp['aadhaar']))),
//                     ]),
//                   if (emp['address'] != null || emp['city'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('Address', s(emp['address']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('City', s(emp['city']))),
//                     ]),
//                   if (emp['state'] != null || emp['country'] != null)
//                     pw.Row(children: [
//                       pw.Expanded(child: kv('State', s(emp['state']))),
//                       pw.SizedBox(width: 12),
//                       pw.Expanded(child: kv('Country', s(emp['country']))),
//                     ]),
//                 ]),
//           ),

//           pw.SizedBox(height: 12),

//           // Details header
//           pw.Container(
//             color: PdfColors.grey200,
//             padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             child: pw.Row(children: [
//               pw.Text('Details',
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//             ]),
//           ),

//           // Earnings & deductions tables side by side with inner padding and gap
//           pw.SizedBox(height: 6),
//           pw.Padding(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 0),
//             child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
//             // Earnings
//             pw.Expanded(
//               child: pw.Table(
//                 border:
//                     pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
//                 columnWidths: {1: const pw.FlexColumnWidth(0.6)},
//                 children: [
//                   pw.TableRow(
//                       decoration:
//                           const pw.BoxDecoration(color: PdfColors.grey200),
//                       children: [
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Text('EARNINGS',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold,
//                                     fontSize: 10))),
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Align(
//                                 alignment: pw.Alignment.centerRight,
//                                 child: pw.Text('AMOUNT',
//                                     style: pw.TextStyle(
//                                         fontWeight: pw.FontWeight.bold,
//                                         fontSize: 10)))),
//                       ]),
//                   ..._kvRows({
//                     'Basic Salary': money(finalCal['basic_salary']),
//                     'House Rent Allowance (HRA)': money(finalCal['hra']),
//                     'Conveyance Allowance': money(finalCal['conveyance']),
//                     'Medical Allowance': money(finalCal['medical_allowance']),
//                     'Special Allowance': money(finalCal['special_allowance']),
//                     if (finalCal['performance_bonus'] != null)
//                       'Performance Bonus': money(finalCal['performance_bonus']),
//                     if (finalCal['overtime_payment'] != null)
//                       'Overtime Payment': money(finalCal['overtime_payment']),
//                   }),
//                   pw.TableRow(
//                       decoration:
//                           const pw.BoxDecoration(color: PdfColors.green100),
//                       children: [
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Text('TOTAL EARNINGS',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold,
//                                     fontSize: 10))),
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Align(
//                                 alignment: pw.Alignment.centerRight,
//                                 child: pw.Text(
//                                     money(finalCal['total_earnings']),
//                                     style: pw.TextStyle(
//                                         fontWeight: pw.FontWeight.bold,
//                                         fontSize: 10)))),
//                       ]),
//                 ],
//               ),
//             ),
//             pw.SizedBox(width: 14),
//             // Deductions
//             pw.Expanded(
//               child: pw.Table(
//                 border:
//                     pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
//                 columnWidths: {1: const pw.FlexColumnWidth(0.6)},
//                 children: [
//                   pw.TableRow(
//                       decoration:
//                           const pw.BoxDecoration(color: PdfColors.grey200),
//                       children: [
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Text('DEDUCTIONS',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold,
//                                     fontSize: 10))),
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Align(
//                                 alignment: pw.Alignment.centerRight,
//                                 child: pw.Text('AMOUNT',
//                                     style: pw.TextStyle(
//                                         fontWeight: pw.FontWeight.bold,
//                                         fontSize: 10)))),
//                       ]),
//                   ..._kvRows({
//                     'Employee Provident Fund (EPF)':
//                         money(finalCal['provident_fund']),
//                     'Employee State Insurance (ESI)': money(finalCal['esi']),
//                     'Professional Tax (PT)': money(finalCal['ptax']),
//                     'Tax Deducted At Source (TDS)': money(finalCal['tds']),
//                     'Loan': money(finalCal['loan']),
//                     'Loss Of Pay (LOP)': money(finalCal['lop']),
//                   }),
//                   pw.TableRow(
//                       decoration:
//                           const pw.BoxDecoration(color: PdfColors.green100),
//                       children: [
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Text('TOTAL DEDUCTIONS',
//                                 style: pw.TextStyle(
//                                     fontWeight: pw.FontWeight.bold,
//                                     fontSize: 10))),
//                         pw.Padding(
//                             padding: const pw.EdgeInsets.all(6),
//                             child: pw.Align(
//                                 alignment: pw.Alignment.centerRight,
//                                 child: pw.Text(
//                                     money(finalCal['total_deductions']),
//                                     style: pw.TextStyle(
//                                         fontWeight: pw.FontWeight.bold,
//                                         fontSize: 10)))),
//                       ]),
//                 ],
//               ),
//             ),
//           ]),
//           ),

//           pw.SizedBox(height: 10),
//           divider(),
//           pw.SizedBox(height: 6),

//           // Net salary
//           pw.Container(
//             padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//             color: PdfColors.green100,
//             child: pw.Row(children: [
//               pw.Expanded(
//                   child: pw.Text('Net Salary',
//                       style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
//               pw.Text(money(finalCal['net_salary']),
//                   style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//             ]),
//           ),

//           // In words
//           pw.SizedBox(height: 8),
//           if (finalCal['in_words'] != null)
//             pw.Text('Net Salary (in Words): ${s(finalCal['in_words'])}',
//                 style: const pw.TextStyle(fontSize: 10)),

//           pw.SizedBox(height: 16),
//           pw.Text(
//               'This is a computer generated payslip. No signature is required.',
//               style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
//         ],
//       ),
//     );

//     return doc.save();
//   }
// }
