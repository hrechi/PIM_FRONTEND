import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/animal_health_models.dart';

/// Écran d'explication complète du diagnostic IA
class DiagnosisDetailScreen extends StatelessWidget {
  final DiagnosisResult result;
  final String animalName;

  const DiagnosisDetailScreen({
    super.key,
    required this.result,
    required this.animalName,
  });

  // ── Couleurs par niveau d'alerte ─────────────────────────
  Color get _alertColor {
    switch (result.alertLevel) {
      case 'critical': return const Color(0xFFDC2626);
      case 'medium':   return const Color(0xFFD97706);
      default:         return const Color(0xFF16A34A);
    }
  }

  String get _alertLabel {
    switch (result.alertLevel) {
      case 'critical': return 'CRITICAL';
      case 'medium':   return 'MODERATE';
      default:         return 'HEALTHY';
    }
  }

  IconData get _alertIcon {
    switch (result.alertLevel) {
      case 'critical': return Symbols.error;
      case 'medium':   return Symbols.warning;
      default:         return Symbols.check_circle;
    }
  }

  Color _severityColor(String severity) =>
      severity == 'high' ? const Color(0xFFDC2626) : const Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final exp = result.explanation;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Diagnosis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            Text(animalName, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 1. Score global ──────────────────────────────
          _buildScoreCard(),

          const SizedBox(height: 16),

          // ── 2. Résumé textuel ────────────────────────────
          if (exp != null) ...[
            _buildSummaryCard(exp),
            const SizedBox(height: 16),
          ],

          // ── 3. Valeurs capteurs ──────────────────────────
          if (exp != null) ...[
            _buildSensorCard(exp.sensorReadings),
            const SizedBox(height: 16),
          ],

          // ── 4. Déclencheurs (triggers) ───────────────────
          if (exp != null && exp.triggers.isNotEmpty) ...[
            _buildTriggersCard(exp.triggers),
            const SizedBox(height: 16),
          ],

          // ── 5. Probabilités par maladie ──────────────────
          _buildProbabilitiesCard(),

          const SizedBox(height: 16),

          // ── 6. Symptômes de la maladie détectée ─────────
          if (exp != null && exp.diseaseInfo.symptoms.isNotEmpty) ...[
            _buildSymptomsCard(exp.diseaseInfo),
            const SizedBox(height: 16),
          ],

          // ── 7. Recommandation ────────────────────────────
          if (exp != null) _buildRecommendationCard(exp),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Score global ─────────────────────────────────────────

  Widget _buildScoreCard() {
    final exp = result.explanation;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _alertColor.withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _alertColor.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _alertColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.healthScore.toInt()}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _alertColor),
                ),
                Text('/ 100', style: TextStyle(fontSize: 10, color: _alertColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_alertIcon, color: _alertColor, size: 18),
                    const SizedBox(width: 6),
                    Text(_alertLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _alertColor)),
                  ],
                ),
                const SizedBox(height: 4),
                if (result.predictedDisease != null)
                  Text(
                    exp?.diseaseInfo.label ?? result.predictedDisease!,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                Text(
                  'Confidence: ${(result.confidence * 100).toInt()}%  •  Anomaly: ${exp?.anomalyScorePct.toInt() ?? (result.isoScore * 50).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                if (result.isStaticFallback)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '⚠ Based on static fields — add IoT sensors for precision',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Résumé textuel ───────────────────────────────────────

  Widget _buildSummaryCard(DiagnosisExplanation exp) {
    return _card(
      icon: Symbols.summarize,
      color: const Color(0xFF1565C0),
      title: 'Diagnosis Summary',
      child: Text(
        exp.summary,
        style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
      ),
    );
  }

  // ── Valeurs capteurs ─────────────────────────────────────

  Widget _buildSensorCard(SensorSnapshot s) {
    return _card(
      icon: Symbols.sensors,
      color: const Color(0xFF0277BD),
      title: 'Sensor Readings (1h average)',
      child: Column(
        children: [
          _sensorRow('🌡️ Temperature', '${s.temperature.toStringAsFixed(2)} °C',
              delta: s.deltaTemp, unit: '°C', threshold: 0.5),
          _divider(),
          _sensorRow('❤️ Heart Rate', '${s.heartRate.toStringAsFixed(0)} bpm',
              delta: s.deltaHr, unit: 'bpm', threshold: 5),
          _divider(),
          _sensorRow('🏃 Activity Score', '${s.activityScore.toStringAsFixed(0)} / 100',
              delta: -s.activityDrop, unit: 'pts', threshold: 8, invertDelta: true),
          _divider(),
          _sensorRow('🛏️ Lying Time (6h)', '${s.lyingPct6h.toStringAsFixed(0)} %',
              delta: s.lyingPct6h - 45, unit: '%', threshold: 15),
          _divider(),
          _sensorRow('📐 Gait Asymmetry', s.accAsymmetry.toStringAsFixed(4),
              delta: s.accAsymmetry - 0.05, unit: '', threshold: 0.1),
        ],
      ),
    );
  }

  Widget _sensorRow(String label, String value, {
    required double delta,
    required String unit,
    required double threshold,
    bool invertDelta = false,
  }) {
    final isAbnormal = delta.abs() >= threshold;
    final effectiveDelta = invertDelta ? -delta : delta;
    final isUp = effectiveDelta > 0;
    final deltaColor = isAbnormal
        ? (isUp ? const Color(0xFFDC2626) : const Color(0xFF1565C0))
        : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: deltaColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${isUp ? '+' : ''}${delta.toStringAsFixed(delta.abs() < 1 ? 3 : 1)}$unit',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deltaColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Déclencheurs ─────────────────────────────────────────

  Widget _buildTriggersCard(List<DiagnosisTrigger> triggers) {
    return _card(
      icon: Symbols.warning,
      color: const Color(0xFFD97706),
      title: 'Anomaly Triggers',
      subtitle: 'Parameters that triggered the alert',
      child: Column(
        children: triggers.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          return Column(
            children: [
              if (i > 0) _divider(),
              _triggerRow(t),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _triggerRow(DiagnosisTrigger t) {
    final color = _severityColor(t.severity);
    final isUp  = t.direction == '↑';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Center(
              child: Text(t.direction, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                Text(
                  'Normal: ${t.normalRange}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${t.value.toStringAsFixed(t.unit.isEmpty ? 4 : 2)}${t.unit}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.severity.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Probabilités ─────────────────────────────────────────

  Widget _buildProbabilitiesCard() {
    final sorted = result.allProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final diseaseColors = {
      'saine':            const Color(0xFF16A34A),
      'mammite':          const Color(0xFFDC2626),
      'fievre':           const Color(0xFFEF4444),
      'boiterie':         const Color(0xFF9B59B6),
      'stress_thermique': const Color(0xFFF59E0B),
    };

    final diseaseLabels = {
      'saine':            'Healthy',
      'mammite':          'Mastitis',
      'fievre':           'Fever',
      'boiterie':         'Lameness',
      'stress_thermique': 'Heat Stress',
    };

    return _card(
      icon: Symbols.bar_chart,
      color: const Color(0xFF6A1B9A),
      title: 'Disease Probabilities',
      subtitle: 'XGBoost classification output',
      child: Column(
        children: sorted.map((e) {
          final color = diseaseColors[e.key] ?? const Color(0xFF309448);
          final label = diseaseLabels[e.key] ?? e.key;
          final pct   = (e.value * 100).toInt();
          final isTop = e.key == result.predictedDisease ||
              (result.predictedDisease == null && e.key == 'saine');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isTop)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                        child: Text('TOP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
                      ),
                    Expanded(
                      child: Text(label, style: TextStyle(
                        fontSize: 13,
                        fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                        color: isTop ? color : const Color(0xFF475569),
                      )),
                    ),
                    Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: e.value,
                    minHeight: isTop ? 10 : 7,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Symptômes ─────────────────────────────────────────────

  Widget _buildSymptomsCard(DiseaseInfo info) {
    return _card(
      icon: Symbols.medical_services,
      color: const Color(0xFFDC2626),
      title: '${info.label} — Clinical Signs',
      subtitle: info.description,
      child: Column(
        children: info.symptoms.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.circle, size: 6, color: Color(0xFFDC2626)),
              const SizedBox(width: 10),
              Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4))),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // ── Recommandation ────────────────────────────────────────

  Widget _buildRecommendationCard(DiagnosisExplanation exp) {
    final isUrgent = result.alertLevel == 'critical';
    final color    = isUrgent ? const Color(0xFFDC2626) : const Color(0xFF1565C0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isUrgent ? Symbols.emergency : Symbols.info, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? 'URGENT ACTION REQUIRED' : 'RECOMMENDATION',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(exp.recommendation, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: color.withAlpha(40))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                      if (subtitle != null)
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));
}
