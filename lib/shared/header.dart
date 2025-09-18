import 'package:flutter/material.dart';

import 'notification_modal.dart'; // Add this import

class Header extends StatelessWidget implements PreferredSizeWidget {
  final String pageTitle;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final bool showBackButton;

  const Header({
    super.key,
    required this.pageTitle,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Color(0xFF422F90),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side - Breadcrumb/Menu icon
              GestureDetector(
                onTap: onMenuPressed ??
                    () {
                      if (showBackButton) {
                        Navigator.pop(context);
                      } else {
                        // Open drawer if available
                        Scaffold.of(context).openDrawer();
                      }
                    },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1), // Fix: Line 51
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showBackButton ? Icons.arrow_back_ios : Icons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Middle - Page Title
              Expanded(
                child: Text(
                  pageTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Right side - Notification icon
              GestureDetector(
                onTap: onNotificationPressed ??
                    () {
                      // Show notification modal instead of snackbar
                      NotificationModal.show(context);
                    },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1), // Fix: Line 84
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      // Notification badge (shows unread count)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
