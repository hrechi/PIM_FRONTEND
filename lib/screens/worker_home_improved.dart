import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/asset_item.dart';
import '../models/animal.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import '../services/animal_service.dart';
import '../services/api_service.dart';
import '../screens/mechanic_chat_screen.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/asset_image_utils.dart';
import '../widgets/app_drawer.dart';
import 'profile_screen.dart';
import 'signin_screen.dart';

class WorkerHomeImproved extends StatefulWidget {
  const WorkerHomeImproved({super.key});

  @override
  State<WorkerHomeImproved> createState() => _WorkerHomeImprovedState();
}

class _WorkerHomeImprovedState extends State<WorkerHomeImproved> {
  final AnimalService _animalService = AnimalService();

  List<AssetItem> _assignedAssets = [];
  List<Animal> _animals = [];
  bool _isLoading = true;
  String? _error;
  AssetItem? _activeAsset;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  String? _selectedStartAssetId;

  int _activeSessionsCount = 0;
  int _assignedAssetsCount = 0;
  int _animalsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDashboard());
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final assetProvider = context.read<AssetProvider>();
      final auth = context.read<AuthProvider>();
      
      await assetProvider.fetchAssets();

      if (!mounted) return;

      final activeSession = assetProvider.activeUsageSession;
      final assignedAssets = assetProvider.assets
          .where((asset) => asset.status != 'MAINTENANCE')
          .toList();

      List<Animal> animals = [];
      try {
        animals = await _animalService.getAnimals(
          fieldId: auth.user?.assignedFieldId,
        );
      } catch (e) {
        debugPrint('Error loading animals: $e');
      }

      AssetItem? activeAsset;
      DateTime? startTime;

      if (activeSession != null) {
        final assetId = activeSession['assetId']?.toString();
        try {
          activeAsset = assignedAssets.firstWhere(
            (a) => a.id == assetId,
          );
        } catch (e) {
          activeAsset = null;
        }
        startTime = DateTime.tryParse(activeSession['startTime']?.toString() ?? '');
        if (startTime != null) {
          _startSessionTimer(startTime);
        }
      } else {
        try {
          // Fallback for worker reload: if backend says IN_USE, surface it.
          activeAsset = assignedAssets.firstWhere((a) => a.status == 'IN_USE');
        } catch (_) {
          activeAsset = null;
        }
      }

      setState(() {
        _assignedAssets = assignedAssets;
        _animals = animals;
        _activeAsset = activeAsset;
        _sessionStartTime = startTime;
        _activeSessionsCount = assignedAssets.where((a) => a.status == 'IN_USE').length;
        _assignedAssetsCount = assignedAssets.length;
        _animalsCount = animals.length;
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

  Future<void> _showAssetHistory(AssetItem asset) async {
    final provider = context.read<AssetProvider>();
    if (!provider.assetHistoryById.containsKey(asset.id)) {
      try {
        await provider.fetchAssetHistory(asset.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
        return;
      }
    }

    if (!mounted) return;

    final history =
        (provider.assetHistoryById[asset.id]?['history'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine History', style: AppTextStyles.h3()),
                const SizedBox(height: 4),
                Text('${asset.brand} - ${asset.name}', style: AppTextStyles.caption()),
                const SizedBox(height: 12),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text(
                            'No history yet for this machine',
                            style: AppTextStyles.bodySmall(),
                          ),
                        )
                      : ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final item = history[index];
                            final started = DateTime.tryParse(
                              item['startTime']?.toString() ?? '',
                            );
                            final ended = DateTime.tryParse(
                              item['endTime']?.toString() ?? '',
                            );

                            final details = <String>[
                              item['notes']?.toString() ?? '',
                              item['issues']?.toString() ?? '',
                              item['maintenanceNote']?.toString() ?? '',
                            ]..removeWhere((d) => d.trim().isEmpty);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item['farmerName'] ?? 'Worker'} • ${item['condition'] ?? 'N/A'}',
                                    style: AppTextStyles.bodySmall().copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${started != null ? DateFormat('dd MMM yyyy, HH:mm').format(started) : '-'} -> ${ended != null ? DateFormat('dd MMM yyyy, HH:mm').format(ended) : 'in progress'}',
                                    style: AppTextStyles.caption(),
                                  ),
                                  if (details.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(details.join(' | '), style: AppTextStyles.caption()),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
  }

  String _formatElapsed(DateTime start) {
    final duration = DateTime.now().difference(start);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _signOut() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _startSession(AssetItem asset) async {
    if (!mounted) return;
    final previewStart = DateTime.now();
    Timer? previewTimer;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: AppColorPalette.charcoalGreen,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          previewTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
            if (ctx.mounted) {
              setModalState(() {});
            }
          });

          final now = DateTime.now();
          final elapsed = now.difference(previewStart);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C2A39), Color(0xFF2C3E50)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      asset.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${asset.brand}${asset.model != null ? ' • ${asset.model}' : ''}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(color: Colors.white70),
                    ),
                    if (asset.fieldName != null && asset.fieldName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Field: ${asset.fieldName}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColorPalette.robotTechEnd.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColorPalette.robotTechEnd.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _formatDuration(elapsed),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${DateFormat('h:mma').format(previewStart)}  →  ${DateFormat('h:mma').format(now)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Live free timer • no fixed duration',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Start session timer'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorPalette.robotTechEnd,
                        foregroundColor: AppColorPalette.charcoalGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final modalNavigator = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await context.read<AssetProvider>().startUsageSession(
                                assetId: asset.id,
                              );
                          if (!mounted) return;
                          modalNavigator.pop();
                          _loadDashboard();
                          messenger.showSnackBar(
                            SnackBar(content: Text('Started using ${asset.name}')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      previewTimer?.cancel();
    });
  }

  Future<void> _checkIn(AssetItem asset) async {
    final distance = TextEditingController();
    final notes = TextEditingController();
    String condition = 'GOOD';

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Check In Equipment', style: AppTextStyles.h3()),
              const SizedBox(height: 4),
              Text(asset.name, style: AppTextStyles.bodySmall()),
              const SizedBox(height: 16),
              TextField(
                controller: distance,
                decoration: InputDecoration(
                  labelText: 'Distance Traveled (km) - Required',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Text('Equipment Condition', style: AppTextStyles.bodySmall()),
              const SizedBox(height: 8),
              Row(
                children: [
                  _conditionChip('GOOD', condition, Colors.green, () {
                    setState(() => condition = 'GOOD');
                  }),
                  const SizedBox(width: 8),
                  _conditionChip('WARNING', condition, Colors.orange, () {
                    setState(() => condition = 'WARNING');
                  }),
                  const SizedBox(width: 8),
                  _conditionChip('CRITICAL', condition, Colors.red, () {
                    setState(() => condition = 'CRITICAL');
                  }),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                decoration: InputDecoration(
                  labelText: 'Issues/Notes - Optional',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Check In'),
                  onPressed: () async {
                    final modalNavigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    if (distance.text.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter distance'),
                        ),
                      );
                      return;
                    }

                    try {
                      await context.read<AssetProvider>().endUsageSession(
                            assetId: asset.id,
                            distanceKm: double.tryParse(distance.text) ?? 0,
                            condition: condition,
                            issues: notes.text.isEmpty ? null : notes.text,
                            maintenanceNote:
                                notes.text.isEmpty ? null : notes.text,
                          );
                      if (!mounted) return;
                      modalNavigator.pop();
                      _stopSessionTimer();
                      _loadDashboard();
                      messenger.showSnackBar(
                        SnackBar(content: Text('Checked in ${asset.name}')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    distance.dispose();
    notes.dispose();
  }

  Widget _conditionChip(String label, String current, Color color,
      VoidCallback onTap) {
    final isSelected = label == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'Worker';

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('My Equipment'),
        backgroundColor: AppColorPalette.wheatWarmClay,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MechanicChatScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text(
                    'Hello, $userName',
                    style: AppTextStyles.h2(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back to your dashboard',
                    style: AppTextStyles.bodySmall(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Stats (reordered to match worker UI)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCardWithIcon(
                          'Available',
                          _assignedAssetsCount.toString(),
                          Icons.handyman,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCardWithIcon(
                          'Animals',
                          _animalsCount.toString(),
                          Icons.pets,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCardWithIcon(
                          'Active',
                          _activeSessionsCount.toString(),
                          Icons.timer,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Large action buttons (Control Room / Skill Certification)
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // navigate to control room (placeholder)
                          },
                          icon: const Icon(Icons.monitor_heart),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Control Room', style: TextStyle(fontSize: 16)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorPalette.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            // navigate to skill certification (placeholder)
                          },
                          icon: const Icon(Icons.workspace_premium),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Skill Certification', style: TextStyle(fontSize: 16)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorPalette.charcoalGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Using Material row (dropdown + start button)
                  Text('Start Using Material', style: AppTextStyles.h3()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedStartAssetId,
                          items: _assignedAssets
                              .map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedStartAssetId = v),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'Select material...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _selectedStartAssetId == null
                            ? null
                            : () {
                                final asset = _assignedAssets.firstWhere((a) => a.id == _selectedStartAssetId);
                                _startSession(asset);
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                          child: Text('Start'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorPalette.charcoalGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(height: 20),

                  // Active Session Card
                  if (_activeAsset != null && _sessionStartTime != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColorPalette.success.withValues(alpha: 0.9),
                            AppColorPalette.success,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Session',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 8),
                          Text(_formatElapsed(_sessionStartTime!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 8),
                          Text(_activeAsset!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _checkIn(_activeAsset!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                              child: const Text('Check In Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Equipment Section
                  Text('My Equipment', style: AppTextStyles.h3()),
                  const SizedBox(height: 12),
                  if (_assignedAssets.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('No equipment assigned'),
                      ),
                    )
                  else
                    ..._assignedAssets.map((asset) {
                      return _buildAssetCard(asset);
                    }),

                  // Animals Section
                  if (_animals.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Farm Animals', style: AppTextStyles.h3()),
                    const SizedBox(height: 12),
                    ..._animals.take(3).map((animal) => _buildAnimalCard(animal)),
                    if (_animals.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+${_animals.length - 3} more animals',
                          style: AppTextStyles.caption(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                      ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_error!,
                                style: AppTextStyles.bodySmall()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  


  Widget _buildStatCardWithIcon(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.caption(color: AppColorPalette.softSlate)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildAssetCard(AssetItem asset) {
    final imageProvider = resolveAssetImageProvider(
      asset.imageUrl,
      mediaBaseUrl: ApiService.mediaBaseUrl,
    );
    final hasImage = imageProvider != null;
    final isInUse = asset.status == 'IN_USE';
    final isCurrentWorkerActive = asset.id == _activeAsset?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInUse ? AppColorPalette.success : Colors.grey[300]!,
          width: isInUse ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image(
                image: imageProvider,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
              ),
            )
          else
            _imagePlaceholder(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(asset.name,
                              style: AppTextStyles.h4(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(asset.brand,
                              style: AppTextStyles.caption(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (asset.fieldName != null &&
                              asset.fieldName!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Field: ${asset.fieldName}',
                                style: AppTextStyles.caption()),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInUse
                            ? AppColorPalette.success.withValues(alpha: 0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isInUse ? 'In Use' : 'Available',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isInUse
                              ? AppColorPalette.success
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mileage: ${asset.mileage?.toStringAsFixed(0) ?? '-'}', style: AppTextStyles.caption()),
                        const SizedBox(height: 6),
                        Text('Hours: ${asset.operatingHours?.toStringAsFixed(1) ?? '-'}', style: AppTextStyles.caption()),
                        const SizedBox(height: 6),
                        Text(
                          'Last service: ${asset.lastServiceDate != null ? DateFormat('dd MMM yyyy').format(asset.lastServiceDate!) : 'Not set'}',
                          style: AppTextStyles.caption(),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: isInUse
                              ? (isCurrentWorkerActive ? () => _checkIn(asset) : null)
                              : () => _startSession(asset),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isInUse ? Colors.orange : AppColorPalette.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(isInUse ? 'In Use' : 'Start Using'),
                        ),
                        IconButton(
                          onPressed: () {
                            _showAssetHistory(asset);
                          },
                          icon: const Icon(Icons.history),
                          tooltip: 'Machine history',
                        ),
                      ],
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

  Widget _buildAnimalCard(Animal animal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.pets, color: Colors.blue, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  animal.name,
                  style: AppTextStyles.bodyMedium(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  animal.breed ?? 'No breed info',
                  style: AppTextStyles.caption(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(Icons.construction, size: 40, color: Colors.grey[400]),
      ),
    );
  }
}
