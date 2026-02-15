import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../models/ai_prediction.dart';
import 'risk_level_indicator.dart';

/// Widget to display AI prediction results
/// Shows wilting score, risk level, and visual indicator
class AiPredictionCard extends StatelessWidget {
  final AiPrediction prediction;
  final VoidCallback? onRefresh;

  const AiPredictionCard({
    super.key,
    required this.prediction,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(prediction.riskLevel.color).withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(prediction.riskLevel.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: Color(prediction.riskLevel.color),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Wilting Risk Analysis',
                          style: AppTextStyles.h4(),
                        ),
                        Text(
                          'Machine Learning Prediction',
                          style: AppTextStyles.caption(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                      tooltip: 'Refresh prediction',
                    ),
                ],
              ),
              
              const SizedBox(height: 24),

              // Risk Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    prediction.wiltingScore.toStringAsFixed(1),
                    style: AppTextStyles.h1().copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(prediction.riskLevel.color),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      '/ 100',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Risk Level Indicator
              RiskLevelIndicator(
                score: prediction.wiltingScore,
                riskLevel: prediction.riskLevel,
              ),

              const SizedBox(height: 20),

              // Risk Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(prediction.riskLevel.color),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prediction.riskLevel.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Risk Level: ${prediction.riskLevel.displayName.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Priority
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorPalette.wheatWarmClay.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(prediction.riskLevel.color).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getPriorityIcon(),
                      color: Color(prediction.riskLevel.color),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prediction.actionPriority,
                        style: AppTextStyles.bodyMedium(
                          color: AppColorPalette.charcoalGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Measurement timestamp
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColorPalette.softSlate,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Measured: ${_formatDate(prediction.measurementData.measuredAt)}',
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPriorityIcon() {
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
