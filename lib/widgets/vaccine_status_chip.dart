import 'package:flutter/material.dart';
import '../models/vaccine_models.dart';

class VaccineStatusChip extends StatelessWidget {
  final String status;
  final bool small;

  const VaccineStatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final cfg = _config[status] ?? _config['DEFAULT']!;
    final fs = small ? 10.0 : 12.0;
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 5);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, color: cfg.color, size: small ? 10 : 13),
          const SizedBox(width: 4),
          Text(cfg.label, style: TextStyle(color: cfg.color, fontSize: fs, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static const _config = {
    'PENDING':   _Cfg(Color(0xFF1B3C35), Color(0xFFF8FAF7), Color(0xFFD1FAE5), Icons.schedule_rounded, 'Pending'),
    'NOTIFIED':  _Cfg(Color(0xFF3B82F6), Color(0xFFEFF6FF), Color(0xFFBFDBFE), Icons.notifications_rounded, 'Notified'),
    'DONE':      _Cfg(Color(0xFF22C55E), Color(0xFFF0FDF4), Color(0xFFBBF7D0), Icons.check_circle_rounded, 'Done'),
    'OVERDUE':   _Cfg(Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFFECACA), Icons.warning_rounded, 'Overdue'),
    'CANCELLED': _Cfg(Color(0xFF94A3B8), Color(0xFFF8FAFC), Color(0xFFE2E8F0), Icons.cancel_rounded, 'Cancelled'),
    'DEFAULT':   _Cfg(Color(0xFF1B3C35), Color(0xFFF8FAF7), Color(0xFFE2E8F0), Icons.help_outline_rounded, 'Unknown'),
  };
}

class _Cfg {
  final Color color, bg, border;
  final IconData icon;
  final String label;
  const _Cfg(this.color, this.bg, this.border, this.icon, this.label);
}

// ─── Priority badge ──────────────────────────────────────────────────────
class VaccinePriorityBadge extends StatelessWidget {
  final bool isMandatory;
  const VaccinePriorityBadge({super.key, required this.isMandatory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMandatory ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isMandatory ? 'MANDATORY' : 'RECOMMENDED',
        style: TextStyle(
          color: isMandatory ? const Color(0xFFEF4444) : const Color(0xFF1B3C35),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
