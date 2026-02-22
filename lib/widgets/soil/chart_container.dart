import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Reusable container widget for charts
/// Provides consistent styling and layout for all chart widgets
class ChartContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final Widget? legend;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final VoidCallback? onInfoTap;

  const ChartContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.chart,
    this.legend,
    this.padding,
    this.height,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withValues(alpha: 0.08),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h4(),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.caption(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onInfoTap != null)
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: AppColorPalette.softSlate,
                    size: 20,
                  ),
                  onPressed: onInfoTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            height: height ?? 200,
            child: chart,
          ),

          // Legend (optional)
          if (legend != null) ...[
            const SizedBox(height: 16),
            legend!,
          ],
        ],
      ),
    );
  }
}

/// Legend widget for displaying chart indicators
class ChartLegend extends StatelessWidget {
  final List<ChartLegendItem> items;
  final Axis direction;
  final MainAxisAlignment alignment;

  const ChartLegend({
    super.key,
    required this.items,
    this.direction = Axis.horizontal,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: 24,
        runSpacing: 8,
        children: items,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < items.length - 1 ? 8 : 0,
                ),
                child: entry.value,
              ))
          .toList(),
    );
  }
}

/// Individual legend item
class ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const ChartLegendItem({
    super.key,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption(
            color: AppColorPalette.darkGrey,
          ),
        ),
      ],
    );
  }
}

