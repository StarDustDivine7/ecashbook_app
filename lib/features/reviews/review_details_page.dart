import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/bottom_menu.dart';
import '../../shared/main_layout.dart';

class ReviewDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ReviewDetailsPage({super.key, required this.data});

  String _monthName(dynamic m) {
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
    final n = int.tryParse(m?.toString() ?? '');
    if (n == null || n < 1 || n > 12) return m?.toString() ?? '-';
    return names[n - 1];
  }

  String _fmtDate(String? input) {
    if (input == null || input.isEmpty) return '-';
    try {
      final dt = DateTime.parse(input.replaceAll(' ', 'T'));
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return input;
    }
  }

  Widget _stars(dynamic value) {
    int v;
    try {
      v = int.tryParse((value ?? '').toString()) ?? 0;
    } catch (_) {
      v = 0;
    }
    if (v < 0) v = 0;
    if (v > 5) v = 5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < v;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _kvStars(String k, dynamic v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _stars(v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final month = _monthName(data['review_month']);
    final year = (data['review_year'] ?? '').toString();
    final createdAt = _fmtDate(data['created_at']?.toString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HR-letter style header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined),
                    const SizedBox(width: 8),
                    const Text('Performance Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$month $year'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Details',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                _kvStars('Work Rating', data['work_rating']),
                _kvStars('Skill Rating', data['skill_rating']),
                _kvStars('Attendance Rating', data['attendance_rating']),
                _kvStars('Teamwork Rating', data['teamwork_rating']),
                const Divider(height: 24),
                _kv('Total Percentage', '${data['total_percentage'] ?? '-'}%',
                    bold: true),
                const Divider(height: 24),
                const Text('Manager Review',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text((data['review'] ?? '-').toString()),
                const SizedBox(height: 16),
                Text('Created: $createdAt',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: 2,
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
