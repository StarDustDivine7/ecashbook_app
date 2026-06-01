import 'package:flutter/material.dart';
import 'hr_letter_view.dart';
import '../../core/services/hr_letter_service.dart';

class HrLetterListPage extends StatefulWidget {
  const HrLetterListPage({super.key});

  @override
  State<HrLetterListPage> createState() => _HrLetterListPageState();
}

class _HrLetterListPageState extends State<HrLetterListPage> {
  // Premium Design Colors
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

  // Letters data (filled from API)
  List<Map<String, dynamic>> hrLetters = [];
  bool _loading = false;
  String? _error;
  final Set<String> _readIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLetters();
  }

  DateTime? _parseSentAt(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.tryParse(iso);
  }

  Future<void> _fetchLetters() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await HrLetterService.getLetterListForCurrentUser();
      if (resp['success'] == true) {
        final List data = resp['data'] as List;
        final List<Map<String, dynamic>> mapped =
            data.map<Map<String, dynamic>>((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final sentAt = (m['sent_at'] ?? '').toString();
          final parts = sentAt.split(' ');
          final datePart = parts.isNotEmpty ? parts.first : '';
          final timePart = parts.length > 1 ? parts[1] : '';
          final id = (m['id'] ?? '').toString();
          return {
            'id': id,
            'subject': (m['subject'] ?? '').toString(),
            'sender': 'HR Department',
            'senderEmail': 'hr@ecashbook.com',
            'date': datePart,
            'time': timePart,
            'content': (m['content'] ?? '').toString(),
            // temp; will be set below so only latest is unread
            'isRead': true,
            'priority': 'medium',
            'sentAt': _parseSentAt(sentAt),
          };
        }).toList();
        // Determine the latest item by sentAt; mark only it as unread
        String? latestId;
        DateTime? latestAt;
        for (final item in mapped) {
          final dt = item['sentAt'] as DateTime?;
          if (dt == null) continue;
          if (latestAt == null || dt.isAfter(latestAt)) {
            latestAt = dt;
            latestId = item['id'] as String;
          }
        }
        if (latestId == null && mapped.isNotEmpty) {
          latestId = mapped.first['id'] as String; // fallback
        }
        for (final item in mapped) {
          item['isRead'] = (item['id'] != latestId);
        }
        // Sort: Unread first, then by sentAt descending (most recent first)
        mapped.sort((a, b) {
          final aUnread = !(a['isRead'] as bool);
          final bUnread = !(b['isRead'] as bool);
          if (aUnread != bUnread) {
            return aUnread ? -1 : 1; // unread first
          }
          final da = a['sentAt'] as DateTime?;
          final db = b['sentAt'] as DateTime?;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });
        setState(() {
          hrLetters = mapped;
        });
      } else {
        setState(() {
          _error = (resp['message'] ?? 'Failed to load letters').toString();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // MARK LETTER AS READ WHEN OPENED
  void _markAsRead(String letterId) {
    setState(() {
      final letterIndex = hrLetters.indexWhere(
          (letter) => letter['id'] == letterId); // FIXED: Updated reference
      if (letterIndex != -1) {
        hrLetters[letterIndex]['isRead'] = true; // FIXED: Updated reference
        _readIds.add(letterId);
      }
    });
  }

  // GET UNREAD COUNT
  int get _unreadCount => hrLetters
      .where((letter) => !letter['isRead'])
      .length; // FIXED: Updated reference

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Stats - NO APP BAR
            Container(
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
                      Icons.mail_outline_rounded,
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
                          'Your Messages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${hrLetters.length} letters received', // FIXED: Updated reference
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // DYNAMIC UNREAD COUNT
                  if (_unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accentGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _accentGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_unreadCount New',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'All Read',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Letters List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState(_error!)
                      : hrLetters.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount:
                                  hrLetters.length, // FIXED: Updated reference
                              itemBuilder: (context, index) {
                                final letter = hrLetters[
                                    index]; // FIXED: Updated reference
                                return _buildLetterCard(context, letter, index);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 48, color: _textLight),
          const SizedBox(height: 8),
          Text('No letters found', style: TextStyle(color: _textLight)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchLetters,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: _errorRed),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: _textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchLetters,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLetterCard(
      BuildContext context, Map<String, dynamic> letter, int index) {
    final bool isUnread = !letter['isRead'];
    final Color priorityColor = _getPriorityColor(letter['priority']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // DIFFERENT BACKGROUND FOR UNREAD
        color: isUnread ? _primaryPurple.withValues(alpha: 0.02) : _cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isUnread ? _primaryPurple.withValues(alpha: 0.3) : _borderColor,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? _primaryPurple.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // MARK AS READ WHEN TAPPED
            _markAsRead(letter['id']);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HrLetterViewPage(
                  subject: letter['subject'],
                  sender: letter['sender'],
                  senderEmail: letter['senderEmail'],
                  date: letter['date'],
                  time: letter['time'],
                  content: letter['content'],
                  priority: letter['priority'],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Indicator - MORE PROMINENT FOR UNREAD
                Container(
                  width: isUnread ? 5 : 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 16),

                // Sender Avatar - ENHANCED FOR UNREAD
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnread
                          ? [_primaryPurple, _primaryDark]
                          : [_textLight, _textLight.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: isUnread
                        ? Border.all(
                            color: _primaryPurple.withValues(alpha: 0.3),
                            width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      letter['sender'].toString().substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Letter Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              letter['sender'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isUnread ? _primaryPurple : _textDark,
                              ),
                            ),
                          ),
                          // READ STATUS INDICATOR
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentOrange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: _accentGreen,
                                size: 16,
                              ),
                            ),
                          Text(
                            letter['date'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isUnread ? _primaryPurple : _textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Subject - ENHANCED FOR UNREAD
                      Text(
                        letter['subject'],
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isUnread ? FontWeight.w800 : FontWeight.w600,
                          color: isUnread ? _textDark : _textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Content Preview
                      Text(
                        letter['content'].toString().replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textLight,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Unread Indicator Dot - ENHANCED
                if (isUnread) ...[
                  const SizedBox(width: 12),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_accentBlue, _primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: _accentBlue.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return _errorRed;
      case 'medium':
        return _accentBlue;
      case 'low':
        return _accentGreen;
      default:
        return _textLight;
    }
  }
}
