import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../models/ai_prediction.dart';

/// Widget to display AI-generated advice and recommendations
/// Enhanced version with detailed farmer-friendly explanations
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
                Expanded(
                  child: Text(
                    'Detailed Analysis & Recommendations',
                    style: AppTextStyles.h4(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // What this means section
            _buildExplanationSection(),

            const SizedBox(height: 20),

            // Current conditions with visual indicators
            _buildDetailedConditions(),

            const SizedBox(height: 20),

            // Step-by-step recommendations
            _buildDetailedRecommendations(),

            const SizedBox(height: 20),

            // Expected outcomes
            _buildExpectedOutcomes(),
          ],
        ),
      ),
    );
  }

  /// Build explanation section - what this means for the farmer
  Widget _buildExplanationSection() {
    String explanation;
    IconData icon;
    
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        icon = Icons.check_circle_outline;
        explanation = 'Your soil conditions are in excellent shape! The combination of moisture, temperature, pH levels, and sunlight indicates a healthy growing environment. Your crops are thriving and there\'s minimal risk of plant stress or wilting. Keep up your current maintenance routine.';
        break;
      case RiskLevel.medium:
        icon = Icons.warning_amber;
        explanation = 'Your soil is showing some warning signs that need attention. While not critical yet, certain conditions (like moisture levels or temperature) are approaching ranges that could stress your plants. Taking action now will prevent problems and keep your crops healthy.';
        break;
      case RiskLevel.high:
        icon = Icons.error_outline;
        explanation = 'URGENT: Your soil conditions indicate high stress on your plants. One or more factors (moisture, temperature, pH, or sunlight) are at levels that can cause serious damage to your crops. Immediate action is required to prevent wilting, reduced yields, or crop loss.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(prediction.riskLevel.color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(prediction.riskLevel.color).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Color(prediction.riskLevel.color),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'What This Means For Your Crops',
                  style: AppTextStyles.h4(
                    color: Color(prediction.riskLevel.color),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.charcoalGreen,
            ).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Build detailed conditions with visual progress bars
  Widget _buildDetailedConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.wheatWarmClay.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: AppColorPalette.charcoalGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Soil Measurements',
                  style: AppTextStyles.h4(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Soil Moisture
          _buildMetricRow(
            label: 'Soil Moisture',
            value: '${prediction.measurementData.soilMoisture.toStringAsFixed(0)}%',
            icon: Icons.water_drop,
            progress: prediction.measurementData.soilMoisture / 100,
            optimalRange: '20-50%',
            status: _getMoistureDetailedStatus(),
            explanation: _getMoistureExplanation(),
          ),
          
          const SizedBox(height: 16),
          
          // Temperature
          _buildMetricRow(
            label: 'Soil Temperature',
            value: '${prediction.measurementData.temperature.toStringAsFixed(1)}°C',
            icon: Icons.thermostat,
            progress: _normalizeTemperature(prediction.measurementData.temperature),
            optimalRange: '15-30°C',
            status: _getTemperatureDetailedStatus(),
            explanation: _getTemperatureExplanation(),
          ),
          
          const SizedBox(height: 16),
          
          // pH Level
          _buildMetricRow(
            label: 'Soil pH',
            value: prediction.measurementData.ph.toStringAsFixed(1),
            icon: Icons.science,
            progress: _normalizePh(prediction.measurementData.ph),
            optimalRange: '6.0-7.5',
            status: _getPhDetailedStatus(),
            explanation: _getPhExplanation(),
          ),
          
          const SizedBox(height: 16),
          
          // Sunlight
          _buildMetricRow(
            label: 'Sunlight Exposure',
            value: '${prediction.measurementData.sunlight.toStringAsFixed(0)}%',
            icon: Icons.wb_sunny,
            progress: prediction.measurementData.sunlight / 100,
            optimalRange: '60-100%',
            status: _getSunlightDetailedStatus(),
            explanation: _getSunlightExplanation(),
          ),
        ],
      ),
    );
  }

  /// Build a metric row with progress bar and explanation
  Widget _buildMetricRow({
    required String label,
    required String value,
    required IconData icon,
    required double progress,
    required String optimalRange,
    required String status,
    required String explanation,
  }) {
    final isOptimal = status.toLowerCase().contains('optimal') || 
                      status.toLowerCase().contains('good');
    final statusColor = isOptimal 
        ? AppColorPalette.success 
        : (status.toLowerCase().contains('critical') || status.toLowerCase().contains('poor'))
            ? AppColorPalette.alertError
            : AppColorPalette.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColorPalette.charcoalGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.charcoalGreen,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.charcoalGreen,
              ).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColorPalette.lightGrey,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 8,
          ),
        ),
        
        const SizedBox(height: 6),
        
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: AppTextStyles.caption(
                  color: statusColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Optimal: $optimalRange',
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        Text(
          explanation,
          style: AppTextStyles.caption(
            color: AppColorPalette.softSlate,
          ).copyWith(height: 1.4),
        ),
      ],
    );
  }

  /// Build detailed step-by-step recommendations
  Widget _buildDetailedRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.checklist,
              size: 20,
              color: Color(prediction.riskLevel.color),
            ),
            const SizedBox(width: 8),
            Text(
              'Action Plan',
              style: AppTextStyles.h4(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        ..._getDetailedRecommendations().asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRecommendationItem(
              number: index + 1,
              title: rec['title'] as String,
              description: rec['description'] as String,
              priority: rec['priority'] as String,
            ),
          );
        }),
      ],
    );
  }

  /// Build a single recommendation item
  Widget _buildRecommendationItem({
    required int number,
    required String title,
    required String description,
    required String priority,
  }) {
    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'urgent':
        priorityColor = AppColorPalette.alertError;
        break;
      case 'soon':
        priorityColor = AppColorPalette.warning;
        break;
      default:
        priorityColor = AppColorPalette.success;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.bodyMedium(
                          color: AppColorPalette.charcoalGreen,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        priority,
                        style: AppTextStyles.caption(
                          color: priorityColor,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption(
                    color: AppColorPalette.softSlate,
                  ).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build expected outcomes section
  Widget _buildExpectedOutcomes() {
    List<String> outcomes;
    
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        outcomes = [
          'Your crops will continue to grow healthy and strong',
          'Maximum yield potential maintained',
          'Low risk of disease or pest problems',
          'Efficient water and nutrient usage',
        ];
        break;
      case RiskLevel.medium:
        outcomes = [
          'Follow recommendations to prevent stress',
          'Return to optimal conditions within 1-2 days',
          'Avoid potential yield reduction (5-15%)',
          'Prevent escalation to high-risk conditions',
        ];
        break;
      case RiskLevel.high:
        outcomes = [
          'Immediate action prevents crop damage',
          'Recovery within 2-4 days with proper care',
          'Without action: possible 30-50% yield loss',
          'Risk of permanent plant damage if delayed',
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(prediction.riskLevel.color).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 18,
                color: Color(prediction.riskLevel.color),
              ),
              const SizedBox(width: 8),
              Text(
                'Expected Results',
                style: AppTextStyles.h4(
                  color: Color(prediction.riskLevel.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...outcomes.map((outcome) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: AppTextStyles.bodyMedium(
                    color: Color(prediction.riskLevel.color),
                  ),
                ),
                Expanded(
                  child: Text(
                    outcome,
                    style: AppTextStyles.bodySmall(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // Helper methods for status and explanations
  
  String _getMoistureDetailedStatus() {
    final moisture = prediction.measurementData.soilMoisture;
    if (moisture < 15) return 'Critical - Too Dry';
    if (moisture < 20) return 'Low';
    if (moisture > 80) return 'Too Wet';
    if (moisture > 60) return 'High';
    return 'Optimal';
  }

  String _getMoistureExplanation() {
    final moisture = prediction.measurementData.soilMoisture;
    if (moisture < 15) return 'Dangerously dry. Plants are likely wilting. Water immediately and deeply.';
    if (moisture < 20) return 'Below optimal. Plants may show stress. Increase watering schedule.';
    if (moisture > 80) return 'Too much water can cause root rot. Reduce watering and improve drainage.';
    if (moisture > 60) return 'Slightly high but manageable. Reduce watering frequency.';
    return 'Perfect moisture level for healthy plant growth and root development.';
  }

  String _getTemperatureDetailedStatus() {
    final temp = prediction.measurementData.temperature;
    if (temp < 10) return 'Too Cold';
    if (temp < 15) return 'Cool';
    if (temp > 35) return 'Critical - Too Hot';
    if (temp > 30) return 'Hot';
    return 'Optimal';
  }

  String _getTemperatureExplanation() {
    final temp = prediction.measurementData.temperature;
    if (temp < 10) return 'Too cold for most crops. Consider protection or wait for warmer weather.';
    if (temp < 15) return 'Slow growth expected. Most crops prefer warmer soil.';
    if (temp > 35) return 'Extreme heat stress. Provide shade and increase watering immediately.';
    if (temp > 30) return 'Heat stress possible. Consider shade cloth during peak sun hours.';
    return 'Ideal temperature range for strong root growth and nutrient absorption.';
  }

  String _getPhDetailedStatus() {
    final ph = prediction.measurementData.ph;
    if (ph < 5.5) return 'Too Acidic';
    if (ph < 6.0) return 'Slightly Acidic';
    if (ph > 8.0) return 'Too Alkaline';
    if (ph > 7.5) return 'Slightly Alkaline';
    return 'Optimal';
  }

  String _getPhExplanation() {
    final ph = prediction.measurementData.ph;
    if (ph < 5.5) return 'Very acidic soil limits nutrient availability. Add lime to raise pH.';
    if (ph < 6.0) return 'Slightly low. Most crops prefer neutral pH. Consider adding lime.';
    if (ph > 8.0) return 'Too alkaline. Add sulfur or organic matter to lower pH.';
    if (ph > 7.5) return 'Slightly high. Some nutrients may be less available.';
    return 'Perfect pH range. Nutrients are readily available to plants.';
  }

  String _getSunlightDetailedStatus() {
    final sunlight = prediction.measurementData.sunlight;
    if (sunlight < 40) return 'Too Low';
    if (sunlight < 60) return 'Moderate';
    if (sunlight > 95) return 'Intense';
    return 'Good';
  }

  String _getSunlightExplanation() {
    final sunlight = prediction.measurementData.sunlight;
    if (sunlight < 40) return 'Insufficient light for optimal growth. Prune shade sources if possible.';
    if (sunlight < 60) return 'Adequate for many crops but not ideal for sun-loving plants.';
    if (sunlight > 95) return 'Very intense. May need shade during hottest hours to prevent burning.';
    return 'Excellent sunlight exposure for photosynthesis and growth.';
  }

  double _normalizeTemperature(double temp) {
    // Normalize to 0-1 range where 15-30°C is optimal
    if (temp < 15) return temp / 30;
    if (temp > 30) return 1.0 - ((temp - 30) / 20).clamp(0.0, 0.5);
    return 0.5 + ((temp - 15) / 30);
  }

  double _normalizePh(double ph) {
    // Normalize to 0-1 range where 6.0-7.5 is optimal
    if (ph < 6.0) return ph / 12;
    if (ph > 7.5) return 1.0 - ((ph - 7.5) / 7).clamp(0.0, 0.5);
    return 0.5 + ((ph - 6.0) / 3);
  }

  List<Map<String, String>> _getDetailedRecommendations() {
    switch (prediction.riskLevel) {
      case RiskLevel.low:
        return [
          {
            'title': 'Continue Regular Maintenance',
            'description': 'Your current watering schedule and soil management are working perfectly. Keep doing what you\'re doing!',
            'priority': 'Routine',
          },
          {
            'title': 'Monitor Weekly',
            'description': 'Check soil conditions once a week to catch any changes early. Look for signs of dryness or excess moisture.',
            'priority': 'Routine',
          },
          {
            'title': 'Maintain Fertilization',
            'description': 'Continue your regular fertilization schedule to support healthy growth.',
            'priority': 'Routine',
          },
        ];
      
      case RiskLevel.medium:
        final recommendations = <Map<String, String>>[];
        
        if (prediction.measurementData.soilMoisture < 0.25) {
          recommendations.add({
            'title': 'Increase Watering',
            'description': 'Water thoroughly within the next 12-24 hours. Add 20-30% more water than usual and water deeper to reach roots.',
            'priority': 'Soon',
          });
        }
        
        if (prediction.measurementData.temperature > 28) {
          recommendations.add({
            'title': 'Provide Shade',
            'description': 'Use shade cloth or natural shade during peak afternoon sun (12pm-4pm) to reduce heat stress.',
            'priority': 'Soon',
          });
        }
        
        if (prediction.measurementData.ph < 6.0 || prediction.measurementData.ph > 7.5) {
          recommendations.add({
            'title': 'Adjust Soil pH',
            'description': prediction.measurementData.ph < 6.0 
                ? 'Add agricultural lime (1-2 kg per 10m²) to raise pH. Re-test in 2 weeks.'
                : 'Add sulfur or peat moss to lower pH. Mix into top 10cm of soil.',
            'priority': 'Soon',
          });
        }
        
        recommendations.add({
          'title': 'Increase Monitoring',
          'description': 'Check soil conditions every 2-3 days until levels return to optimal range.',
          'priority': 'Soon',
        });
        
        return recommendations;
      
      case RiskLevel.high:
        final recommendations = <Map<String, String>>[];
        
        if (prediction.measurementData.soilMoisture < 0.20) {
          recommendations.add({
            'title': 'Emergency Watering',
            'description': 'Water immediately! Apply 2-3 times your normal amount, slowly over 30-60 minutes. Water early morning or evening. Check if soil is moist at 15cm depth.',
            'priority': 'Urgent',
          });
        }
        
        if (prediction.measurementData.temperature > 32) {
          recommendations.add({
            'title': 'Immediate Cooling',
            'description': 'Install shade cloth NOW or use temporary shade (umbrellas, tarps). Mist leaves lightly in morning (not during hot sun). Ensure good air circulation.',
            'priority': 'Urgent',
          });
        }
        
        if (prediction.measurementData.ph < 5.8|| prediction.measurementData.ph > 7.8) {
          recommendations.add({
            'title': 'Emergency pH Correction',
            'description': 'Contact agricultural extension service or local expert. pH is critically out of range and needs professional guidance for rapid correction.',
            'priority': 'Urgent',
          });
        }
        
        recommendations.add({
          'title': 'Daily Monitoring',
          'description': 'Check plants twice daily (morning and evening) for next 3-5 days. Look for wilting, leaf curling, or discoloration.',
          'priority': 'Urgent',
        });
        
        recommendations.add({
          'title': 'Consider Expert Help',
          'description': 'If plants don\'t improve within 48 hours with your actions, contact an agricultural extension agent or local farming expert for personalized advice.',
          'priority': 'Soon',
        });
        
        return recommendations;
    }
  }
}
