import 'package:flutter/material.dart';

class BottomMenuBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomMenuBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.transparent, // Main container is now transparent
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main bottom bar with curved notch
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 100),
              painter: BottomNavBarPainter(),
            ),
          ),

          // Navigation items container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color:
                  Colors.transparent, // Navigation container also transparent
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Payslip',
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Icons.task_alt_outlined,
                    label: 'Task',
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  // Empty space for floating button
                  const SizedBox(width: 60),
                  _buildNavItem(
                    icon: Icons.event_note_outlined,
                    label: 'Leave',
                    index: 3,
                    isSelected: currentIndex == 3,
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    index: 4,
                    isSelected: currentIndex == 4,
                  ),
                ],
              ),
            ),
          ),

          // Floating Dashboard Button
          Positioned(
            top: -5,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: currentIndex == 2
                      ? const Color(0xFF422F90)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentIndex == 2
                        ? const Color(0xFF422F90)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentIndex == 2
                          ? const Color(0xFF422F90)
                              .withValues(alpha: 0.2) // Fix: Line 97
                          : Colors.black.withValues(alpha: 0.1), // Fix: Line 98
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home,
                  size: 28,
                  color: currentIndex == 2
                      ? Colors.white
                      : const Color(0xFF422F90),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF422F90)
                        .withValues(alpha: 0.1) // Fix: Line 135
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color:
                    isSelected ? const Color(0xFF422F90) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected ? const Color(0xFF422F90) : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF422F90),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the full-width rounded bar with gentle notch
// Custom painter for the full-width rounded bar with gentle notch
class BottomNavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw shadow first
    Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    Path shadowPath = _createPath(size, 2);
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw main white bar path
    Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    Path path = _createPath(size, 0);
    canvas.drawPath(path, whitePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;

  Path _createPath(Size size, double offset) {
    Path path = Path();

    // Start from bottom left (full width, no padding)
    path.moveTo(20, size.height + offset);
    path.lineTo(size.width - 20, size.height + offset);

    // Bottom right rounded corner
    path.quadraticBezierTo(
      size.width,
      size.height + offset,
      size.width,
      size.height - 20 + offset,
    );

    // Right side up
    path.lineTo(size.width, 30 + offset);

    // Top right rounded corner
    path.quadraticBezierTo(
      size.width,
      20 + offset,
      size.width - 10,
      20 + offset,
    );

    // Top edge to notch start
    path.lineTo(size.width * 0.62, 20 + offset);

    // Gentle curve down for notch
    path.quadraticBezierTo(
      size.width * 0.58,
      20 + offset,
      size.width * 0.55,
      30 + offset,
    );

    // Bottom of notch - gentle curve
    path.quadraticBezierTo(
      size.width * 0.5,
      35 + offset,
      size.width * 0.45,
      30 + offset,
    );

    // Gentle curve up from notch
    path.quadraticBezierTo(
      size.width * 0.42,
      20 + offset,
      size.width * 0.38,
      20 + offset,
    );

    // Top left edge
    path.lineTo(10, 20 + offset);

    // Top left rounded corner
    path.quadraticBezierTo(
      0,
      20 + offset,
      0,
      30 + offset,
    );

    // Left side down
    path.lineTo(0, size.height - 20 + offset);

    // Bottom left rounded corner
    path.quadraticBezierTo(
      0,
      size.height + offset,
      20,
      size.height + offset,
    );

    path.close();
    return path;
  }
}
