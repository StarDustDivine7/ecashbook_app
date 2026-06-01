import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'expenditure_service.dart';
import 'claim_details.dart';
import 'apply_claim.dart';
import '../../shared/bottom_sheet_host.dart';
import '../../shared/fullscreen_bottom_sheet.dart';

class ClaimsListPage extends ConsumerStatefulWidget {
  const ClaimsListPage({super.key});

  @override
  ConsumerState<ClaimsListPage> createState() => _ClaimsListPageState();
}

class _ClaimsListPageState extends ConsumerState<ClaimsListPage> {
  static const Color _primary = Color(0xFF6366F1); // App primary purple
  static const Color _primaryDark = Color(0xFF4338CA); // App primary dark
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _card = Colors.white;
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenditureServiceProvider.notifier).loadClaims();
    });
  }

  @override
  Widget build(BuildContext context) {
    final claims = ref.watch(expenditureServiceProvider);
    final svc = ref.read(expenditureServiceProvider.notifier);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => svc.loadClaims(),
                color: _primary,
                child: svc.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (svc.error != null)
                        ? _buildError(svc.error!, svc)
                        : (claims.isEmpty
                            ? _buildEmpty(svc)
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: claims.length,
                                itemBuilder: (context, index) {
                                  final c = claims[index];
                                  final sc = _statusColor(c.status);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
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
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ClaimDetailsPage(claimId: c.id),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: sc,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            c.category,
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w700,
                                                              color: _textDark,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: sc.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(color: sc.withValues(alpha: 0.3)),
                                                          ),
                                                          child: Text(
                                                            c.status.displayName,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w700,
                                                              color: sc,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      _fmtDate(c.date),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: _textLight,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Amount: ₹${c.amount.toStringAsFixed(2)} • ${c.paymentMethod}',
                                                      style: const TextStyle(fontSize: 12, color: _textLight),
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
                                },
                              )),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'claimsFab',
          onPressed: () {
            showFullscreenBottomSheet(
              context: context,
              title: 'Expenditure Claim',
              child: const ApplyClaimPage(),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: _primary.withValues(alpha: 0.3),
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
            child: Text(
              'Expenditure Claims',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildError(String msg, ExpenditureService svc) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: _accentRed, size: 48),
              const SizedBox(height: 12),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: _textLight)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => svc.loadClaims(),
                style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              )
            ],
          ),
        ),
      );

  Widget _buildEmpty(ExpenditureService svc) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, color: _textLight, size: 48),
            const SizedBox(height: 12),
            const Text('No claims yet', style: TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Tap + to submit a new claim', style: TextStyle(color: _textLight, fontSize: 13)),
          ],
        ),
      );

  Color _statusColor(ClaimStatus s) {
    switch (s) {
      case ClaimStatus.pending:
        return _accentOrange;
      case ClaimStatus.approved:
        return _accentGreen;
      case ClaimStatus.rejected:
        return _accentRed;
    }
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
