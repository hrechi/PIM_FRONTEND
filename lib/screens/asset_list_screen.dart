import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import 'asset_deep_dive_screen.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/asset_suggest_field.dart';
import '../services/asset_ai_service.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final provider = context.read<AssetProvider>();
    provider.fetchAssets();
    provider.fetchStaffOptions();
    provider.fetchFieldOptions();
  }

  Future<void> _openAddAssetForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAssetSheet(),
    );
  }

  Future<void> _scanQrAndFetchAsset() async {
    final qrValue = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerScreen()));

    if (!mounted || qrValue == null || qrValue.isEmpty) return;

    final provider = context.read<AssetProvider>();
    final result = await provider.getByQrValue(qrValue);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset not found for this QR code.')),
      );
      return;
    }

    final asset = result['asset'] as AssetItem;
    final aiMessage = result['aiMessage']?.toString() ?? '';

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Asset Found', style: AppTextStyles.h4()),
        content: _AssetPreview(asset: asset, aiMessage: aiMessage),
      ),
    );
  }

  Widget _brandBadge(String brand) {
    final lower = brand.toLowerCase();
    IconData icon = Icons.agriculture;

    if (lower.contains('caterpillar')) icon = Icons.construction;
    if (lower.contains('claas')) icon = Icons.precision_manufacturing;
    if (lower.contains('kubota')) icon = Icons.local_shipping;
    if (lower.contains('mitsubishi')) icon = Icons.directions_car;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColorPalette.charcoalGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColorPalette.charcoalGreen),
          const SizedBox(width: 6),
          Text(
            brand,
            style: AppTextStyles.caption(color: AppColorPalette.charcoalGreen),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_USE':
        return AppColors.warning;
      case 'MAINTENANCE':
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  void _showQrCode(AssetItem asset) {
    print('🔍 QR Code button tapped for asset: ${asset.name}');
    print('📱 Serial Number: ${asset.serialNumber}');

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asset QR Code', style: AppTextStyles.h4()),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: asset.serialNumber.isNotEmpty
                        ? asset.serialNumber
                        : asset.id,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  asset.name,
                  style: AppTextStyles.h4(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Serial: ${asset.serialNumber}',
                  style: AppTextStyles.bodySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(dialogContext),
                  backgroundColor: AppColors.success,
                  width: 120,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          'Asset Inventory',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQrAndFetchAsset,
        backgroundColor: AppColors.mistyBlue,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        label: Text(
          'Scan QR',
          style: AppTextStyles.buttonMedium(color: Colors.white),
        ),
      ),
      body: Consumer<AssetProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: provider.fetchAssets,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColorPalette.fieldFreshGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR-Based Asset & Tool Inventory',
                        style: AppTextStyles.h4(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${provider.assets.length} assets tracked',
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CustomButton(
                        text: 'Add Asset',
                        icon: Icons.add,
                        onPressed: _openAddAssetForm,
                        backgroundColor: Colors.white,
                        textColor: AppColors.mistyBlue,
                        width: 180,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.error!,
                      style: AppTextStyles.bodyMedium(color: AppColors.error),
                    ),
                  ),
                if (provider.isLoading && provider.assets.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.assets.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No assets yet. Add your first machinery, drone, or tool.',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  )
                else
                  ...provider.assets.map(
                    (asset) => InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AssetDeepDiveScreen(asset: asset),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF102218),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColorPalette.fieldFreshStart.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _brandBadge(asset.brand),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              asset.name,
                                              style: AppTextStyles.h4(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      asset.status,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    asset.status,
                                    style: AppTextStyles.caption(
                                      color: _statusColor(asset.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Category: ${asset.category}',
                              style: AppTextStyles.bodyMedium(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (asset.model != null && asset.model!.isNotEmpty)
                              Text(
                                'Model: ${asset.model}${asset.modelYear != null ? ' (${asset.modelYear})' : ''}',
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white70,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Serial: ${asset.serialNumber}',
                              style: AppTextStyles.bodyMedium(
                                color: Colors.white70,
                              ),
                            ),
                            if (asset.mileage != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Mileage: ${asset.mileage!.toStringAsFixed(0)} km',
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            if (asset.operatingHours != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Operating Hours: ${asset.operatingHours!.toStringAsFixed(0)} h',
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              asset.assignedToName != null
                                  ? 'Assigned To: ${asset.assignedToName}'
                                  : 'Assigned To: Unassigned',
                              style: AppTextStyles.bodyMedium(
                                color: Colors.white70,
                              ),
                            ),
                            if (asset.lastServiceDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Last Service: ${DateFormat('dd MMM yyyy').format(asset.lastServiceDate!)}",
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        text: 'QR Code',
                                        onPressed: () {
                                          _showQrCode(asset);
                                        },
                                        backgroundColor:
                                            AppColorPalette.emeraldGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CustomButton(
                                        text: 'In Use',
                                        onPressed: () {
                                          provider.updateAsset(
                                            assetId: asset.id,
                                            status: 'IN_USE',
                                          );
                                        },
                                        backgroundColor: AppColors.warning,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text: 'Available',
                                    onPressed: () {
                                      provider.updateAsset(
                                        assetId: asset.id,
                                        status: 'AVAILABLE',
                                      );
                                    },
                                    backgroundColor: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddAssetSheet extends StatefulWidget {
  const _AddAssetSheet();

  @override
  State<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<_AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _serialController = TextEditingController();
  String? _selectedCategory;
  XFile? _selectedImage;
  DateTime? _selectedDateTime;
  String? _selectedFieldId;

  // AI Suggestion states
  final AssetAiService _assetAiService = AssetAiService();
  Timer? _validationDebounce;
  List<String> _suggestedCategories = [];
  List<String> _suggestedUsages = [];
  List<String> _suggestedModels = [];
  Map<String, dynamic>? _liveValidation;
  bool _isLiveValidating = false;

  static const List<String> _categoryOptions = [
    'Machinery',
    'Drones',
    'Tools',
    'Vehicles',
    'Equipment',
    'Technology',
    'Other',
  ];

  bool get _hideMileage {
    final category = (_selectedCategory ?? '').toLowerCase();
    return category == 'drones' ||
        category == 'technology' ||
        category == 'tools';
  }

  @override
  void initState() {
    super.initState();
    _brandController.addListener(_scheduleLiveValidation);
    _modelController.addListener(_scheduleLiveValidation);
    _nameController.addListener(_scheduleLiveValidation);
    _operatingHoursController.addListener(_scheduleLiveValidation);
    _mileageController.addListener(_scheduleLiveValidation);
  }

  String? _mapToCategoryOption(String rawCategory) {
    final value = rawCategory.toLowerCase();
    if (value.contains('drone')) return 'Drones';
    if (value.contains('tractor') ||
        value.contains('harvest') ||
        value.contains('machin')) {
      return 'Machinery';
    }
    if (value.contains('vehicle') || value.contains('truck')) return 'Vehicles';
    if (value.contains('tool')) return 'Tools';
    if (value.contains('sensor') || value.contains('tech')) return 'Technology';
    if (value.contains('equip')) return 'Equipment';
    return _categoryOptions.contains(rawCategory) ? rawCategory : null;
  }

  void _applyAiSuggestions({
    required List<String> categories,
    required List<String> usages,
    List<String> models = const [],
  }) {
    String? mappedCategory;
    for (final category in categories) {
      final mapped = _mapToCategoryOption(category);
      if (mapped != null) {
        mappedCategory = mapped;
        break;
      }
    }

    setState(() {
      _suggestedCategories = categories;
      _suggestedUsages = usages;
      _suggestedModels = models;
      if (mappedCategory != null) {
        _selectedCategory = mappedCategory;
      }
    });

    _scheduleLiveValidation();
  }

  @override
  void dispose() {
    _validationDebounce?.cancel();
    _brandController.removeListener(_scheduleLiveValidation);
    _modelController.removeListener(_scheduleLiveValidation);
    _nameController.removeListener(_scheduleLiveValidation);
    _operatingHoursController.removeListener(_scheduleLiveValidation);
    _mileageController.removeListener(_scheduleLiveValidation);
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _modelYearController.dispose();
    _mileageController.dispose();
    _operatingHoursController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  void _scheduleLiveValidation() {
    _validationDebounce?.cancel();
    _validationDebounce = Timer(const Duration(milliseconds: 450), () {
      _runLiveValidation();
    });
  }

  Future<void> _runLiveValidation() async {
    if ((_brandController.text.trim()).isEmpty ||
        (_nameController.text.trim()).isEmpty) {
      return;
    }

    setState(() => _isLiveValidating = true);

    try {
      final result = await _assetAiService.validateAsset({
        'name': _nameController.text.trim(),
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim().isEmpty
            ? null
            : _modelController.text.trim(),
        'category': _selectedCategory,
        'type': _selectedCategory,
        'operatingHours': double.tryParse(
          _operatingHoursController.text.trim(),
        ),
        'horsepower': double.tryParse(_operatingHoursController.text.trim()),
        'mileage': double.tryParse(_mileageController.text.trim()),
        'usage': double.tryParse(_mileageController.text.trim()),
      });

      if (!mounted) return;
      setState(() {
        _liveValidation = result;
        _isLiveValidating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLiveValidating = false);
    }
  }

  Widget _buildSectionCard({
    required Color color,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColorPalette.charcoalGreen),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h4()),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    if (mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
      );

      if (time != null) {
        setState(
          () => _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a field.')));
      return;
    }

    // --- AI Validation Step ---
    final aiPayload = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory!,
      'type': _selectedCategory!,
      'operatingHours': double.tryParse(_operatingHoursController.text.trim()),
      'horsepower': double.tryParse(_operatingHoursController.text.trim()),
      'mileage': double.tryParse(_mileageController.text.trim()),
      'usage': double.tryParse(_mileageController.text.trim()),
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      'modelYear': int.tryParse(_modelYearController.text.trim()),
    };
    String aiStatus = 'valid';
    String aiMessage = '';
    List<dynamic> aiIssues = [];
    List<dynamic> aiWarnings = [];
    List<dynamic> aiSuggestions = [];
    try {
      final assetAiService = AssetAiService();
      final aiResult = await assetAiService.validateAsset(aiPayload);
      if (aiResult['valid'] == false) {
        aiStatus = 'invalid';
        aiIssues = aiResult['issues'] ?? [];
        aiWarnings = aiResult['warnings'] ?? [];
        aiSuggestions = aiResult['suggestions'] ?? [];
      } else if ((aiResult['warnings'] as List?)?.isNotEmpty ?? false) {
        aiStatus = 'warning';
        aiWarnings = aiResult['warnings'] ?? [];
        aiSuggestions = aiResult['suggestions'] ?? [];
      } else if ((aiResult['confidence'] ?? 1.0) < 0.7) {
        aiStatus = 'warning';
        aiIssues = aiResult['issues'] ?? [];
        aiWarnings = aiResult['warnings'] ?? [];
        aiSuggestions = aiResult['suggestions'] ?? [];
      }
    } catch (e) {
      aiStatus = 'warning';
      aiMessage = 'AI validation unavailable. Proceeding with caution.';
    }

    // Show dialog if not valid
    if (aiStatus == 'invalid' || aiStatus == 'warning') {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            aiStatus == 'invalid'
                ? '❌ Invalid Asset Data'
                : '⚠️ Asset Data Warning',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (aiMessage.isNotEmpty) Text(aiMessage),
              if (aiIssues.isNotEmpty) ...[
                const Text(
                  'Issues:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...aiIssues.map((e) => Text('- $e')).toList(),
              ],
              if (aiWarnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Warnings:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...aiWarnings.map((e) => Text('- $e')).toList(),
              ],
              if (aiSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Suggestions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...aiSuggestions.map((e) => Text('- $e')).toList(),
              ],
            ],
          ),
          actions: [
            if (aiStatus == 'warning')
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Proceed Anyway'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    // --- Proceed to submit asset ---
    final provider = context.read<AssetProvider>();
    final success = await provider.addAsset(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      category: _selectedCategory!,
      serialNumber: _serialController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      modelYear: int.tryParse(_modelYearController.text.trim()),
      mileage: double.tryParse(_mileageController.text.trim()),
      operatingHours: double.tryParse(_operatingHoursController.text.trim()),
      imageUrl: _selectedImage != null ? _selectedImage!.path : '',
      lastServiceDate: _selectedDateTime,
      fieldId: _selectedFieldId!,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset added successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssetProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Add Asset', style: AppTextStyles.h3()),
                      ),
                      const Icon(Icons.smart_toy_outlined, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _isLiveValidating
                          ? Colors.blue.withValues(alpha: 0.08)
                          : (_liveValidation == null
                                ? Colors.grey.withValues(alpha: 0.08)
                                : ((_liveValidation?['valid'] == true)
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1))),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        if (_isLiveValidating)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Icon(
                            _liveValidation == null
                                ? Icons.info_outline
                                : ((_liveValidation?['valid'] == true)
                                      ? Icons.verified
                                      : Icons.warning_amber_rounded),
                            color: _liveValidation == null
                                ? Colors.blueGrey
                                : ((_liveValidation?['valid'] == true)
                                      ? Colors.green
                                      : Colors.orange),
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLiveValidating
                                ? 'AI is validating inputs...'
                                : (_liveValidation == null
                                      ? 'Start filling brand/model for AI guidance.'
                                      : ((_liveValidation?['valid'] == true)
                                            ? 'Looks coherent so far.'
                                            : 'Please review warnings before submit.')),
                            style: AppTextStyles.bodySmall(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSectionCard(
                    color: const Color(0xFFEFF8F2),
                    icon: Icons.account_tree_outlined,
                    title: 'Basic Info',
                    children: [
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'e.g., DJI Agras T40',
                        label: 'Asset Name',
                        validator: (v) => Validators.required(v, 'Asset name'),
                      ),
                      const SizedBox(height: 10),
                      AssetSuggestField(
                        label: 'Brand',
                        helperText: 'AI powered brand suggestions',
                        controller: _brandController,
                        fieldType: 'brand',
                        required: true,
                        categoryValue: _selectedCategory,
                        onModelSuggestions: (models) {
                          setState(() => _suggestedModels = models);
                        },
                        onCategorySuggestions: (categories) {
                          _applyAiSuggestions(
                            categories: categories,
                            usages: _suggestedUsages,
                            models: _suggestedModels,
                          );
                        },
                        onUsageSuggestions: (usages) {
                          _applyAiSuggestions(
                            categories: _suggestedCategories,
                            usages: usages,
                            models: _suggestedModels,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AssetSuggestField(
                        label: 'Model',
                        helperText: _selectedCategory == null
                            ? 'Pick a category to refine models'
                            : 'Filtered by ${_selectedCategory!}',
                        controller: _modelController,
                        fieldType: 'model',
                        categoryValue: _selectedCategory,
                        brandValue: _brandController.text.trim(),
                        onModelSuggestions: (models) {
                          setState(() => _suggestedModels = models);
                        },
                        onCategorySuggestions: (categories) {
                          _applyAiSuggestions(
                            categories: categories,
                            usages: _suggestedUsages,
                            models: _suggestedModels,
                          );
                        },
                        onUsageSuggestions: (usages) {
                          _applyAiSuggestions(
                            categories: _suggestedCategories,
                            usages: usages,
                            models: _suggestedModels,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _suggestedModels.isEmpty
                            ? const SizedBox.shrink()
                            : Wrap(
                                key: ValueKey(_suggestedModels.join(',')),
                                spacing: 8,
                                runSpacing: 8,
                                children: _suggestedModels
                                    .take(5)
                                    .map(
                                      (m) => ActionChip(
                                        label: Text(m),
                                        onPressed: () => setState(
                                          () => _modelController.text = m,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),

                  _buildSectionCard(
                    color: const Color(0xFFEFF5FF),
                    icon: Icons.tune,
                    title: 'Smart Details',
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          helperText: 'Auto-filled by AI, but editable',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null) return 'Please select a category';
                          return null;
                        },
                        items: _categoryOptions
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                          _scheduleLiveValidation();
                        },
                      ),
                      if (_suggestedCategories.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestedCategories
                              .take(4)
                              .map(
                                (c) => Chip(
                                  label: Text(c),
                                  backgroundColor: const Color(0xFFDDEBFF),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _modelYearController,
                              hintText: 'e.g. 2020',
                              label: 'Model Year',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              controller: _operatingHoursController,
                              hintText: 'Hours',
                              label: 'Operating Hours',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (!_hideMileage) ...[
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _mileageController,
                          hintText: 'KM',
                          label: 'Mileage (optional)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                      if (_suggestedUsages.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Wrap(
                            key: ValueKey(_suggestedUsages.join(',')),
                            spacing: 8,
                            runSpacing: 8,
                            children: _suggestedUsages
                                .take(5)
                                .map(
                                  (u) => Chip(
                                    label: Text(u),
                                    backgroundColor: const Color(0xFFE8F6EF),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ],
                  ),

                  _buildSectionCard(
                    color: const Color(0xFFF6F0FF),
                    icon: Icons.assignment_ind_outlined,
                    title: 'Assignment',
                    children: [
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedFieldId,
                        decoration: InputDecoration(
                          labelText: 'Select Field',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a field';
                          }
                          return null;
                        },
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Choose a field...'),
                          ),
                          ...provider.fieldOptions.map(
                            (field) => DropdownMenuItem<String?>(
                              value: field['id']?.toString(),
                              child: Text(
                                field['name']?.toString() ?? 'Unknown Field',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedFieldId = value),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Worker assignment is optional and can be done later.',
                        style: AppTextStyles.bodySmall(
                          color: AppColorPalette.softSlate,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _serialController,
                        hintText: 'Unique serial number',
                        label: 'Serial Number',
                        validator: (v) =>
                            Validators.required(v, 'Serial number'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Material(
                    child: InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asset Image',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColorPalette.softSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedImage?.name ??
                                        'Tap to upload image',
                                    style: AppTextStyles.bodyMedium(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.photo_library),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    child: InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Service Date & Time',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColorPalette.softSlate,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDateTime != null
                                        ? DateFormat(
                                            'dd MMM yyyy • HH:mm',
                                          ).format(_selectedDateTime!)
                                        : 'Tap to select date & time (optional)',
                                    style: AppTextStyles.bodyMedium(),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Create Asset',
                    onPressed: _submit,
                    isLoading: provider.isLoading,
                    gradient: AppColors.fieldFreshGradient,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssetPreview extends StatelessWidget {
  const _AssetPreview({required this.asset, required this.aiMessage});

  final AssetItem asset;
  final String aiMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(asset.name, style: AppTextStyles.h4()),
        const SizedBox(height: 8),
        Text('ID: ${asset.id}', style: AppTextStyles.bodySmall()),
        Text('Category: ${asset.category}', style: AppTextStyles.bodyMedium()),
        Text('Brand: ${asset.brand}', style: AppTextStyles.bodyMedium()),
        if (asset.mileage != null)
          Text(
            'Mileage: ${asset.mileage!.toStringAsFixed(0)} km',
            style: AppTextStyles.bodyMedium(),
          ),
        Text('Status: ${asset.status}', style: AppTextStyles.bodyMedium()),
        Text(
          'Serial: ${asset.serialNumber}',
          style: AppTextStyles.bodyMedium(),
        ),
        if (asset.fieldName != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Field: ${asset.fieldName}',
              style: AppTextStyles.bodyMedium(),
            ),
          ),
        if (aiMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              aiMessage,
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.charcoalGreen,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _detected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Asset QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_detected) return;
              final code = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first.rawValue
                  : null;
              if (code == null || code.isEmpty) return;
              _detected = true;
              Navigator.of(context).pop(code);
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Align the QR code to fetch asset by ID',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
