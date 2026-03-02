import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/security/incident_detail_screen.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

/// Modern security alert overlay matching the Fieldly Agri-Tech design system.
///
/// Slides down from top with a clean glassmorphism card on a blurred scrim.
/// Supports intruder, animal, and all acoustic incident types.
class SecurityAlertOverlay extends StatefulWidget {
  final String incidentId;
  final String type;
  final String imageUrl;
  final VoidCallback onDismiss;

  const SecurityAlertOverlay({
    super.key,
    required this.incidentId,
    required this.type,
    required this.imageUrl,
    required this.onDismiss,
  });

  /// Show the overlay as a full-screen overlay entry on top of everything.
  static OverlayEntry show(
    BuildContext context, {
    required String incidentId,
    required String type,
    required String imageUrl,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => SecurityAlertOverlay(
        incidentId: incidentId,
        type: type,
        imageUrl: imageUrl,
        onDismiss: () => entry.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  @override
  State<SecurityAlertOverlay> createState() => _SecurityAlertOverlayState();
}

class _SecurityAlertOverlayState extends State<SecurityAlertOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  bool get _isIntruder => widget.type == 'intruder';
  bool get _isAcoustic => widget.type.startsWith('acoustic');

  Color get _accentColor {
    switch (widget.type) {
      case 'intruder':
        return AppColorPalette.alertError;
      case 'acoustic_engine':
        return const Color(0xFFE65100);
      case 'acoustic_glass':
        return const Color(0xFF1565C0);
      case 'acoustic_loud':
        return const Color(0xFF6A1B9A);
      case 'acoustic_anomaly':
        return AppColorPalette.robotTechStart;
      default:
        return AppColorPalette.warning;
    }
  }

  String get _alertTitle {
    switch (widget.type) {
      case 'intruder':
        return 'Intruder Detected';
      case 'acoustic_engine':
        return 'Suspicious Engine';
      case 'acoustic_glass':
        return 'Glass Break Detected';
      case 'acoustic_loud':
        return 'Loud Anomaly';
      case 'acoustic_anomaly':
        return 'Acoustic Threat';
      default:
        return 'Animal Detected';
    }
  }

  String get _alertBody {
    switch (widget.type) {
      case 'intruder':
        return 'An unknown person was detected on your farm. Immediate action required.';
      case 'acoustic_engine':
        return 'A suspicious engine sound was detected near the perimeter.';
      case 'acoustic_glass':
        return 'A high-frequency impact detected — possible glass break or forced entry.';
      case 'acoustic_loud':
        return 'An unusually loud sound was detected by the acoustic system.';
      case 'acoustic_anomaly':
        return 'An acoustic anomaly was flagged by the sound monitoring system.';
      default:
        return 'An animal was detected in a restricted area of your farm.';
    }
  }

  IconData get _alertIcon {
    switch (widget.type) {
      case 'intruder':
        return Icons.person_off_rounded;
      case 'acoustic_engine':
        return Icons.directions_car_rounded;
      case 'acoustic_glass':
        return Icons.broken_image_rounded;
      case 'acoustic_loud':
        return Icons.volume_up_rounded;
      case 'acoustic_anomaly':
        return Icons.graphic_eq_rounded;
      default:
        return Icons.pets_rounded;
    }
  }

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _slideController.reverse();
    widget.onDismiss();
  }

  void _viewIncident(BuildContext context) {
    _dismiss();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncidentDetailScreen(incidentId: widget.incidentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Blurred scrim ─────────────────────────────────────
          GestureDetector(
            onTap: _dismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
          ),

          // ── Slide-in card ─────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Accent header bar ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (_, __) => Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        blurRadius: _glowAnim.value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isIntruder
                        ? 'CRITICAL ALERT'
                        : _isAcoustic
                            ? 'ACOUSTIC ALERT'
                            : 'SECURITY ALERT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),

          // ── Body content ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // ── Thumbnail ────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accentColor.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderThumbnail(),
                              )
                            : _placeholderThumbnail(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ── Alert info ───────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _alertTitle,
                            style: AppTextStyles.h4(
                              color: AppColorPalette.charcoalGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _alertBody,
                            style: AppTextStyles.bodySmall(
                              color: AppColorPalette.softSlate,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Live badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _accentColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColorPalette.healthGlow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE',
                                  style: AppTextStyles.overline(
                                    color: _accentColor,
                                  ).copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Buttons ──────────────────────────────────────
                Row(
                  children: [
                    // DISMISS
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColorPalette.softSlate,
                          side: BorderSide(
                            color: AppColorPalette.mediumGrey,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'DISMISS',
                          style: AppTextStyles.buttonMedium(
                            color: AppColorPalette.softSlate,
                          ).copyWith(letterSpacing: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // VIEW INCIDENT
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: child,
                        ),
                        child: ElevatedButton(
                          onPressed: () => _viewIncident(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor:
                                _accentColor.withValues(alpha: 0.4),
                          ),
                          child: Text(
                            'VIEW INCIDENT',
                            style: AppTextStyles.buttonMedium(
                              color: Colors.white,
                            ).copyWith(letterSpacing: 0.8),
                          ),
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

  Widget _placeholderThumbnail() {
    return Container(
      color: _accentColor.withValues(alpha: 0.08),
      child: Icon(
        _alertIcon,
        color: _accentColor.withValues(alpha: 0.4),
        size: 36,
      ),
    );
  }
}
