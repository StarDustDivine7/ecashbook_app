import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supply_service.dart';
import 'supply_details.dart';
import 'apply_supply.dart';
import '../../shared/bottom_sheet_host.dart';
import '../../shared/fullscreen_bottom_sheet.dart';

class SupplyListPage extends ConsumerStatefulWidget {
  const SupplyListPage({super.key});

  @override
  ConsumerState<SupplyListPage> createState() => _SupplyListPageState();
}

class _SupplyListPageState extends ConsumerState<SupplyListPage> {
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4338CA);
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
      ref.read(supplyServiceProvider.notifier).loadSupply();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(supplyServiceProvider);
    final svc = ref.read(supplyServiceProvider.notifier);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => svc.loadSupply(),
                color: _primary,
                child: svc.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (svc.error != null)
                        ? _buildError(svc.error!, svc)
                        : (items.isEmpty
                            ? _buildEmpty(svc)
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final c = items[index];
                                  final sc = _statusColor(c.status);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: _card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.04),
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
                                              builder: (_) => SupplyDetailsPage(
                                                  requisitionId: c.id),
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
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            c.category,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: _textDark,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                sc.withValues(
                                                                    alpha: 0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                            border: Border.all(
                                                                color: sc
                                                                    .withValues(
                                                                        alpha:
                                                                            0.3)),
                                                          ),
                                                          child: Text(
                                                            c.status
                                                                .displayName,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: _textLight,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Qty: ${c.quantity} • Amount: ₹${c.amount.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: _textLight),
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
        child: Container(
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
            heroTag: 'supplyFab',
            onPressed: () {
              showFullscreenBottomSheet(
                context: context,
                title: 'Supply Requisition',
                child: const ApplySupplyPage(),
              );
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),

        // FloatingActionButton(
        //   heroTag: 'supplyFab',
        //   onPressed: () {
        //     final host = BottomSheetHost.of(context);
        //     if (host != null) {
        //       host.show((ctx) {
        //         final h = MediaQuery.of(ctx).size.height;
        //         return SafeArea(
        //           top: false,
        //           child: AnimatedPadding(
        //             duration: const Duration(milliseconds: 200),
        //             curve: Curves.easeOut,
        //             padding: EdgeInsets.only(
        //               bottom: MediaQuery.of(ctx).viewInsets.bottom,
        //             ),
        //             child: SizedBox(
        //               height: h * 0.95,
        //               child: const ApplySupplyPage(),
        //             ),
        //           ),
        //         );
        //       });
        //     } else {
        //       showModalBottomSheet(
        //         context: context,
        //         isScrollControlled: true,
        //         useSafeArea: true,
        //         showDragHandle: true,

        //         backgroundColor: Colors.transparent,
        //         builder: (ctx) => Padding(
        //           padding: MediaQuery.of(ctx).viewInsets,
        //           child: const FractionallySizedBox(
        //             heightFactor: 0.95,
        //             child: ApplySupplyPage(),
        //           ),
        //         ),
        //       );
        //     }
        //   },
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   shape:
        //       RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        //   child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        // ),
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
          Icon(Icons.inventory_2_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Supply Requisitions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildError(String msg, SupplyService svc) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: _accentRed, size: 48),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textLight)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => svc.loadSupply(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primary, foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              )
            ],
          ),
        ),
      );

  Widget _buildEmpty(SupplyService svc) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_rounded, color: _textLight, size: 48),
            SizedBox(height: 12),
            Text('No requisitions yet',
                style: TextStyle(
                    color: _textLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('Tap + to submit a new requisition',
                style: TextStyle(color: _textLight, fontSize: 13)),
          ],
        ),
      );

  Color _statusColor(SupplyStatus s) {
    switch (s) {
      case SupplyStatus.pending:
        return _accentOrange;
      case SupplyStatus.approved:
        return _accentGreen;
      case SupplyStatus.rejected:
        return _accentRed;
    }
  }

  String _fmtDate(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
