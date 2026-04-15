import 'dart:async';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../services/animal_service.dart';

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  final AnimalService _animalService = AnimalService();
  final GlobalKey<FormState> _startSessionFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _endSessionFormKey = GlobalKey<FormState>();
  final TextEditingController _startMileageController = TextEditingController();
  final TextEditingController _startHoursController = TextEditingController();
  final TextEditingController _taskTypeController = TextEditingController();
  final TextEditingController _startNotesController = TextEditingController();
  final TextEditingController _endMileageController = TextEditingController();
  final TextEditingController _endHoursController = TextEditingController();
  final TextEditingController _fuelLevelController = TextEditingController();
  final TextEditingController _conditionNoteController = TextEditingController();
  final TextEditingController _checkInNotesController = TextEditingController();

  List<Animal> _animals = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _scannerBusy = false;
  String? _error;
  String? _selectedAssetId;
  Map<String, dynamic>? _activeSession;
  DateTime? _sessionStartedAt;
  Timer? _sessionTimer;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sessionTimer?.cancel();
    _startMileageController.dispose();
    _startHoursController.dispose();
    _taskTypeController.dispose();
    _startNotesController.dispose();
    _endMileageController.dispose();
    _endHoursController.dispose();
    _fuelLevelController.dispose();
    _conditionNoteController.dispose();
    _checkInNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final auth = context.read<AuthProvider>();
    final assetProvider = context.read<AssetProvider>();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        assetProvider.fetchAssets(),
        assetProvider.fetchWeeklyUsageIntensity(),
      ]);

      final assignedFieldId = auth.user?.assignedFieldId;
      final animals = await _animalService.getAnimals(fieldId: assignedFieldId);
      final activeSession = assetProvider.activeUsageSession;
      final activeAssetId = assetProvider.activeAssetId;
      final startTime = activeSession != null
          ? DateTime.tryParse(activeSession['startTime']?.toString() ?? '')
          : null;

      if (!mounted) return;
      setState(() {
        _animals = assignedFieldId == null
            ? animals
            : animals.where((animal) => animal.fieldId == assignedFieldId).toList();
        _selectedAssetId = activeAssetId ??
            (_selectedAssetId ??
                (assetProvider.assets.isNotEmpty ? assetProvider.assets.first.id : null));
        _activeSession = activeSession;
        _sessionStartedAt = startTime;
        _isLoading = false;
      });

      if (startTime != null) {
        _startSessionTimer(startTime);
      } else {
        _stopSessionTimer();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load operational dashboard.';
        _isLoading = false;
      });
    }
  }

  void _startSessionTimer(DateTime startTime) {
    _sessionTimer?.cancel();
    _sessionStartedAt = startTime;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _sessionStartedAt = null;
  }

  AssetItem? _assetById(List<AssetItem> assets, String? assetId) {
    if (assetId == null) return null;
    for (final asset in assets) {
      if (asset.id == assetId) return asset;
    }
    return null;
  }

  void _primeStartSessionFields(AssetItem asset) {
    _selectedAssetId = asset.id;
    _startMileageController.text = asset.mileage?.toStringAsFixed(0) ?? '';
    _startHoursController.text = asset.operatingHours?.toStringAsFixed(1) ?? '';
    _taskTypeController.clear();
    _startNotesController.clear();
    _startTime = DateTime.now();
  }

  void _primeCheckInFields() {
    _endMileageController.clear();
    _endHoursController.clear();
    _fuelLevelController.clear();
    _conditionNoteController.clear();
    _checkInNotesController.clear();
    _endTime = DateTime.now();
  }

  Future<void> _openQrSessionScanner() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _glassSheet(
          heightFactor: 0.92,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) async {
                  if (_scannerBusy) return;
                  final code = capture.barcodes.isNotEmpty
                      ? capture.barcodes.first.rawValue
                      : null;
                  if (code == null || code.isEmpty) return;
                  _scannerBusy = true;

                  final result = await context.read<AssetProvider>().getByQrValue(code);
                  if (!mounted) return;
                  Navigator.of(sheetContext).pop();
                  _scannerBusy = false;

                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Asset not found for this QR code.')),
                    );
                    return;
                  }

                  final asset = result['asset'] as AssetItem;
                  await _openStartSessionSheet(asset, result['aiMessage']?.toString());
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: _glassCard(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Scan the asset QR code to start a live session.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openStartSessionSheet(AssetItem asset, [String? aiMessage]) async {
    _primeStartSessionFields(asset);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _glassSheet(
          heightFactor: 0.89,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _startSessionFormKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9EE6B7).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF9EE6B7)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Start Session',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      asset.brand + (asset.model != null ? ' • ${asset.model}' : ''),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      asset.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (aiMessage != null && aiMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _glassCard(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          aiMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startMileageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: _fieldDecoration('Initial mileage'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value.trim()) == null) return 'Invalid mileage';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _startHoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: _fieldDecoration('Initial hours'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value.trim()) == null) return 'Invalid hours';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _taskTypeController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _fieldDecoration('Task type').copyWith(
                        hintText: 'Plowing, transport, spraying, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _startNotesController,
                      maxLines: 2,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _fieldDecoration('Optional notes').copyWith(
                        hintText: 'Route, field condition, or delivery details',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitStartSession(asset, sheetContext),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Session'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B8F5A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCheckInSheet(AssetItem asset) async {
    _primeCheckInFields();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _glassSheet(
          heightFactor: 0.88,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: Form(
              key: _endSessionFormKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stop & Check-in',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      asset.brand + (asset.model != null ? ' • ${asset.model}' : ''),
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _endMileageController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: _fieldDecoration('End mileage'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value.trim()) == null) return 'Invalid mileage';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _endHoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: _fieldDecoration('End hours'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Required';
                              if (double.tryParse(value.trim()) == null) return 'Invalid hours';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fuelLevelController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _fieldDecoration('Fuel level %').copyWith(
                        hintText: '0 - 100',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Required';
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null) return 'Invalid fuel level';
                        if (parsed < 0 || parsed > 100) return 'Must be between 0 and 100';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _conditionNoteController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _fieldDecoration('Condition note').copyWith(
                        hintText: 'Optional notes about noises, leaks, or vibration',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _checkInNotesController,
                      maxLines: 2,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: _fieldDecoration('Return notes').copyWith(
                        hintText: 'Optional handover notes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitEndSession(asset, sheetContext),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Check-in Asset'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B5B4D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitStartSession(AssetItem asset, BuildContext sheetContext) async {
    if (!(_startSessionFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await context.read<AssetProvider>().startUsageSession(
            assetId: asset.id,
            startMileage: double.parse(_startMileageController.text.trim()),
            startOperatingHours: double.parse(_startHoursController.text.trim()),
            taskType: _taskTypeController.text.trim(),
            startTime: _startTime,
            notes: _startNotesController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _activeSession = response;
        _selectedAssetId = asset.id;
        _sessionStartedAt = DateTime.tryParse(response['startTime']?.toString() ?? '') ?? DateTime.now();
        _isSubmitting = false;
      });
      _startSessionTimer(_sessionStartedAt!);
      await context.read<AssetProvider>().fetchWeeklyUsageIntensity();
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Live session started.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start session.')),
      );
    }
  }

  Future<void> _submitEndSession(AssetItem asset, BuildContext sheetContext) async {
    if (!(_endSessionFormKey.currentState?.validate() ?? false)) return;
    final active = _activeSession;
    if (active == null) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<AssetProvider>().endUsageSession(
            usageLogId: active['id']?.toString() ?? '',
            endMileage: double.parse(_endMileageController.text.trim()),
            endOperatingHours: double.parse(_endHoursController.text.trim()),
            fuelLevel: double.parse(_fuelLevelController.text.trim()),
            conditionNote: _conditionNoteController.text.trim(),
            endTime: _endTime,
            returnConfirmation: true,
            notes: _checkInNotesController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _activeSession = null;
        _selectedAssetId = asset.id;
        _isSubmitting = false;
      });
      _stopSessionTimer();
      await context.read<AssetProvider>().fetchAssets();
      await context.read<AssetProvider>().fetchWeeklyUsageIntensity();
      Navigator.of(sheetContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset checked in successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete check-in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final assetProvider = context.watch<AssetProvider>();
    final user = auth.user;
    final assets = assetProvider.assets
      .where((asset) => asset.status != 'MAINTENANCE')
      .toList();
    final activeSession = assetProvider.activeUsageSession ?? _activeSession;
    final activeAsset = _assetById(assets, assetProvider.activeAssetId);
    final selectedAsset = activeAsset ?? _assetById(assets, _selectedAssetId) ?? (assets.isNotEmpty ? assets.first : null);
    final weeklyData = assetProvider.weeklyUsageIntensity;
    final mechanicalAsset = selectedAsset ?? (assets.isNotEmpty ? assets.first : null);

    return Scaffold(
      backgroundColor: const Color(0xFF08140E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Operational Farmer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.withValues(
                      alpha: 0.6 + _glowController.value * 0.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.45),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const _FarmBackdrop(),
          RefreshIndicator(
            onRefresh: _loadDashboard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _buildHero(user),
                const SizedBox(height: 14),
                _buildMetricsRow(assets.length, _animals.length, weeklyData),
                const SizedBox(height: 14),
                _buildSessionLauncherCard(assets, selectedAsset),
                if (activeSession != null) ...[
                  const SizedBox(height: 14),
                  _buildLiveSessionCard(assets, activeSession),
                ],
                const SizedBox(height: 14),
                _buildWeeklyUsageCard(weeklyData),
                const SizedBox(height: 14),
                _buildMechanicalExpertCard(mechanicalAsset),
                const SizedBox(height: 14),
                _buildSectionTitle('Assigned Assets'),
                const SizedBox(height: 10),
                ..._buildAssetsList(assets),
                const SizedBox(height: 14),
                _buildSectionTitle('Assigned Animals'),
                const SizedBox(height: 10),
                ..._buildAnimalsList(_animals),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorCard(_error!),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(dynamic user) {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF61C06F), Color(0xFF2F5D3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF61C06F).withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.agriculture_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good to see you${user?.name != null ? ', ${user!.name}' : ''}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Operational view for your assigned field${user?.assignedFieldId != null ? ' (${user!.assignedFieldId})' : ''}.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(int assetCount, int animalCount, List<Map<String, dynamic>> weeklyData) {
    final totalHours = weeklyData.fold<double>(
      0,
      (sum, item) => sum + ((item['totalHours'] as num?)?.toDouble() ?? 0),
    );

    return Row(
      children: [
        Expanded(child: _metricCard('Assets', assetCount.toString(), Icons.precision_manufacturing_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Animals', animalCount.toString(), Icons.pets_rounded)),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Weekly Hours', totalHours.toStringAsFixed(1), Icons.query_stats_rounded)),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return _glassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF9EE6B7), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionLauncherCard(List<AssetItem> assets, AssetItem? selectedAsset) {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF9EE6B7)),
              const SizedBox(width: 10),
              Text(
                'Session Management',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedAsset != null
                ? 'Ready to start a live session on ${selectedAsset.brand} ${selectedAsset.model ?? selectedAsset.name}.'
                : 'Scan a QR code to open the start-session bottom sheet.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || assets.isEmpty ? null : _openQrSessionScanner,
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('Scan QR & Start Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B8F5A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          if (selectedAsset != null) ...[
            const SizedBox(height: 14),
            _sessionPreviewChip(selectedAsset),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveSessionCard(List<AssetItem> assets, Map<String, dynamic> session) {
    final activeAsset = _assetById(assets, session['assetId']?.toString());
    final startedAt = _sessionStartedAt ??
        DateTime.tryParse(session['startTime']?.toString() ?? '') ??
        DateTime.now();
    final duration = DateTime.now().difference(startedAt);

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Color(0xFF9EE6B7)),
              const SizedBox(width: 10),
              Text(
                'Live Session',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _smallInfoChip(
                  'Asset',
                  activeAsset != null ? activeAsset.name : session['assetId']?.toString() ?? 'Unknown',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallInfoChip('Timer', _formatElapsed(duration)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Task: ${session['taskType']?.toString() ?? 'Operational work'}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Started at ${_formatDateTime(startedAt)}',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting || activeAsset == null ? null : () => _openCheckInSheet(activeAsset),
              icon: const Icon(Icons.stop_circle_rounded),
              label: const Text('Stop & Check-in'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B5B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyUsageCard(List<Map<String, dynamic>> weeklyData) {
    final bars = <BarChartGroupData>[];
    for (var index = 0; index < 7; index++) {
      final value = index < weeklyData.length
          ? (weeklyData[index]['totalHours'] as num?)?.toDouble() ?? 0
          : 0.0;
      bars.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              width: 14,
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF9EE6B7), Color(0xFF4B8F5A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ],
        ),
      );
    }

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF9EE6B7)),
              const SizedBox(width: 10),
              Text(
                'Usage Intensity',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: _weeklyMax(weeklyData),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[index],
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: bars,
                alignment: BarChartAlignment.spaceAround,
                groupsSpace: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicalExpertCard(AssetItem? asset) {
    final diagnosis = asset?.diagnosis;
    final title = asset == null ? 'Mechanical AI Expert' : '${asset.brand} ${asset.model ?? asset.name}';

    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF61C06F).withValues(alpha: 0.22),
                      const Color(0xFF9EE6B7).withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF9EE6B7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mechanical AI Expert',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            diagnosis?['technicalBulletin']?.toString() ??
                'The AI bulletin will appear once a machine is loaded with mileage and model data.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallInfoChip(
                  'Health',
                  '${diagnosis?['riskPercentage']?.toString() ?? '0'}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _smallInfoChip(
                  'Service interval',
                  '${diagnosis?['serviceIntervalKm']?.toString() ?? 'N/A'} km',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF9EE6B7).withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9EE6B7).withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAssetsList(List<AssetItem> assets) {
    if (assets.isEmpty) {
      return [
        _glassCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No assigned assets are available yet.',
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ];
    }

    return assets
        .map(
          (asset) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _glassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _brandIcon(asset.brand),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          asset.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _healthPill(_diagnosisScore(asset)),
                    ],
                  ),
                  if (((asset.diagnosis?['failureProbability'] as num?)?.toDouble() ?? 0) > 80) ...[
                    const SizedBox(height: 8),
                    _precheckBadge(),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${asset.brand}${asset.model != null ? ' • ${asset.model}' : ''}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pro Tip: ${asset.diagnosis?['maintenanceProTip']?.toString() ?? 'Inspect lubrication and drive alignment before the next session.'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _healthBar((asset.diagnosis?['failureProbability'] as num?)?.toDouble() ?? 0),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _openStartSessionSheet(asset),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('Select for Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B8F5A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bulletin: ${asset.diagnosis?['technicalBulletin']?.toString() ?? 'Mechanical AI expert will update with model-specific bulletin.'}',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _brandIcon(String brand) {
    final lower = brand.toLowerCase();
    IconData icon = Icons.agriculture_rounded;
    if (lower.contains('mitsubishi')) icon = Icons.directions_car_filled_rounded;
    if (lower.contains('landini')) icon = Icons.agriculture_rounded;
    if (lower.contains('kubota')) icon = Icons.local_shipping_rounded;
    if (lower.contains('caterpillar')) icon = Icons.construction_rounded;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF9EE6B7).withValues(alpha: 0.14),
      ),
      child: Icon(icon, color: const Color(0xFF9EE6B7), size: 18),
    );
  }

  Widget _healthBar(double failureProbability) {
    final normalized = (failureProbability.clamp(0, 100)) / 100;
    final health = 1 - normalized;
    final color = health > 0.6
        ? const Color(0xFF61C06F)
        : health > 0.3
            ? const Color(0xFFE3A77B)
            : const Color(0xFFE36D6D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick-View Health',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 11,
              ),
            ),
            Text(
              '${(health * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: health,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _precheckBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE36D6D).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE36D6D).withValues(alpha: 0.32)),
      ),
      child: Text(
        'Pre-check Required',
        style: GoogleFonts.poppins(
          color: const Color(0xFFE36D6D),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Widget> _buildAnimalsList(List<Animal> animals) {
    if (animals.isEmpty) {
      return [
        _glassCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No animals are linked to this field yet.',
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ),
      ];
    }

    return animals
        .map(
          (animal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _glassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9EE6B7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.pets_rounded, color: Color(0xFF9EE6B7)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${animal.animalType.toUpperCase()} • ${animal.healthStatus}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildErrorCard(String message) {
    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE3A77B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.68)),
      filled: true,
      fillColor: const Color(0xFF0F2016).withValues(alpha: 0.82),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9EE6B7), width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }

  Widget _sessionPreviewChip(AssetItem asset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF112316),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9EE6B7).withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.devices_rounded, color: Color(0xFF9EE6B7), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${asset.brand}${asset.model != null ? ' • ${asset.model}' : ''}',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthPill(double? score) {
    final value = score ?? 0;
    final isHealthy = value < 40;
    final isWarning = value >= 40 && value < 70;
    final color = isHealthy
        ? const Color(0xFF61C06F)
        : isWarning
            ? const Color(0xFFE3A77B)
            : const Color(0xFFE36D6D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '${value.toStringAsFixed(0)}% health',
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double? _diagnosisScore(AssetItem asset) {
    final score = asset.diagnosis?['riskPercentage'];
    if (score is num) {
      return (100 - score.toDouble()).clamp(0, 100);
    }
    return null;
  }

  double _weeklyMax(List<Map<String, dynamic>> weeklyData) {
    final peak = weeklyData.fold<double>(
      0,
      (maxValue, item) => (item['totalHours'] as num?)?.toDouble() != null
          ? ((item['totalHours'] as num).toDouble() > maxValue ? (item['totalHours'] as num).toDouble() : maxValue)
          : maxValue,
    );
    return peak < 4 ? 4 : peak + 2;
  }

  Widget _glassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF102218).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassSheet({required Widget child, required double heightFactor}) {
    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A170F).withValues(alpha: 0.96),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _FarmBackdrop extends StatelessWidget {
  const _FarmBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF08140E), Color(0xFF0C1D14), Color(0xFF15291B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -30,
            child: _GlowBlob(color: Color(0xFF2C6E49).withValues(alpha: 0.22), size: 180),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _GlowBlob(color: Color(0xFF9EE6B7).withValues(alpha: 0.11), size: 140),
          ),
          Positioned(
            bottom: -60,
            left: 20,
            child: _GlowBlob(color: Color(0xFF61C06F).withValues(alpha: 0.14), size: 220),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
