import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class FarmMoodCard extends StatefulWidget {
  final int farmScore;
  final String mood;
  final String emoji;
  final String message;

  const FarmMoodCard({
    super.key,
    required this.farmScore,
    required this.mood,
    required this.emoji,
    required this.message,
  });

  @override
  State<FarmMoodCard> createState() => _FarmMoodCardState();
}

class _FarmMoodCardState extends State<FarmMoodCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getMoodColor() {
    if (widget.farmScore >= 80) {
      return const Color(0xFF10B981); // Happy - Green
    } else if (widget.farmScore >= 60) {
      return const Color(0xFF3B82F6); // Good - Blue
    } else if (widget.farmScore >= 40) {
      return const Color(0xFFF59E0B); // Stressed - Orange
    } else {
      return const Color(0xFFEF4444); // Critical - Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodColor.withValues(alpha: 0.05),
            moodColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: moodColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated Emoji
            ScaleTransition(
              scale: _scaleAnimation,
              child: Text(
                widget.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
            const SizedBox(height: 16),

            // Farm Score with Linear Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.farmScore}',
                  style: AppTextStyles.h1(color: moodColor),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ 100',
                  style:
                      AppTextStyles.bodyLarge(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.farmScore / 100,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(moodColor),
              ),
            ),
            const SizedBox(height: 16),

            // Mood Label
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: moodColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.mood.toUpperCase(),
                style: AppTextStyles.caption(color: moodColor).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Funny Message
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(color: Colors.grey.shade700)
                  .copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            // Motivational tip based on mood
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMoodIcon(),
                    color: moodColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTip(),
                      style: AppTextStyles.bodySmall(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon() {
    if (widget.farmScore >= 80) {
      return Icons.favorite; // Happy
    } else if (widget.farmScore >= 60) {
      return Icons.thumb_up; // Good
    } else if (widget.farmScore >= 40) {
      return Icons.info; // Stressed
    } else {
      return Icons.warning; // Critical
    }
  }

  String _getTip() {
    if (widget.farmScore >= 80) {
      return 'Keep up the excellent work! Your farm is thriving.';
    } else if (widget.farmScore >= 60) {
      return 'Good progress! Small improvements can boost your score.';
    } else if (widget.farmScore >= 40) {
      return 'Your farm needs attention. Check soil and water levels.';
    } else {
      return 'Critical situation. Take immediate action to save your crops!';
    }
  }
}
