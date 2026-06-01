import 'package:ecashbook_app/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/expenditure_api_service.dart';
import '../../shared/bottom_menu.dart';
import '../../shared/main_layout.dart';

class ClaimDetailsPage extends ConsumerStatefulWidget {
  final String claimId;
  const ClaimDetailsPage({super.key, required this.claimId});

  @override
  ConsumerState<ClaimDetailsPage> createState() => _ClaimDetailsPageState();
}

class _ClaimDetailsPageState extends ConsumerState<ClaimDetailsPage> {
  static const Color _primary = Color(0xFF6366F1); // App primary purple
  static const Color _primaryDark = Color(0xFF4338CA); // App primary dark
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final user = await AuthService.getSavedUser();
      final secure = await AuthService.getSecure();
      if (user == null || secure == null) {
        setState(() {
          error = 'Session expired. Please login again.';
          loading = false;
        });
        return;
      }
      final res = await ExpenditureApiService.getClaimDetails(
        employeeId: user.employeeId,
        claimId: widget.claimId,
        secure: secure,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          data = (res['data'] as Map?)?.cast<String, dynamic>();
          loading = false;
        });
      } else {
        setState(() {
          error = res['message']?.toString();
          loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Claim Details';
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? _buildError(error!)
              : _buildDetails(),
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

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: Colors.red.shade400, size: 48),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textLight)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              )
            ],
          ),
        ),
      );

  Widget _buildDetails() {
    final d = data ?? {};
    final category = (d['category'] ?? '-').toString();
    final amount = (d['claim_amount'] ?? d['amount'] ?? '-').toString();
    final date = (d['claim_date'] ?? d['date'] ?? '-').toString();
    final method = (d['payment_method'] ?? '-').toString();
    final status = (d['status'] ?? '-').toString();
    final details = (d['details'] ?? d['description'] ?? '-').toString();
    final comments = (d['comments'] ?? '').toString();
    final receiptUrl = (d['receipt'] ?? '').toString();

    final statusColor = _statusColor(status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeaderCard(category, amount, status, statusColor),
        _buildInfoCard(
          children: [
            _infoRow('Date', date),
            _divider(),
            _infoRow('Payment Method', method),
            _divider(),
            _infoRow('Status', status, valueColor: statusColor),
          ],
        ),
        _buildInfoCard(
          title: 'Details',
          children: [
            Text(details,
                style: const TextStyle(fontSize: 14, color: _textDark)),
            if (comments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Comments',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textLight)),
              const SizedBox(height: 6),
              Text(comments,
                  style: const TextStyle(fontSize: 14, color: _textDark)),
            ],
          ],
        ),
        if (receiptUrl.isNotEmpty)
          _buildInfoCard(
            title: 'Receipt',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  receiptUrl,
                  fit: BoxFit.cover,
                  height: 220,
                  width: double.infinity,
                  errorBuilder: (ctx, err, st) => Container(
                    height: 100,
                    alignment: Alignment.center,
                    color: _surface,
                    child: const Text('Open receipt',
                        style: TextStyle(color: _textLight)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Open in browser using default handler
                  // ignore: deprecated_member_use
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => _ReceiptWebView(url: receiptUrl),
                  ));
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Receipt'),
              )
            ],
          ),
      ],
    );
  }

  Widget _buildHeaderCard(
      String category, String amount, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            color: _primary.withValues(alpha: 0.3),
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
            child: const Icon(Icons.request_quote_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Amount: ₹$amount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard({String? title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _textLight)),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textLight)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? _textDark),
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 1,
        color: _border,
      );

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _ReceiptWebView extends StatelessWidget {
  final String url;
  const _ReceiptWebView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Receipt'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Image.network(url)

        // Center(
        //   child: SelectableText(url, textAlign: TextAlign.center),
        // ),
        );
  }
}
