import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

/// Plant chat bubble widget displaying animated messages from the farm
class PlantChatBubble extends StatefulWidget {
  final String message;
  final String mood; // 'happy', 'good', 'stressed', 'critical'

  const PlantChatBubble({
    super.key,
    required this.message,
    required this.mood,
  });

  @override
  State<PlantChatBubble> createState() => _PlantChatBubbleState();
}

class _PlantChatBubbleState extends State<PlantChatBubble>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _plantController;
  late Animation<double> _bubbleFadeAnimation;
  late Animation<Offset> _bubbleSlideAnimation;
  late Animation<double> _plantBounceAnimation;

  @override
  void initState() {
    super.initState();

    // Bubble fade + slide up animation (300ms)
    _bubbleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bubbleFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );

    _bubbleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeOutCubic),
    );

    // Plant bounce animation (continuous, 1.2s loop)
    _plantController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _plantBounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _plantController, curve: Curves.easeInOutQuad),
    );

    // Start bubble animation
    _bubbleController.forward();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _plantController.dispose();
    super.dispose();
  }

  Color _getMoodColor() {
    switch (widget.mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFFD1FAE5); // Light green
      case 'good':
        return const Color(0xFFCFF0F5); // Soft blue-green
      case 'stressed':
        return const Color(0xFFFED7AA); // Light orange
      case 'critical':
        return const Color(0xFFFECACA); // Light red
      default:
        return const Color(0xFFD1FAE5);
    }
  }

  /// Calculate vertical position for bouncing animation
  double _getBounceOffset() {
    // Animate from 0 to 1 and back
    // At 0 and 1: offset is 0
    // At 0.5: offset is -8 (moves up)
    if (_plantBounceAnimation.value < 0.5) {
      // First half: move up
      return -(_plantBounceAnimation.value * 2) * 8;
    } else {
      // Second half: move down
      return -(2 - _plantBounceAnimation.value * 2) * 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _bubbleSlideAnimation,
      child: FadeTransition(
        opacity: _bubbleFadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Plant avatar with bounce animation
              AnimatedBuilder(
                animation: _plantBounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _getBounceOffset()),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getMoodColor(),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '🌱',
                          style: TextStyle(
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Chat bubble
              Expanded(
                child: _buildChatBubble(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the chat bubble with tail
  Widget _buildChatBubble() {
    return Stack(
      children: [
        // Main bubble
        Container(
          decoration: BoxDecoration(
            color: _getMoodColor(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Text(
            widget.message,
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.charcoalGreen,
            ).copyWith(
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
          ),
        ),
        // Tail pointing down-left
        Positioned(
          left: 12,
          bottom: -8,
          child: CustomPaint(
            size: const Size(20, 15),
            painter: _ChatBubbleTailPainter(_getMoodColor()),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for chat bubble tail (WhatsApp style)
class _ChatBubbleTailPainter extends CustomPainter {
  final Color bubbleColor;

  _ChatBubbleTailPainter(this.bubbleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.fill;

    // Draw triangle tail pointing down-left
    final path = Path();
    path.moveTo(0, 0); // Top left
    path.lineTo(size.width, 0); // Top right
    path.lineTo(0, size.height); // Bottom left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ChatBubbleTailPainter oldDelegate) {
    return oldDelegate.bubbleColor != bubbleColor;
  }
}
