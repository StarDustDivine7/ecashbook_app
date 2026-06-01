import 'package:flutter/material.dart';

class FullscreenBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final bool showDragHandle;

  const FullscreenBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && onClose != null) {
          onClose!();
        }
      },
      child: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              if (showDragHandle)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              
              // Custom header with close button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Fullscreen content
              Expanded(
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to show fullscreen bottom sheet
Future<T?> showFullscreenBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FullscreenBottomSheet(
      title: title,
      child: child,
      onClose: () => Navigator.of(ctx).pop(),
    ),
  );
}
