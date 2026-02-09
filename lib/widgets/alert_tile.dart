import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../models/alert_item.dart';

/// Reusable tile widget for displaying alerts
/// Shows alert information with severity-based styling
class AlertTile extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback? onTap;
  final bool showTimestamp;
  final bool compact;

  const AlertTile({
    super.key,
    required this.alert,
    this.onTap,
    this.showTimestamp = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(compact ? 12.0 : 16.0),
        decoration: BoxDecoration(
          color: _getSeverityBackgroundColor().withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: _getSeverityColor().withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Icon
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _getSeverityBackgroundColor(),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(
                _getSeverityIcon(),
                size: compact ? 18.0 : 20.0,
                color: _getSeverityColor(),
              ),
            ),
            const SizedBox(width: 12.0),

            // Alert Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (!compact)
                    Text(
                      alert.title,
                      style: AppTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColorPalette.charcoalGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!compact) const SizedBox(height: 4.0),

                  // Description
                  Text(
                    alert.description,
                    style: compact
                        ? AppTextStyles.bodySmall(
                            color: AppColorPalette.charcoalGreen,
                          )
                        : AppTextStyles.bodySmall(
                            color: AppColorPalette.softSlate,
                          ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Timestamp
                  if (showTimestamp) ...[
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColorPalette.softSlate,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          alert.timeAgo,
                          style: AppTextStyles.caption(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Indicator
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColorPalette.softSlate,
              ),
          ],
        ),
      ),
    );
  }

  /// Get icon based on alert severity
  IconData _getSeverityIcon() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Icons.error;
      case AlertSeverity.warning:
        return Icons.warning;
      case AlertSeverity.info:
        return Icons.info;
    }
  }

  /// Get color based on alert severity
  Color _getSeverityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColorPalette.alertError;
      case AlertSeverity.warning:
        return AppColorPalette.warning;
      case AlertSeverity.info:
        return AppColorPalette.info;
    }
  }

  /// Get background color based on alert severity
  Color _getSeverityBackgroundColor() {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColorPalette.alertError.withOpacity(0.15);
      case AlertSeverity.warning:
        return AppColorPalette.warning.withOpacity(0.15);
      case AlertSeverity.info:
        return AppColorPalette.info.withOpacity(0.15);
    }
  }

  /// Factory constructor for compact display
  factory AlertTile.compact({
    required AlertItem alert,
    VoidCallback? onTap,
  }) {
    return AlertTile(
      alert: alert,
      onTap: onTap,
      showTimestamp: false,
      compact: true,
    );
  }
}
