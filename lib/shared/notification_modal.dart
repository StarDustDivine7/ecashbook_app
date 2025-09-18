import 'package:flutter/material.dart';

class NotificationModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationBottomSheet(),
    );
  }
}

class NotificationBottomSheet extends StatefulWidget {
  const NotificationBottomSheet({super.key});

  @override
  State<NotificationBottomSheet> createState() =>
      _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy notifications data
  final List<Map<String, dynamic>> allNotifications = [
    {
      'title': 'Leave Request Approved ✅',
      'message':
          'Your leave request for Aug 20-22 has been approved by HR department.',
      'time': '2 hours ago',
      'icon': Icons.check_circle,
      'iconColor': const Color(0xFF4CAF50),
      'isRead': false,
    },
    {
      'title': 'New Task Assigned 📋',
      'message': 'Complete the quarterly financial report by end of this week.',
      'time': '4 hours ago',
      'icon': Icons.assignment,
      'iconColor': const Color(0xFF2196F3),
      'isRead': false,
    },
    {
      'title': 'Urgent: System Update 🔄',
      'message':
          'Please update your password before Aug 25. Security requirement.',
      'time': '6 hours ago',
      'icon': Icons.security,
      'iconColor': const Color(0xFFE91E63),
      'isRead': false,
    },
    {
      'title': 'Payslip Generated 💰',
      'message': 'Your payslip for July 2024 is now available for download.',
      'time': '1 day ago',
      'icon': Icons.receipt,
      'iconColor': const Color(0xFF4CAF50),
      'isRead': true,
    },
    {
      'title': 'Meeting Reminder 📅',
      'message':
          'Team standup meeting at 10:30 AM tomorrow in Conference Room A.',
      'time': '1 day ago',
      'icon': Icons.event,
      'iconColor': const Color(0xFFFF9800),
      'isRead': false,
    },
    {
      'title': 'Attendance Reminder ⏰',
      'message': 'Don\'t forget to mark your attendance for today before 6 PM.',
      'time': '2 days ago',
      'icon': Icons.access_time,
      'iconColor': const Color(0xFFFF9800),
      'isRead': true,
    },
    {
      'title': 'HR Letter Available 📄',
      'message':
          'Your experience certificate is ready for download from HR portal.',
      'time': '3 days ago',
      'icon': Icons.description,
      'iconColor': const Color(0xFF9C27B0),
      'isRead': true,
    },
    {
      'title': 'Birthday Wishes 🎉',
      'message': 'Happy Birthday John! Hope you have a wonderful day.',
      'time': '4 days ago',
      'icon': Icons.cake,
      'iconColor': const Color(0xFFE91E63),
      'isRead': true,
    },
    {
      'title': 'System Maintenance 🔧',
      'message': 'System will be down for maintenance on Aug 25, 2-4 AM IST.',
      'time': '1 week ago',
      'icon': Icons.build,
      'iconColor': const Color(0xFFFF5722),
      'isRead': true,
    },
    {
      'title': 'Policy Update 📋',
      'message': 'New remote work policy has been updated. Please review it.',
      'time': '1 week ago',
      'icon': Icons.policy,
      'iconColor': const Color(0xFF607D8B),
      'isRead': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get unread notifications count
  int get unreadCount => allNotifications.where((n) => !n['isRead']).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF422F90), Color(0xFF5A4FCF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        '$unreadCount unread messages',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Mark all as read
                TextButton(
                  onPressed: () {
                    setState(() {
                      for (var notification in allNotifications) {
                        notification['isRead'] = true;
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: Color(0xFF422F90),
                      ),
                    );
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Color(0xFF422F90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Improved Tab Bar with Custom Design
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // All Tab
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final isSelected = _tabController.index == 0;
                      return GestureDetector(
                        onTap: () => _tabController.animateTo(0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF422F90),
                                      Color(0xFF5A4FCF)
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF422F90)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.list_alt,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : const Color(0xFF422F90)
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${allNotifications.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF422F90),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Unread Tab
                Expanded(
                  child: AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final isSelected = _tabController.index == 1;
                      return GestureDetector(
                        onTap: () => _tabController.animateTo(1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF422F90),
                                      Color(0xFF5A4FCF)
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF422F90)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mark_chat_unread,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Unread',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? (isSelected
                                          ? Colors.red.withValues(alpha: 0.9)
                                          : Colors.red)
                                      : (isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: unreadCount > 0
                                        ? Colors.white
                                        : (isSelected
                                            ? Colors.white
                                            : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Notifications List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotifications(),
                _buildUnreadNotifications(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotifications() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: allNotifications.length,
      itemBuilder: (context, index) {
        final notification = allNotifications[index];
        return _buildNotificationItem(
          title: notification['title'],
          message: notification['message'],
          time: notification['time'],
          icon: notification['icon'],
          iconColor: notification['iconColor'],
          isRead: notification['isRead'],
          onTap: () {
            setState(() {
              allNotifications[index]['isRead'] = true;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opened: ${notification['title']}'),
                backgroundColor: notification['iconColor'],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUnreadNotifications() {
    final unreadNotifications =
        allNotifications.where((n) => !n['isRead']).toList();

    if (unreadNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: unreadNotifications.length,
      itemBuilder: (context, index) {
        final notification = unreadNotifications[index];
        return _buildNotificationItem(
          title: notification['title'],
          message: notification['message'],
          time: notification['time'],
          icon: notification['icon'],
          iconColor: notification['iconColor'],
          isRead: notification['isRead'],
          onTap: () {
            setState(() {
              notification['isRead'] = true;
            });
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opened: ${notification['title']}'),
                backgroundColor: notification['iconColor'],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String message,
    required String time,
    required IconData icon,
    required Color iconColor,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color(0xFF422F90).withValues(alpha: 0.05),
        border: Border.all(
          color: isRead
              ? Colors.grey.shade200
              : const Color(0xFF422F90).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF422F90),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No unread notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! 🎉',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
