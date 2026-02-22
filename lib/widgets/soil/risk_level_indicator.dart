import 'package:flutter/material.dart';
import '../../models/ai_prediction.dart';

/// Visual indicator showing risk level as a progress bar
/// Color transitions from green → yellow → red
class RiskLevelIndicator extends StatelessWidget {
  final double score; // 0-100
  final RiskLevel riskLevel;

  const RiskLevelIndicator({
    super.key,
    required this.score,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Low', 0xFF4CAF50),
            _buildLabel('Medium', 0xFFFF9800),
            _buildLabel('High', 0xFFF44336),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (score < 40) {
      // Green
      return const Color(0xFF4CAF50);
    } else if (score < 70) {
      // Orange (transition from green to red)
      return const Color(0xFFFF9800);
    } else {
      // Red
      return const Color(0xFFF44336);
    }
  }

  Widget _buildLabel(String text, int color) {
    final bool isActive = (text == 'Low' && score < 40) ||
        (text == 'Medium' && score >= 40 && score <= 70) ||
        (text == 'High' && score > 70);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Color(color) : Colors.grey[400],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Color(color) : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
