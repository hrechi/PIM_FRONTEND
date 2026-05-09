import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/security_incident.dart';
import '../../services/api_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/constants.dart';
import '../../l10n/l10n_extensions.dart';
import 'live_feed_screen.dart'; // same security/ folder

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
  bool _sirenActive = false;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _fetchIncident();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  void _initSocket() {
    _socket = IO.io(
      'http://${AppConfig.serverHost}:${AppConfig.serverPort}',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket.connect();
    _socket.onConnect((_) => debugPrint('[SOCKET] Siren socket connected'));
    _socket.onDisconnect(
      (_) => debugPrint('[SOCKET] Siren socket disconnected'),
    );
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

  Color get _typeColor {
    switch (_incident?.type) {
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

  IconData get _typeIcon {
    switch (_incident?.type) {
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

  String get _typeLabel {
    switch (_incident?.type) {
      case 'intruder':
        return 'INTRUDER';
      case 'acoustic_engine':
        return 'ENGINE';
      case 'acoustic_glass':
        return 'GLASS BREAK';
      case 'acoustic_loud':
        return 'LOUD NOISE';
      case 'acoustic_anomaly':
        return 'ACOUSTIC';
      default:
        return 'ANIMAL';
    }
  }

  String get _typeName {
    switch (_incident?.type) {
      case 'intruder':
        return 'Intruder';
      case 'acoustic_engine':
        return 'Suspicious Engine';
      case 'acoustic_glass':
        return 'Glass Break / Impact';
      case 'acoustic_loud':
        return 'Loud Anomaly';
      case 'acoustic_anomaly':
        return 'Acoustic Anomaly';
      default:
        return 'Animal';
    }
  }

  String get _threatDescription {
    switch (_incident?.type) {
      case 'intruder':
        return 'An unknown person was detected on your property. Review the footage and take appropriate action.';
      case 'acoustic_engine':
        return 'A suspicious engine or motor sound was detected near the farm perimeter.';
      case 'acoustic_glass':
        return 'A high-frequency impact was detected — possible glass break or forced entry.';
      case 'acoustic_loud':
        return 'An unusually loud sound was detected by the acoustic monitoring system.';
      case 'acoustic_anomaly':
        return 'An acoustic threat was detected by the sound monitoring system.';
      default:
        return 'An animal was detected in a restricted area. Review the footage below.';
    }
  }

  String get _imageUrl {
    if (_incident == null) return '';
    return '${ApiService.mediaBaseUrl}${_incident!.imagePath}';
  }

  void _markAsResolved() {
    setState(() => _isResolved = true);
    if (_sirenActive) _toggleSiren();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.incidentResolved),
        backgroundColor: AppColorPalette.fieldFreshMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleSiren() {
    // Ensure socket is connected before emitting
    if (!_socket.connected) {
      _socket.connect();
    }

    if (_sirenActive) {
      _socket.emit('stop_siren', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      setState(() => _sirenActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_off, color: Colors.white),
              const SizedBox(width: 10),
              Text(context.l10n.sirenDeactivated),
            ],
          ),
          backgroundColor: AppColorPalette.charcoalGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      _socket.emit('trigger_siren', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      setState(() => _sirenActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white),
              const SizedBox(width: 10),
              Text(context.l10n.sirenActivated),
            ],
          ),
          backgroundColor: AppColorPalette.alertError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
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
            label: Text(context.l10n.goBack),
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
          backgroundColor: _typeColor,
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
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey.shade900,
                      child: Icon(_typeIcon, size: 80, color: Colors.white30),
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
                        color: _typeColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _typeColor.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _typeLabel,
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
                _buildDetailsGrid(),
                const SizedBox(height: 24),
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
    final isActive = !_isResolved;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _isResolved
            ? const Color(0xFF1B5E20)
            : AppColorPalette.alertError,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: AppColorPalette.alertError.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          if (isActive)
            BoxShadow(
              color: AppColorPalette.alertError.withValues(alpha: 0.2),
              blurRadius: 60,
              spreadRadius: -4,
            ),
          if (!isActive)
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
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
                _isResolved ? Icons.check_circle : Icons.warning_amber_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _isResolved ? context.l10n.done : 'ACTIVE THREAT',
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
                : _threatDescription,
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

  // ── Details Grid ────────────────────────────────────────────
  Widget _buildDetailsGrid() {
    final timestamp = _incident!.timestamp;
    final formattedDate = DateFormat('MMM d, yyyy').format(timestamp);
    final formattedTime = DateFormat('HH:mm:ss').format(timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            'Incident Details',
            style: AppTextStyles.h3(
              color: AppColorPalette.charcoalGreen,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _detailTile(
                Icons.category_rounded,
                'Detection Type',
                _typeName,
                _typeColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _detailTile(
                Icons.calendar_today_rounded,
                'Date',
                formattedDate,
                AppColorPalette.fieldFreshMid,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _detailTile(
                Icons.access_time_rounded,
                'Time',
                formattedTime,
                AppColorPalette.mistyBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _detailTile(
                Icons.fingerprint_rounded,
                'Incident ID',
                widget.incidentId.length >= 8
                    ? widget.incidentId.substring(0, 8).toUpperCase()
                    : widget.incidentId.toUpperCase(),
                AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _detailTile(
                Icons.speed_rounded,
                'Confidence',
                '92%',
                AppColorPalette.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _detailTile(
                Icons.sensors_rounded,
                'Sensor',
                _incident!.type.startsWith('acoustic') ? 'Acoustic' : 'Camera',
                AppColorPalette.robotTechStart,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailTile(IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorPalette.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColorPalette.softSlate,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColorPalette.charcoalGreen,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
              _isResolved ? context.l10n.incidentResolved : 'MARK AS RESOLVED',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isResolved
                  ? AppColorPalette.fieldFreshMid
                  : AppColorPalette.info,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColorPalette.fieldFreshMid,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColorPalette.info.withValues(alpha: 0.4),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Siren Toggle
        if (!_isResolved)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _toggleSiren,
              icon: Icon(
                _sirenActive
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
              ),
              label: Text(
                _sirenActive ? 'STOP SIREN' : 'ACTIVATE SIREN',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _sirenActive
                    ? AppColorPalette.charcoalGreen
                    : AppColorPalette.alertError,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: _sirenActive ? 2 : 6,
                shadowColor: _sirenActive
                    ? Colors.transparent
                    : AppColorPalette.alertError.withValues(alpha: 0.4),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Live Feed Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LiveFeedScreen()));
            },
            icon: const Icon(Icons.videocam_rounded),
            label: const Text(
              'VIEW LIVE FEED',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorPalette.robotTechStart,
              side: const BorderSide(
                color: AppColorPalette.robotTechStart,
                width: 2,
              ),
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
