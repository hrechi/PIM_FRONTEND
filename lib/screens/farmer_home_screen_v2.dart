import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/asset_item.dart';
import '../models/animal.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../services/animal_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import 'profile_screen.dart';
import 'signin_screen.dart';

/// Redesigned Farmer Home Screen with Material Management System
class FarmerHomeScreenV2 extends StatefulWidget {
  const FarmerHomeScreenV2({super.key});

  @override
  State<FarmerHomeScreenV2> createState() => _FarmerHomeScreenV2State();
}

class _FarmerHomeScreenV2State extends State<FarmerHomeScreenV2> {
  final AnimalService _animalService = AnimalService();

  // State management
  List<AssetItem> _assignedMaterials = [];
  List<Animal> _animals = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _activeMaterialSession;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;

  // Controllers for material session
  final GlobalKey<FormState> _materialCheckInFormKey = GlobalKey<FormState>();
  final TextEditingController _materialNotesController =
      TextEditingController();
  final TextEditingController _completionStatusController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFarmerDashboard());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _materialNotesController.dispose();
    _completionStatusController.dispose();
    super.dispose();
  }

  Future<void> _loadFarmerDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final assetProvider = context.read<AssetProvider>();
      final assignedFieldId = auth.user?.assignedFieldId;

      await assetProvider.fetchAssets();

      // Usage stats should not block material visibility.
      try {
        await assetProvider.fetchWeeklyUsageIntensity();
      } catch (_) {}

      // Get animals for assigned field, but never let that block materials.
      List<Animal> animals = [];
      try {
        animals = await _animalService.getAnimals(fieldId: assignedFieldId);
      } catch (_) {}

      if (!mounted) return;

      // Keep a defensive field filter on client side in case backend payload is broad.
      final assignedMaterials = assetProvider.assets
          .where(
            (asset) =>
                asset.status != 'MAINTENANCE' &&
                (assignedFieldId == null || asset.fieldId == assignedFieldId),
          )
          .toList();

      // Get active session if any
      final activeSession = assetProvider.activeUsageSession;

      DateTime? startTime;
      if (activeSession != null) {
        startTime = DateTime.tryParse(
          activeSession['startTime']?.toString() ?? '',
        );
        if (startTime != null) {
          _startSessionTimer(startTime);
        }
      }

      setState(() {
        _assignedMaterials = assignedMaterials;
        _animals = animals;
        _activeMaterialSession = activeSession;
        _sessionStartTime = startTime;
        _error = assignedFieldId == null
            ? 'No field is assigned to this worker account yet.'
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  void _startSessionTimer(DateTime startTime) {
    _sessionTimer?.cancel();
    _sessionStartTime = startTime;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _sessionStartTime = null;
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Do you want to sign out of this worker account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await context.read<AuthProvider>().signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  String _formatElapsedTime(DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'My Materials & Equipment',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: AppColorPalette.wheatWarmClay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline_rounded),
            color: AppColorPalette.charcoalGreen,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            color: AppColorPalette.charcoalGreen,
            onPressed: _handleSignOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFarmerDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting Card
                  _buildGreetingCard(user),
                  const SizedBox(height: 20),

                  // Current Status / Active Material
                  if (_activeMaterialSession != null) ...[
                    _buildActiveMaterialCard(),
                    const SizedBox(height: 20),
                  ],

                  // Quick Stats
                  _buildQuickStatsRow(),
                  const SizedBox(height: 20),

                  // Operations quick actions
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 430;

                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/control_room',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      AppColorPalette.robotTechStart,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.videogame_asset_rounded),
                                label: const Text('Control Room'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/skill_certification',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0A7E52),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.workspace_premium_rounded,
                                ),
                                label: const Text('Skill Certification'),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/control_room'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColorPalette.robotTechStart,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.videogame_asset_rounded),
                              label: const Text('Control Room'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/skill_certification',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A7E52),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.workspace_premium_rounded),
                              label: const Text('Skill Path'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Material Selection & Management
                  _buildMaterialManagementSection(),
                  const SizedBox(height: 20),

                  // Assigned Materials List
                  if (_assignedMaterials.isNotEmpty) ...[
                    _buildMaterialsListSection(),
                    const SizedBox(height: 20),
                  ],

                  // Animals Section
                  if (_animals.isNotEmpty) ...[
                    _buildAnimalsSection(),
                    const SizedBox(height: 20),
                  ],

                  // Error Display
                  if (_error != null) ...[_buildErrorCard(_error!)],
                ],
              ),
            ),
    );
  }

  Widget _buildGreetingCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorPalette.charcoalGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${user?.name ?? 'Worker'}',
            style: AppTextStyles.h3(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your materials and equipment for today\'s work',
            style: AppTextStyles.bodySmall(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMaterialCard() {
    final activeAssetId = _activeMaterialSession?['assetId']?.toString();
    final activeMaterial = _assignedMaterials.firstWhere(
      (asset) => asset.id == activeAssetId,
      orElse: () => AssetItem(
        id: activeAssetId ?? '',
        name: 'Unknown',
        brand: 'Unknown',
        category: 'Equipment',
        status: 'IN_USE',
        serialNumber: '',
      ),
    );

    final startedAt = _sessionStartTime ?? DateTime.now();
    final elapsedTime = _formatElapsedTime(startedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withValues(alpha: 0.9), AppColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently in Use',
                      style: AppTextStyles.buttonSmall(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      elapsedTime,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activeMaterial.name,
            style: AppTextStyles.h4(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '${activeMaterial.brand} • ${activeMaterial.model ?? 'N/A'}',
            style: AppTextStyles.bodySmall(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCheckInDialog(activeMaterial),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Check-in Material'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.construction,
            label: 'Available',
            value: _assignedMaterials.length.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.pets,
            label: 'Animals',
            value: _animals.length.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.timer,
            label: 'Active',
            value: _activeMaterialSession != null ? '1' : '0',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColorPalette.charcoalGreen, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h4()),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption()),
        ],
      ),
    );
  }

  Widget _buildMaterialManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Start Using Material', style: AppTextStyles.h4()),
        const SizedBox(height: 12),
        if (_assignedMaterials.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No materials assigned yet',
                style: AppTextStyles.bodySmall(),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorPalette.charcoalGreen.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: DropdownButton<AssetItem>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: Text(
                      'Select material...',
                      style: AppTextStyles.bodySmall(),
                    ),
                    items: _assignedMaterials.map((material) {
                      return DropdownMenuItem(
                        value: material,
                        child: Text('${material.brand} - ${material.name}'),
                      );
                    }).toList(),
                    onChanged: (selected) {
                      if (selected != null) {
                        _showStartSessionDialog(selected);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _showStartSessionDialog(_assignedMaterials.first),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.charcoalGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMaterialsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Materials & Equipment', style: AppTextStyles.h4()),
        const SizedBox(height: 12),
        ..._assignedMaterials.map((material) => _buildMaterialCard(material)),
      ],
    );
  }

  Widget _buildMaterialCard(AssetItem material) {
    final isActive =
        _activeMaterialSession?['assetId']?.toString() == material.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.success
              : AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.precision_manufacturing,
                  color: AppColorPalette.charcoalGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(material.name, style: AppTextStyles.h4()),
                    const SizedBox(height: 4),
                    Text(
                      '${material.brand}${material.model != null ? ' • ${material.model}' : ''}',
                      style: AppTextStyles.bodySmall(),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          material.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        material.status,
                        style: AppTextStyles.caption(
                          color: _getStatusColor(material.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _showStartSessionDialog(material),
                ),
            ],
          ),
          if (material.mileage != null || material.operatingHours != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (material.mileage != null)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mileage: ',
                            style: AppTextStyles.caption(),
                          ),
                          TextSpan(
                            text: material.mileage?.toStringAsFixed(0) ?? 'N/A',
                            style: AppTextStyles.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (material.operatingHours != null)
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Hours: ',
                            style: AppTextStyles.caption(),
                          ),
                          TextSpan(
                            text:
                                material.operatingHours?.toStringAsFixed(1) ??
                                'N/A',
                            style: AppTextStyles.bodySmall(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Animals', style: AppTextStyles.h4()),
        const SizedBox(height: 12),
        ..._animals.take(3).map((animal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColorPalette.charcoalGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.pets, color: AppColorPalette.charcoalGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        style: AppTextStyles.bodySmall().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal.breed ?? 'Unknown',
                        style: AppTextStyles.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodySmall(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartSessionDialog(AssetItem material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Using: ${material.name}', style: AppTextStyles.h4()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${material.brand} • ${material.model ?? 'N/A'}',
              style: AppTextStyles.bodySmall(),
            ),
            const SizedBox(height: 16),
            Text(
              'Start time: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now())}',
              style: AppTextStyles.caption(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startMaterialSession(material);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showCheckInDialog(AssetItem material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Return Material: ${material.name}',
          style: AppTextStyles.h4(),
        ),
        content: Form(
          key: _materialCheckInFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${material.brand} • ${material.model ?? 'N/A'}',
                  style: AppTextStyles.bodySmall(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _materialNotesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Any observations or condition notes',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _completionStatusController,
                  decoration: InputDecoration(
                    labelText: 'Completion Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Completed, Partial, etc.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endMaterialSession(material);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
  }

  Future<void> _startMaterialSession(AssetItem material) async {
    try {
      final assetProvider = context.read<AssetProvider>();
      final response = await assetProvider.startUsageSession(
        assetId: material.id,
        startMileage: material.mileage ?? 0,
        startOperatingHours: material.operatingHours ?? 0,
        taskType: 'Farm Work',
        startTime: DateTime.now(),
        notes: 'Worker started using material',
      );

      if (!mounted) return;

      setState(() {
        _activeMaterialSession = response;
        _sessionStartTime = DateTime.now();
      });
      _startSessionTimer(DateTime.now());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Started using ${material.name}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _endMaterialSession(AssetItem material) async {
    try {
      final assetProvider = context.read<AssetProvider>();
      final activeSession = _activeMaterialSession;

      if (activeSession == null) {
        throw Exception('No active session');
      }

      await assetProvider.endUsageSession(
        usageLogId: activeSession['id']?.toString() ?? '',
        endMileage: material.mileage ?? 0,
        endOperatingHours: material.operatingHours ?? 0,
        fuelLevel: 0,
        conditionNote: _materialNotesController.text,
        endTime: DateTime.now(),
        returnConfirmation: true,
        notes: _completionStatusController.text,
      );

      if (!mounted) return;

      setState(() {
        _activeMaterialSession = null;
        _sessionStartTime = null;
      });
      _stopSessionTimer();
      _materialNotesController.clear();
      _completionStatusController.clear();

      await _loadFarmerDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${material.name} checked in successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_USE':
        return AppColors.warning;
      case 'MAINTENANCE':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }
}
