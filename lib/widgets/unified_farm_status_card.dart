import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

/// Unified Farm Status Card combining plant chat and mood score
class UnifiedFarmStatusCard extends StatefulWidget {
  final int farmScore;
  final String mood; // 'happy', 'good', 'stressed', 'critical'
  final String emoji;
  final String message;

  const UnifiedFarmStatusCard({
    super.key,
    required this.farmScore,
    required this.mood,
    required this.emoji,
    required this.message,
  });

  @override
  State<UnifiedFarmStatusCard> createState() => _UnifiedFarmStatusCardState();
}

class _UnifiedFarmStatusCardState extends State<UnifiedFarmStatusCard>
    with TickerProviderStateMixin {
  late AnimationController _emojiController;
  late AnimationController _plantController;
  late Animation<double> _emojiScaleAnimation;
  late Animation<double> _plantBounceAnimation;

  @override
  void initState() {
    super.initState();

    // Emoji pulsing animation (1 second loop)
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _emojiScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _emojiController, curve: Curves.easeInOutQuad),
    );

    // Plant bouncing animation (1.2 second loop)
    _plantController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _plantBounceAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _plantController, curve: Curves.easeInOutQuad),
    );
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _plantController.dispose();
    super.dispose();
  }

  Color _getMoodColor() {
    switch (widget.mood.toLowerCase()) {
      case 'happy':
        return const Color(0xFF10B981);
      case 'good':
        return const Color(0xFF3B82F6);
      case 'stressed':
        return const Color(0xFFF59E0B);
      case 'critical':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getBackgroundColor() {
    final baseColor = _getMoodColor();
    return baseColor.withValues(alpha: 0.08);
  }

  double _getBounceOffset() {
    if (_plantBounceAnimation.value < 0.5) {
      return -(_plantBounceAnimation.value * 2) * 6;
    } else {
      return -(2 - _plantBounceAnimation.value * 2) * 6;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getMoodColor().withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getMoodColor().withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Plant avatar + Score
            Row(
              children: [
                // Plant avatar with bounce
                AnimatedBuilder(
                  animation: _plantBounceAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _getBounceOffset()),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _getBackgroundColor(),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _getMoodColor().withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🌱',
                            style: TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Score section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Farm Status',
                            style: AppTextStyles.caption(
                              color: AppColorPalette.softSlate,
                            ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(width: 4),
                          // Live indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getMoodColor().withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _getMoodColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'LIVE',
                                  style: AppTextStyles.caption(
                                    color: _getMoodColor(),
                                  ).copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Real-time soil health & farm conditions',
                        style: AppTextStyles.bodySmall(
                          color: AppColorPalette.softSlate,
                        ).copyWith(fontSize: 12, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ScaleTransition(
                            scale: _emojiScaleAnimation,
                            child: Text(
                              widget.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.farmScore}/100',
                                style: AppTextStyles.h2(color: _getMoodColor())
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                widget.mood.toUpperCase(),
                                style: AppTextStyles.bodySmall(
                                  color: _getMoodColor(),
                                ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.farmScore / 100,
                minHeight: 8,
                backgroundColor: _getMoodColor().withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(_getMoodColor()),
              ),
            ),
            const SizedBox(height: 16),
            // Plant message bubble
            Container(
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getMoodColor().withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.charcoalGreen,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
