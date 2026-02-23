import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/security_incident.dart';
import '../services/api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class IncidentDetailScreen extends StatefulWidget {
  final String incidentId;

  const IncidentDetailScreen({super.key, required this.incidentId});

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  SecurityIncident? _incident;
  bool _isLoading = true;
  String? _error;
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();
    _fetchIncident();
  }

  Future<void> _fetchIncident() async {
    try {
      final response = await ApiService.get(
        '/security/incidents/${widget.incidentId}',
        withAuth: true,
      );
      if (response == null) {
        setState(() {
          _error = 'Incident not found';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _incident = SecurityIncident.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load incident';
        _isLoading = false;
      });
    }
  }

  bool get _isIntruder => _incident?.type == 'intruder';

  String get _imageUrl {
    if (_incident == null) return '';
    return '${ApiService.mediaBaseUrl}${_incident!.imagePath}';
  }

  void _markAsResolved() {
    setState(() => _isResolved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Incident marked as resolved'),
        backgroundColor: AppColorPalette.fieldFreshMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _alertAuthorities() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.local_police, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Expanded(child: Text('Alert Authorities')),
          ],
        ),
        content: const Text(
          'This will send an alert to local authorities with the incident details. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Authorities have been notified'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error!, style: AppTextStyles.h3(color: Colors.red.shade300)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // ── Hero Image App Bar ──────────────────────────────────
        SliverAppBar(
          expandedHeight: 360,
          pinned: true,
          stretch: true,
          backgroundColor: _isIntruder
              ? const Color(0xFFB71C1C)
              : const Color(0xFF4A148C),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Hero(
              tag: 'incident-image-${widget.incidentId}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade900,
                      child: Icon(
                        _isIntruder ? Icons.person_off : Icons.pets,
                        size: 80,
                        color: Colors.white30,
                      ),
                    ),
                  ),
                  // Gradient scrim at top & bottom
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  // Type badge on image
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isIntruder
                            ? Colors.red.shade700
                            : Colors.purple.shade700,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (_isIntruder ? Colors.red : Colors.purple)
                                .withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isIntruder
                                ? Icons.person_off_rounded
                                : Icons.pets_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isIntruder ? 'INTRUDER' : 'ANIMAL',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Body content ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 20),
                _buildDetailsCard(),
                const SizedBox(height: 28),
                _buildActions(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Card ─────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: _isResolved
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : _isIntruder
                  ? [const Color(0xFFB71C1C), const Color(0xFFC62828)]
                  : [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isResolved
                    ? Colors.green
                    : _isIntruder
                        ? Colors.red
                        : Colors.purple)
                .withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isResolved
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _isResolved ? 'RESOLVED' : 'ACTIVE THREAT',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isResolved
                ? 'This incident has been reviewed and marked as resolved.'
                : _isIntruder
                    ? 'An unknown person was detected on your property. Review the footage and take appropriate action.'
                    : 'An animal was detected in a restricted area. Review the footage below.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Details Card ────────────────────────────────────────────
  Widget _buildDetailsCard() {
    final timestamp = _incident!.timestamp;
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Incident Details',
            style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow(Icons.category_rounded, 'Detection Type',
              _isIntruder ? 'Intruder' : 'Animal'),
          const Divider(height: 24),
          _detailRow(Icons.calendar_today_rounded, 'Date', formattedDate),
          const Divider(height: 24),
          _detailRow(Icons.access_time_rounded, 'Time', formattedTime),
          const Divider(height: 24),
          _detailRow(Icons.fingerprint_rounded, 'Incident ID',
              widget.incidentId.substring(0, 8).toUpperCase()),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColorPalette.fieldFreshMid.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColorPalette.fieldFreshMid, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColorPalette.softSlate,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColorPalette.charcoalGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Action Buttons ──────────────────────────────────────────
  Widget _buildActions() {
    return Column(
      children: [
        // Mark as Resolved
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _isResolved ? null : _markAsResolved,
            icon: Icon(
              _isResolved ? Icons.check_circle : Icons.check_circle_outline,
            ),
            label: Text(
              _isResolved ? 'RESOLVED' : 'MARK AS RESOLVED',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isResolved ? Colors.green.shade600 : AppColorPalette.fieldFreshMid,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green.shade400,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColorPalette.fieldFreshMid.withValues(alpha: 0.4),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Alert Authorities
        if (_isIntruder && !_isResolved)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _alertAuthorities,
              icon: Icon(Icons.local_police_outlined,
                  color: Colors.red.shade700),
              label: Text(
                'ALERT AUTHORITIES',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade700, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
