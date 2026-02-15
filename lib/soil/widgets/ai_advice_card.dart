import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../models/ai_prediction.dart';

/// Widget to display AI-generated advice and recommendations
/// Color-coded based on risk level
class AiAdviceCard extends StatelessWidget {
  final AiPrediction prediction;

  const AiAdviceCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Color(prediction.riskLevel.color),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: AppTextStyles.h4(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // Recommendations list
            ...prediction.recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji or bullet
                    Text(
                      _getEmoji(recommendation),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    // Recommendation text
                    Expanded(
                      child: Text(
                        _cleanRecommendation(recommendation),
                        style: AppTextStyles.bodyMedium(),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Divider
            if (prediction.riskLevel != RiskLevel.low) ...[
              const Divider(height: 24),
              
              // Additional context
              _buildContextInfo(),
            ],
          ],
        ),
      ),
    );
  }

  /// Get emoji from recommendation text
  String _getEmoji(String text) {
    if (text.startsWith('✅')) return '✅';
    if (text.startsWith('⚠️')) return '⚠️';
    if (text.startsWith('🚨')) return '🚨';
    if (text.startsWith('💧')) return '💧';
    if (text.startsWith('🌡️')) return '🌡️';
    if (text.startsWith('🧪')) return '🧪';
    if (text.startsWith('📊')) return '📊';
    if (text.startsWith('📞')) return '📞';
    if (text.startsWith('💦')) return '💦';
    return '•';
  }

  /// Remove emoji from text
  String _cleanRecommendation(String text) {
    return text.replaceFirst(RegExp(r'^[✅⚠️🚨💧🌡️🧪📊📞💦]\s*'), '');
  }

  /// Build context information
  Widget _buildContextInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(prediction.riskLevel.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Color(prediction.riskLevel.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Current Conditions',
                style: AppTextStyles.h4(
                  color: Color(prediction.riskLevel.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildConditionRow(
            'pH Level',
            prediction.measurementData.ph.toStringAsFixed(1),
            _getPhStatus(prediction.measurementData.ph),
          ),
          _buildConditionRow(
            'Soil Moisture',
            '${(prediction.measurementData.soilMoisture * 100).toStringAsFixed(0)}%',
            _getMoistureStatus(prediction.measurementData.soilMoisture),
          ),
          _buildConditionRow(
            'Temperature',
            '${prediction.measurementData.temperature.toStringAsFixed(1)}°C',
            _getTemperatureStatus(prediction.measurementData.temperature),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRow(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.charcoalGreen,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Text(
                '($status)',
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPhStatus(double ph) {
    if (ph < 6.0) return 'Acidic';
    if (ph > 7.5) return 'Alkaline';
    return 'Neutral';
  }

  String _getMoistureStatus(double moisture) {
    if (moisture < 0.20) return 'Dry';
    if (moisture > 0.50) return 'Wet';
    return 'Optimal';
  }

  String _getTemperatureStatus(double temp) {
    if (temp < 15) return 'Cold';
    if (temp > 30) return 'Hot';
    return 'Optimal';
  }
}
