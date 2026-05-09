import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/soil_intelligence.dart';
import '../../providers/parcel_provider.dart';
import '../../services/soil_intelligence_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../l10n/l10n_extensions.dart';

class SoilAlertNotificationsScreen extends StatefulWidget {
  const SoilAlertNotificationsScreen({super.key});

  @override
  State<SoilAlertNotificationsScreen> createState() =>
      _SoilAlertNotificationsScreenState();
}

class _SoilAlertNotificationsScreenState
    extends State<SoilAlertNotificationsScreen> {
  final SoilIntelligenceService _service = SoilIntelligenceService();

  List<SoilWeatherAlert> _alerts = [];
  Map<String, String> _parcelNameById = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parcelProvider = context.read<ParcelProvider>();
      if (parcelProvider.parcels.isEmpty) {
        await parcelProvider.fetchParcels();
      }

      final parcels = parcelProvider.parcels;
      _parcelNameById = {
        for (final parcel in parcels) parcel.id: parcel.location,
      };

      if (parcels.isEmpty) {
        if (!mounted) return;
        setState(() {
          _alerts = [];
          _isLoading = false;
        });
        return;
      }

      final perParcelAlerts = await Future.wait(
        parcels.map(
          (parcel) async {
            try {
              return await _service.getActiveAlerts(parcel.id);
            } catch (_) {
              return <SoilWeatherAlert>[];
            }
          },
        ),
      );

      final allAlerts = perParcelAlerts.expand((items) => items).toList();
      final deduped = <String, SoilWeatherAlert>{
        for (final alert in allAlerts) alert.id: alert,
      };

      final sorted = deduped.values.toList()
        ..sort((a, b) {
          final severityDiff = _severityScore(b.severity) - _severityScore(a.severity);
          if (severityDiff != 0) {
            return severityDiff;
          }
          return b.triggeredAt.compareTo(a.triggeredAt);
        });

      if (!mounted) return;
      setState(() {
        _alerts = sorted;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(SoilWeatherAlert alert) async {
    try {
      await _service.markAlertAsRead(alert.id);
      if (!mounted) return;

      setState(() {
        _alerts.removeWhere((item) => item.id == alert.id);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.error}: $error'),
          backgroundColor: AppColorPalette.alertError,
        ),
      );
    }
  }

  int _severityScore(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 4;
      case 'HIGH':
        return 3;
      case 'MEDIUM':
        return 2;
      default:
        return 1;
    }
  }

  String _parcelLabel(String parcelId) {
    final value = _parcelNameById[parcelId];
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
    return 'Parcel $parcelId';
  }

  String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.soilAlertNotifications),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAlerts),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAlerts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.alertError,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : _alerts.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Icon(
                            Icons.notifications_none,
                            size: 56,
                            color: AppColorPalette.softSlate,
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              context.l10n.noData,
                              style: AppTextStyles.bodyLarge(color: AppColorPalette.softSlate),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: alert.backgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: alert.borderColor, width: 1.3),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${alert.alertIcon} ${alert.type.replaceAll('_', ' ')}',
                                        style: AppTextStyles.bodyMedium().copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: alert.borderColor.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        alert.severity.toUpperCase(),
                                        style: AppTextStyles.caption(
                                          color: alert.borderColor,
                                        ).copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _parcelLabel(alert.parcelId),
                                  style: AppTextStyles.bodySmall(
                                    color: AppColorPalette.charcoalGreen,
                                  ).copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(alert.message, style: AppTextStyles.bodySmall()),
                                if (alert.action.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Action: ${alert.action}',
                                    style: AppTextStyles.bodySmall().copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _relativeTime(alert.triggeredAt),
                                        style: AppTextStyles.caption(
                                          color: AppColorPalette.softSlate,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _markAsRead(alert),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: Text(context.l10n.markRead),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
