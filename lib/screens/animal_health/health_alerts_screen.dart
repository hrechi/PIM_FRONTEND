import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/animal_health_provider.dart';
import '../../models/animal_health_models.dart';
import '../../utils/constants.dart';

class HealthAlertsScreen extends StatefulWidget {
  const HealthAlertsScreen({super.key});

  @override
  State<HealthAlertsScreen> createState() => _HealthAlertsScreenState();
}

class _HealthAlertsScreenState extends State<HealthAlertsScreen> {
  String _filter = 'all'; // 'all' | 'critical' | 'medium'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimalHealthProvider>().loadAlerts(limit: 50);
    });
  }

  // ── Helpers ──────────────────────────────────────────────

  Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF16A34A);
    }
  }

  Color _levelBg(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFEF2F2);
      case 'medium':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF0FDF4);
    }
  }

  IconData _levelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Symbols.error;
      case 'medium':
        return Symbols.warning;
      default:
        return Symbols.check_circle;
    }
  }

  String _levelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return 'CRITIQUE';
      case 'medium':
        return 'MODÉRÉ';
      default:
        return 'OK';
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'hier';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  List<HealthAlert> _filtered(List<HealthAlert> all) {
    if (_filter == 'all') return all;
    return all.where((a) => a.alertLevel.toLowerCase() == _filter).toList();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alertes Santé',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh, color: Color(0xFF64748B)),
            onPressed: () =>
                context.read<AnimalHealthProvider>().loadAlerts(limit: 50),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'id': 'all', 'label': 'Toutes'},
      {'id': 'critical', 'label': 'Critiques'},
      {'id': 'medium', 'label': 'Modérées'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f['id'];
          final color = f['id'] == 'critical'
              ? const Color(0xFFDC2626)
              : f['id'] == 'medium'
                  ? const Color(0xFFD97706)
                  : AppColors.mistBlue;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? color : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<AnimalHealthProvider>(
      builder: (context, provider, _) {
        if (provider.alertsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.alertsError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.error, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 12),
                  Text(
                    provider.alertsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => provider.loadAlerts(limit: 50),
                    icon: const Icon(Symbols.refresh, size: 16),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mistBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final alerts = _filtered(provider.alerts);

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Symbols.health_and_safety,
                  size: 64,
                  color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  _filter == 'all'
                      ? 'Aucune alerte santé'
                      : 'Aucune alerte ${_filter == 'critical' ? 'critique' : 'modérée'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tous vos animaux sont en bonne santé 🐄',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          );
        }

        // Summary banner
        final criticalCount =
            provider.alerts.where((a) => a.alertLevel == 'critical').length;
        final mediumCount =
            provider.alerts.where((a) => a.alertLevel == 'medium').length;

        return RefreshIndicator(
          onRefresh: () => provider.loadAlerts(limit: 50),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              _buildSummaryCard(criticalCount, mediumCount),
              const SizedBox(height: 16),

              // Alert list
              ...alerts.map((alert) => _buildAlertCard(alert)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(int critical, int medium) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Symbols.monitor_heart, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RÉSUMÉ DES ALERTES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${critical + medium} alerte${critical + medium > 1 ? 's' : ''} active${critical + medium > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (critical > 0)
            _summaryBadge('$critical critique${critical > 1 ? 's' : ''}',
                const Color(0xFFDC2626)),
          if (critical > 0 && medium > 0) const SizedBox(width: 8),
          if (medium > 0)
            _summaryBadge('$medium modéré${medium > 1 ? 's' : ''}',
                const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAlertCard(HealthAlert alert) {
    final color = _levelColor(alert.alertLevel);
    final bg = _levelBg(alert.alertLevel);
    final icon = _levelIcon(alert.alertLevel);
    final label = _levelLabel(alert.alertLevel);

    // Detect estrus alert
    final isEstrus = alert.message.toLowerCase().contains('estrus');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEstrus ? Symbols.favorite : icon,
                    color: isEstrus ? const Color(0xFFEC4899) : color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.animalName.isNotEmpty
                            ? alert.animalName
                            : 'Animal inconnu',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _relativeTime(alert.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disease / message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isEstrus ? Symbols.cycle : Symbols.biotech,
                      size: 16,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.message.isNotEmpty
                            ? alert.message
                            : 'Anomalie détectée',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
