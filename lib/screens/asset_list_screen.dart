import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

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
    final asset = await provider.getByQrValue(qrValue);

    if (!mounted) return;

    if (asset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset not found for this QR code.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Asset Found', style: AppTextStyles.h4()),
        content: _AssetPreview(asset: asset),
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
                    (asset) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColorPalette.lightGrey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  asset.name,
                                  style: AppTextStyles.h4(),
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
                            style: AppTextStyles.bodyMedium(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Serial: ${asset.serialNumber}',
                            style: AppTextStyles.bodyMedium(),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            asset.assignedToName != null
                                ? 'Assigned To: ${asset.assignedToName}'
                                : 'Assigned To: Unassigned',
                            style: AppTextStyles.bodyMedium(),
                          ),
                          if (asset.lastServiceDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Last Service: ${DateFormat('dd MMM yyyy').format(asset.lastServiceDate!)}",
                              style: AppTextStyles.bodyMedium(),
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
  final _serialController = TextEditingController();
  String? _selectedCategory;
  XFile? _selectedImage;
  DateTime? _selectedDateTime;
  String? _assignedToId;
  String? _selectedFieldId;

  static const List<String> _categoryOptions = [
    'Machinery',
    'Drones',
    'Tools',
    'Vehicles',
    'Equipment',
    'Technology',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    super.dispose();
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

    final provider = context.read<AssetProvider>();
    final success = await provider.addAsset(
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      serialNumber: _serialController.text.trim(),
      imageUrl: _selectedImage != null ? _selectedImage!.path : '',
      assignedTo: _assignedToId,
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
                  Text('Add Asset', style: AppTextStyles.h3()),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'e.g., DJI Agras T40',
                    label: 'Asset Name',
                    validator: (v) => Validators.required(v, 'Asset name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
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
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _serialController,
                    hintText: 'Unique serial number',
                    label: 'Serial Number',
                    validator: (v) => Validators.required(v, 'Serial number'),
                  ),
                  const SizedBox(height: 12),
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
                    onChanged: (value) {
                      setState(() => _selectedFieldId = value);
                    },
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
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _assignedToId,
                    decoration: InputDecoration(
                      labelText: 'Assign To Staff',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...provider.staffOptions.map(
                        (staff) => DropdownMenuItem<String?>(
                          value: staff['id']?.toString(),
                          child: Text(staff['name']?.toString() ?? 'Unknown'),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _assignedToId = value);
                    },
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
  const _AssetPreview({required this.asset});

  final AssetItem asset;

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
