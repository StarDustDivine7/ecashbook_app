import 'package:flutter/material.dart';
import '../../core/services/performance_review_service.dart';
import 'review_details_page.dart';
import '../../shared/header.dart';
import '../../shared/side_menu.dart';
import '../../shared/bottom_menu.dart';
import '../../shared/main_layout.dart';

class ReviewListPage extends StatefulWidget {
  final String employeeId;
  final String secure;
  const ReviewListPage({super.key, required this.employeeId, required this.secure});

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  late Future<Map<String, dynamic>> _future;

  // Design colors copied to match HR Letter list look & feel
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardWhite = Colors.white;
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _future = PerformanceReviewService.fetchReviews(
      employeeId: widget.employeeId,
      secure: widget.secure,
    );
  }

  String _monthName(dynamic m) {
    final names = const [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final n = int.tryParse(m?.toString() ?? '');
    if (n == null || n < 1 || n > 12) return m?.toString() ?? '-';
    return names[n - 1];
  }

  Color _percentColor(String percentStr) {
    final p = double.tryParse(percentStr.replaceAll('%', '')) ?? -1;
    if (p >= 85) return _accentGreen;
    if (p >= 70) return _accentBlue;
    if (p >= 50) return _accentOrange;
    return _errorRed;
  }

  Widget _buildHeader(int count) {
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
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Reviews',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count records',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildReviewCard(BuildContext context, Map m) {
    final month = _monthName(m['review_month']);
    final year = (m['review_year'] ?? '').toString();
    final percent = (m['total_percentage'] ?? '').toString();
    final review = (m['review'] ?? '').toString();
    final indicatorColor = _percentColor(percent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewDetailsPage(data: Map<String, dynamic>.from(m)),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPurple, _primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: Text(
                      'PR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
                          // const Expanded(
                          //   child: Text(
                          //     'HR Department',
                          //     style: TextStyle(
                          //       fontSize: 14,
                          //       fontWeight: FontWeight.w600,
                          //       color: _textDark,
                          //     ),
                          //   ),
                          // ),
                          Spacer(),
                          Text(
                            '$month $year',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$month $year — $percent%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review.toString().replaceAll('\n', ' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textLight,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: const Header(
        pageTitle: 'Performance Reviews',
        showBackButton: false,
      ),
      drawer: const SideMenu(),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final resp = snapshot.data ?? const {};
            final ok = (resp['status']?.toString().toLowerCase() == 'success');
            final List list = ok && resp['data'] is List ? resp['data'] as List : const [];

            return Column(
              children: [
                _buildHeader(list.length),
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No reviews found'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            setState(() {
                              _future = PerformanceReviewService.fetchReviews(
                                employeeId: widget.employeeId,
                                secure: widget.secure,
                              );
                            });
                            await _future;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final m = list[i] as Map;
                              return _buildReviewCard(context, m);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomMenuBar(
        currentIndex: 2, // Keep consistent with other detail pages (Dashboard center)
        onTap: (index) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainLayout(initialIndex: index)),
          );
        },
      ),
    );
  }
}

