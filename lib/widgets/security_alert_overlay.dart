import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/incident_history_screen.dart';
import '../theme/text_styles.dart';

/// High-fidelity security alert overlay shown when a push notification arrives
/// while the app is in the foreground.
///
/// Slides down from the top with a deep-red glassmorphism card,
/// blurred background, glowing header, incident thumbnail, and
/// two action buttons (DISMISS + VIEW INCIDENT with pulse animation).
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
  // Slide-in animation
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnim;

  // Pulse animation for VIEW INCIDENT button
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // Glow animation for CRITICAL ALERT header
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  bool get _isIntruder => widget.type == 'intruder';

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 4.0, end: 18.0).animate(
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
      MaterialPageRoute(builder: (_) => const IncidentHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Blurred background scrim ──────────────────────────
          GestureDetector(
            onTap: _dismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withValues(alpha: 0.45)),
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
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: _isIntruder
              ? [const Color(0xFFB71C1C), const Color(0xFF7B0000)]
              : [const Color(0xFF4A148C), const Color(0xFF1A0033)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isIntruder ? Colors.red : Colors.purple)
                .withValues(alpha: 0.5),
            blurRadius: 32,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBody(),
                const SizedBox(height: 20),
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Pulsing warning icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Text(
              'CRITICAL ALERT',
              style: AppTextStyles.h2(color: Colors.white).copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.redAccent,
                    blurRadius: _glowAnim.value,
                  ),
                  Shadow(
                    color: Colors.orange.withValues(alpha: 0.6),
                    blurRadius: _glowAnim.value * 1.5,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Close button
        GestureDetector(
          onTap: _dismiss,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        // ── Thumbnail ───────────────────────────────────────────
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
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
                    errorBuilder: (_, __, ___) => _placeholderThumbnail(),
                  )
                : _placeholderThumbnail(),
          ),
        ),
        const SizedBox(width: 16),
        // ── Alert info ──────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isIntruder ? 'Intruder Detected' : 'Animal Detected',
                style: AppTextStyles.h3(color: Colors.white).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isIntruder
                    ? 'An unknown person was detected on your farm. Immediate action required.'
                    : 'An animal was detected in a restricted area.',
                style: AppTextStyles.bodySmall(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              // Live badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF76FF03),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: AppTextStyles.overline(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholderThumbnail() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(
        _isIntruder ? Icons.person_off_rounded : Icons.pets,
        color: Colors.white54,
        size: 36,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        // ── DISMISS (outline) ───────────────────────────────────
        Expanded(
          child: OutlinedButton(
            onPressed: _dismiss,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'DISMISS',
              style: AppTextStyles.buttonMedium(color: Colors.white)
                  .copyWith(letterSpacing: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ── VIEW INCIDENT (pulse animated elevated) ─────────────
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
                backgroundColor: Colors.white,
                foregroundColor: _isIntruder
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFF4A148C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 8,
                shadowColor: Colors.white.withValues(alpha: 0.4),
              ),
              child: Text(
                'VIEW INCIDENT',
                style: AppTextStyles.buttonMedium(
                  color: _isIntruder
                      ? const Color(0xFFB71C1C)
                      : const Color(0xFF4A148C),
                ).copyWith(letterSpacing: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
