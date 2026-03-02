import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_info.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/responsive.dart';

/// Full-screen weather forecast + AI recommendations screen.
/// Mimics a clean Google-Weather-style layout with a sky-blue gradient,
/// 7-day horizontal forecast row, and a "Generate Recommendations" button.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    // Load fields & weather on first open
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wp = context.read<WeatherProvider>();
      await wp.loadFields();
      if (wp.selectedFieldId != null) {
        await wp.fetchWeather(wp.selectedFieldId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      body: Consumer<WeatherProvider>(
        builder: (context, wp, _) {
          return CustomScrollView(
            slivers: [
              // Sky-blue gradient header with back button
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: const Color(0xFF57A0D3),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Weather & Advice',
                  style: AppTextStyles.h3().copyWith(color: Colors.white),
                ),
                actions: [
                  if (wp.selectedFieldId != null && !wp.isLoading)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () =>
                          wp.fetchWeather(wp.selectedFieldId!),
                    ),
                ],
              ),

              // ── Field selector ──────────────────────────────
              SliverToBoxAdapter(child: _buildFieldSelector(wp)),

              // ── Main content ────────────────────────────────
              if (wp.isLoadingFields)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (wp.fields.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.landscape_outlined,
                              size: 64, color: AppColorPalette.softSlate),
                          const SizedBox(height: 16),
                          Text(
                            'No fields yet',
                            style: AppTextStyles.h3(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a field first to see its weather forecast.',
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.softSlate),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (wp.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF57A0D3)),
                        SizedBox(height: 16),
                        Text('Fetching weather...'),
                      ],
                    ),
                  ),
                )
              else if (wp.error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 64, color: AppColorPalette.alertError),
                          const SizedBox(height: 16),
                          Text('Error', style: AppTextStyles.h3()),
                          const SizedBox(height: 8),
                          Text(
                            wp.error!,
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.softSlate),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => wp.selectedFieldId != null
                                ? wp.fetchWeather(wp.selectedFieldId!)
                                : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (wp.forecast != null) ...[
                // Current weather hero card
                SliverToBoxAdapter(
                    child: _buildCurrentWeatherCard(wp.forecast!)),
                // 7-day forecast row
                SliverToBoxAdapter(
                    child: _buildDailyForecastRow(wp.forecast!)),
                // Weather details grid
                SliverToBoxAdapter(
                    child: _buildWeatherDetails(wp.forecast!)),
                // Generate Recommendations button
                SliverToBoxAdapter(
                    child: _buildRecommendationsButton(wp)),
                // Recommendations result (if loaded)
                if (wp.recommendations != null)
                  SliverToBoxAdapter(
                      child: _buildRecommendationsCard(wp.recommendations!)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FIELD SELECTOR
  // ─────────────────────────────────────────────────────────
  Widget _buildFieldSelector(WeatherProvider wp) {
    if (wp.fields.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: wp.selectedFieldId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: Text('Select a field',
              style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate)),
          items: wp.fields.map((field) {
            return DropdownMenuItem(
              value: field.id,
              child: Row(
                children: [
                  Icon(Icons.landscape, color: AppColorPalette.mistyBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(field.name,
                            style: AppTextStyles.bodyLarge(
                                color: AppColorPalette.charcoalGreen)),
                        if (field.cropType != null)
                          Text(field.cropType!,
                              style: AppTextStyles.caption(
                                  color: AppColorPalette.softSlate)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) wp.selectField(value);
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CURRENT WEATHER HERO CARD  (Google-Weather-style)
  // ─────────────────────────────────────────────────────────
  Widget _buildCurrentWeatherCard(WeatherForecastResponse forecast) {
    final current = forecast.current;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF57A0D3), Color(0xFF87CEEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57A0D3).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location & condition
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forecast.fieldName?.toUpperCase() ?? 'FIELD',
                      style: AppTextStyles.caption(color: Colors.white70)
                          .copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${current.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    current.condition,
                    style: AppTextStyles.bodyLarge(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    current.weatherIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 7-DAY FORECAST ROW
  // ─────────────────────────────────────────────────────────
  Widget _buildDailyForecastRow(WeatherForecastResponse forecast) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6DB3E0), Color(0xFF93D1F0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF57A0D3).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: forecast.daily.map((day) {
          return Expanded(
            child: _buildDayColumn(day),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayColumn(DailyForecast day) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day.dayLabel,
          style: AppTextStyles.caption(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          '${day.tempMax.toStringAsFixed(0)}°',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          day.icon,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          '${day.tempMin.toStringAsFixed(0)}°',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // WEATHER DETAIL METRICS
  // ─────────────────────────────────────────────────────────
  Widget _buildWeatherDetails(WeatherForecastResponse forecast) {
    final c = forecast.current;
    final details = [
      _DetailItem(Icons.water_drop, 'Humidity', '${c.humidity}%'),
      _DetailItem(Icons.air, 'Wind', '${c.windSpeed.toStringAsFixed(1)} km/h'),
      _DetailItem(Icons.umbrella, 'Precipitation', '${c.precipitation} mm'),
      _DetailItem(Icons.wb_sunny_outlined, 'UV Index', '${c.uvIndex}'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: details.map((d) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(d.icon, color: const Color(0xFF57A0D3), size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.label,
                        style: AppTextStyles.caption(
                            color: AppColorPalette.softSlate)),
                    Text(d.value,
                        style: AppTextStyles.bodyLarge(
                                color: AppColorPalette.charcoalGreen)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // GENERATE RECOMMENDATIONS BUTTON
  // ─────────────────────────────────────────────────────────
  Widget _buildRecommendationsButton(WeatherProvider wp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: wp.isLoadingRecs || wp.selectedFieldId == null
                ? null
                : () => wp.fetchRecommendations(wp.selectedFieldId!),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorPalette.mistyBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 3,
            ),
            icon: wp.isLoadingRecs
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome, size: 22),
            label: Text(
              wp.isLoadingRecs
                  ? 'Generating Recommendations...'
                  : 'Generate AI Recommendations',
              style: AppTextStyles.buttonMedium(),
            ),
          ),
          if (wp.recsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                wp.recsError!,
                style: AppTextStyles.caption(color: AppColorPalette.alertError),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // RECOMMENDATIONS RESULT CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildRecommendationsCard(RecommendationResponse recs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.mistyBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome,
                    color: AppColorPalette.mistyBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Text('AI Recommendations',
                  style: AppTextStyles.h3()
                      .copyWith(color: AppColorPalette.charcoalGreen)),
            ],
          ),
          const SizedBox(height: 16),

          // Should Harvest / Should Plant badges
          Row(
            children: [
              _buildBadge(
                label: 'Harvest',
                value: recs.shouldHarvest,
                trueIcon: Icons.check_circle,
                falseIcon: Icons.cancel,
              ),
              const SizedBox(width: 12),
              _buildBadge(
                label: 'Plant',
                value: recs.shouldPlant,
                trueIcon: Icons.check_circle,
                falseIcon: Icons.cancel,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary
          Text(recs.summary,
              style: AppTextStyles.bodyMedium(
                  color: AppColorPalette.charcoalGreen)),
          const SizedBox(height: 16),

          // Recommendations list
          if (recs.recommendations.isNotEmpty) ...[
            Text('Recommendations',
                style: AppTextStyles.bodyLarge(
                        color: AppColorPalette.charcoalGreen)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...recs.recommendations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF2ECC71), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(r,
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.charcoalGreen)),
                      ),
                    ],
                  ),
                )),
          ],

          // Risk alerts
          if (recs.riskAlerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Risk Alerts',
                style: AppTextStyles.bodyLarge(color: AppColorPalette.alertError)
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...recs.riskAlerts.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColorPalette.alertError.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColorPalette.alertError.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColorPalette.alertError, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(a,
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.charcoalGreen)),
                      ),
                    ],
                  ),
                )),
          ],

          // Irrigation advice
          if (recs.irrigationAdvice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF57A0D3).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFF57A0D3).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.water_drop,
                      color: Color(0xFF57A0D3), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Irrigation',
                            style: AppTextStyles.bodyLarge(
                                    color: const Color(0xFF57A0D3))
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(recs.irrigationAdvice,
                            style: AppTextStyles.bodyMedium(
                                color: AppColorPalette.charcoalGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required bool value,
    required IconData trueIcon,
    required IconData falseIcon,
  }) {
    final color = value ? AppColorPalette.success : AppColorPalette.softSlate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(value ? trueIcon : falseIcon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            '$label: ${value ? "Yes" : "No"}',
            style: AppTextStyles.bodyMedium(color: color)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Internal helper for detail items
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}
