import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import '../providers/auth_provider.dart';
import 'asset_deep_dive_screen.dart';
import 'worker_assistant_screen.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/asset_suggest_field.dart';
import '../services/asset_ai_service.dart';
import '../services/api_service.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key, this.focusAssetId});

  final String? focusAssetId;

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  bool _initialized = false;
  Timer? _refreshTimer;
  bool _focusAssetOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final provider = context.read<AssetProvider>();
    provider.fetchAssets();
    provider.fetchStaffOptions();
    provider.fetchFieldOptions();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      context.read<AssetProvider>().fetchAssets();
    });

    if (widget.focusAssetId != null && widget.focusAssetId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFocusedAssetIfAvailable();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _openAddAssetForm() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddAssetSheet(),
    );
  }

  Future<void> _openFocusedAssetIfAvailable() async {
    if (_focusAssetOpened) return;
    final focusAssetId = widget.focusAssetId;
    if (focusAssetId == null || focusAssetId.isEmpty) return;

    final provider = context.read<AssetProvider>();
    final navigator = Navigator.of(context);
    await provider.fetchAssets();
    if (!mounted || _focusAssetOpened) return;

    final asset = provider.assets
        .where((item) => item.id == focusAssetId)
        .toList();
    if (asset.isEmpty) {
      return;
    }

    _focusAssetOpened = true;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => AssetDeepDiveScreen(asset: asset.first),
      ),
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

  Widget _buildAssetActionButton(AssetItem asset) {
    final authProvider = context.read<AuthProvider>();
    final isWorker =
        authProvider.user?.role == 'WORKER' ||
        authProvider.user?.role == 'FARMER';
    final provider = context.watch<AssetProvider>();
    final isSessionLoading = provider.isSessionActionLoading(asset.id);
    final currentWorkerId = authProvider.user?.staffId ?? authProvider.user?.id;
    final activeWorkerId = asset.activeUsageWorkerId;
    final predictive =
        provider.predictiveMaintenanceById[asset.id] as Map<String, dynamic>?;
    final maintenanceBlocked = predictive?['canUse'] == false;
    final isCurrentUserUsing =
        asset.isInUse &&
        currentWorkerId != null &&
        activeWorkerId == currentWorkerId;
    final isOtherUserUsing =
        asset.isInUse &&
        activeWorkerId != null &&
        activeWorkerId != currentWorkerId;

    if (isWorker) {
      if (!asset.isInUse && maintenanceBlocked) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '⚠ Machine requires maintenance before use',
              style: AppTextStyles.caption(color: const Color(0xFFE3A77B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            CustomButton(
              text: 'Maintenance Required',
              onPressed: null,
              backgroundColor: Colors.red.shade400,
              isLoading: isSessionLoading,
            ),
          ],
        );
      }

      return CustomButton(
        text: asset.isInUse
            ? (isCurrentUserUsing ? 'Finish Using' : 'In Use')
            : 'Start Using',
        onPressed: isSessionLoading
            ? null
            : isOtherUserUsing
            ? null
            : () async {
                try {
                  if (asset.isInUse) {
                    final ended = await _showEndSessionCheckoutDialog(
                      asset,
                      provider,
                    );
                    if (!ended) return;
                  } else {
                    await provider.startUsageSession(assetId: asset.id);
                  }
                  await provider.fetchAssets();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        asset.isInUse
                            ? 'Finished using ${asset.name}'
                            : 'Started using ${asset.name}',
                      ),
                      backgroundColor: const Color(0xFF61C06F),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      action: asset.isInUse && isCurrentUserUsing
                          ? SnackBarAction(
                              label: 'Retry',
                              textColor: Colors.white,
                              onPressed: () async {
                                if (!mounted) return;
                                await _showEndSessionCheckoutDialog(
                                  asset,
                                  provider,
                                );
                              },
                            )
                          : null,
                    ),
                  );
                }
              },
        backgroundColor: asset.isInUse
            ? (isCurrentUserUsing ? const Color(0xFFE3A77B) : Colors.grey)
            : const Color(0xFF61C06F),
        isLoading: isSessionLoading,
      );
    } else {
      final provider = context.read<AssetProvider>();
      return CustomButton(
        text: asset.status == 'IN_USE' ? 'Mark Available' : 'Mark In Use',
        onPressed: () async {
          await provider.updateAsset(
            assetId: asset.id,
            status: asset.status == 'IN_USE' ? 'AVAILABLE' : 'IN_USE',
          );
          await provider.fetchAssets();
        },
        backgroundColor: asset.status == 'IN_USE'
            ? const Color(0xFF61C06F)
            : Colors.orange,
      );
    }
  }

  String _currentWorkerId(AuthProvider authProvider) {
    return authProvider.user?.staffId ?? authProvider.user?.id ?? '';
  }

  bool _isWorkerView(AuthProvider authProvider) {
    return authProvider.user?.role == 'WORKER' ||
        authProvider.user?.role == 'FARMER';
  }

  bool _isCurrentUserUsingAsset(AssetItem asset, AuthProvider authProvider) {
    final workerId = _currentWorkerId(authProvider);
    return asset.isInUse &&
        workerId.isNotEmpty &&
        asset.activeUsageWorkerId == workerId;
  }

  Color _conditionColor(String? condition) {
    switch (condition?.toUpperCase()) {
      case 'WARNING':
        return const Color(0xFFD9822B);
      case 'CRITICAL':
        return const Color(0xFFC83E4D);
      default:
        return Colors.transparent;
    }
  }

  String _conditionLabel(String? condition) {
    switch (condition?.toUpperCase()) {
      case 'WARNING':
        return 'Warning';
      case 'CRITICAL':
        return 'Critical';
      default:
        return '';
    }
  }

  Widget _availabilityBadge(AssetItem asset) {
    if (asset.hasAvailabilityWarning) {
      final color = _conditionColor(asset.usageCondition);
      return _pill(
        '⚠️ ${_conditionLabel(asset.usageCondition)}',
        backgroundColor: color.withValues(alpha: 0.16),
        textColor: color,
      );
    }

    final statusColor = _statusColor(asset.status);
    return _pill(
      asset.status == 'IN_USE' ? '🔴 In use' : '🟢 Available',
      backgroundColor: statusColor.withValues(alpha: 0.16),
      textColor: statusColor,
    );
  }

  Widget _usageBanner(AssetItem asset, AuthProvider authProvider) {
    if (!asset.isInUse) return const SizedBox.shrink();

    final isCurrentUserUsing = _isCurrentUserUsingAsset(asset, authProvider);
    final whoIsUsing = asset.activeUsageWorkerName?.trim().isNotEmpty == true
        ? asset.activeUsageWorkerName!
        : (asset.activeUsageWorkerId ?? 'Worker not synced yet');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            isCurrentUserUsing ? Icons.person_outline : Icons.people_outline,
            size: 18,
            color: Colors.white.withValues(alpha: 0.88),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isCurrentUserUsing
                  ? 'Currently used by you'
                  : 'Currently used by $whoIsUsing',
              style: AppTextStyles.caption(
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showEndSessionCheckoutDialog(
    AssetItem asset,
    AssetProvider provider,
  ) async {
    final distanceController = TextEditingController();
    final issuesController = TextEditingController();
    final maintenanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCondition = 'GOOD';
    bool isSubmitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EFE7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + bottomInset),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Finish & Save', style: AppTextStyles.h3()),
                        const SizedBox(height: 6),
                        Text(
                          '${asset.name}${asset.model != null && asset.model!.isNotEmpty ? ' • ${asset.model}' : ''}${asset.fieldName != null ? ' • ${asset.fieldName}' : ''}',
                          style: AppTextStyles.bodyMedium(
                            color: AppColorPalette.softSlate,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _workerSheetSectionTitle('Usage'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: distanceController,
                          label: 'Distance (km)',
                          hintText: 'Enter distance traveled',
                          prefixIcon: Icons.route,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final raw = value?.trim() ?? '';
                            if (raw.isEmpty) return 'Distance is required';
                            final parsed = double.tryParse(raw);
                            if (parsed == null) return 'Enter a valid number';
                            if (parsed < 0)
                              return 'Distance cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _workerSheetSectionTitle('Issues'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: issuesController,
                          label: 'Issues (Optional)',
                          hintText: 'Describe issues encountered',
                          prefixIcon: Icons.report_problem_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                        _workerSheetSectionTitle('Maintenance'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: maintenanceController,
                          label: 'Maintenance Note (Optional)',
                          hintText: 'Recommended maintenance actions',
                          prefixIcon: Icons.build_circle_outlined,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 14),
                        _workerSheetSectionTitle('Condition'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _conditionChip(
                              label: 'Good',
                              value: 'GOOD',
                              selectedValue: selectedCondition,
                              color: const Color(0xFF61C06F),
                              onTap: isSubmitting
                                  ? null
                                  : () => setLocalState(
                                      () => selectedCondition = 'GOOD',
                                    ),
                            ),
                            _conditionChip(
                              label: 'Warning',
                              value: 'WARNING',
                              selectedValue: selectedCondition,
                              color: const Color(0xFFE3A77B),
                              onTap: isSubmitting
                                  ? null
                                  : () => setLocalState(
                                      () => selectedCondition = 'WARNING',
                                    ),
                            ),
                            _conditionChip(
                              label: 'Critical',
                              value: 'CRITICAL',
                              selectedValue: selectedCondition,
                              color: const Color(0xFFC83E4D),
                              onTap: isSubmitting
                                  ? null
                                  : () => setLocalState(
                                      () => selectedCondition = 'CRITICAL',
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (formKey.currentState != null &&
                            !formKey.currentState!.validate())
                          const SizedBox.shrink(),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Finish & Save',
                            isLoading: isSubmitting,
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;

                                    setLocalState(() {
                                      isSubmitting = true;
                                    });

                                    try {
                                      final distance =
                                          double.tryParse(
                                            distanceController.text.trim(),
                                          ) ??
                                          0;

                                      await provider.endUsageSession(
                                        assetId: asset.id,
                                        distanceKm: distance,
                                        issues: issuesController.text.trim(),
                                        maintenanceNote: maintenanceController
                                            .text
                                            .trim(),
                                        condition: selectedCondition,
                                      );

                                      if (!dialogContext.mounted) return;
                                      Navigator.of(dialogContext).pop(true);
                                    } catch (_) {
                                      if (!dialogContext.mounted) return;
                                      setLocalState(() {
                                        isSubmitting = false;
                                      });
                                    }
                                  },
                            gradient: selectedCondition == 'CRITICAL'
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFC83E4D),
                                      Color(0xFFE06B74),
                                    ],
                                  )
                                : selectedCondition == 'WARNING'
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE3A77B),
                                      Color(0xFFF0C38A),
                                    ],
                                  )
                                : AppColors.fieldFreshGradient,
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
      },
    );

    distanceController.dispose();
    issuesController.dispose();
    maintenanceController.dispose();

    return result ?? false;
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

  Widget _assetImage({
    required AssetItem asset,
    required double size,
    BorderRadius? borderRadius,
  }) {
    final imageUrl = asset.imageUrl?.trim() ?? '';
    final radius = borderRadius ?? BorderRadius.circular(18);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF21382C), Color(0xFF0F1D16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
        ),
        child: imageUrl.isEmpty
            ? Image.asset('assets/images/maskot_chatbot.png', fit: BoxFit.cover)
            : Image.network(
                imageUrl.startsWith('http')
                    ? imageUrl
                    : '${ApiService.mediaBaseUrl}$imageUrl',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/maskot_chatbot.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Widget _workerSheetSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
    );
  }

  Widget _conditionChip({
    required String label,
    required String value,
    required String selectedValue,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isSelected = selectedValue == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onTap == null ? null : (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.18),
      backgroundColor: color.withValues(alpha: 0.08),
      labelStyle: AppTextStyles.bodySmall(
        color: isSelected ? color : AppColorPalette.charcoalGreen,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.32)),
    );
  }

  Widget _pill(String label, {Color? backgroundColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption(color: textColor ?? Colors.white),
      ),
    );
  }

  Widget _assetCard(AssetItem asset) {
    final authProvider = context.read<AuthProvider>();
    final isCurrentUserUsing = _isCurrentUserUsingAsset(asset, authProvider);
    final isOtherUserUsing = asset.isInUse && !isCurrentUserUsing;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AssetDeepDiveScreen(asset: asset)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFF173023), Color(0xFF0F1E17)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'asset-image-${asset.id}',
                    child: _assetImage(asset: asset, size: 92),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.precision_manufacturing_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            _brandBadge(asset.brand),
                            const Spacer(),
                            _availabilityBadge(asset),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          asset.name,
                          style: AppTextStyles.h4(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          asset.model != null && asset.model!.isNotEmpty
                              ? '${asset.category} · ${asset.model}${asset.modelYear != null ? ' · ${asset.modelYear}' : ''}'
                              : asset.category,
                          style: AppTextStyles.bodyMedium(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _usageBanner(asset, authProvider),
                        if (asset.hasAvailabilityWarning) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Condition requires attention',
                            style: AppTextStyles.caption(
                              color: const Color(0xFFF2B35D),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    'Serial ${asset.serialNumber}',
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                  _pill(
                    'Category ${asset.category}',
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                  if (asset.fieldName != null)
                    _pill(
                      'Field ${asset.fieldName}',
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  if (asset.assignedToName != null)
                    _pill(
                      'Assigned ${asset.assignedToName}',
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  if (asset.lastServiceDate != null)
                    _pill(
                      'Serviced ${DateFormat('dd MMM').format(asset.lastServiceDate!)}',
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'QR Code',
                      onPressed: () => _showQrCode(asset),
                      backgroundColor: const Color(0xFF2F8ED1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildAssetActionButton(asset)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkerAssistantScreen(
                          assetId: asset.id,
                          assetBrand: asset.brand,
                          assetModel: asset.model,
                          assetCategory: asset.category,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Ask AI Assistant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              if (isOtherUserUsing) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'This machine is already being used by another worker.',
                    style: AppTextStyles.caption(
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AssetDeepDiveScreen(asset: asset),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Open details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
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
    );
  }

  Widget _overviewCard(AssetProvider provider) {
    int available = 0;
    int inUse = 0;
    int warning = 0;

    for (final asset in provider.assets) {
      if (asset.hasAvailabilityWarning) {
        warning += 1;
      }
      switch (asset.status) {
        case 'AVAILABLE':
          available += 1;
          break;
        case 'IN_USE':
          inUse += 1;
          break;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final isWorker = _isWorkerView(authProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF204534), Color(0xFF102218)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset Inventory',
                      style: AppTextStyles.h2(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap any asset to open a full visual detail page with image, diagnosis, and activity history.',
                      style: AppTextStyles.bodyMedium(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _scanQrAndFetchAsset,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: isWorker
                    ? Text(
                        'Showing only machines in your field or explicitly assigned to you.',
                        style: AppTextStyles.bodyMedium(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      )
                    : CustomButton(
                        text: 'Add Asset',
                        icon: Icons.add_rounded,
                        onPressed: _openAddAssetForm,
                        backgroundColor: Colors.white,
                        textColor: AppColorPalette.charcoalGreen,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statBlock('Total', provider.assets.length.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(child: _statBlock('Available', available.toString())),
              const SizedBox(width: 10),
              Expanded(child: _statBlock('In use', inUse.toString())),
              const SizedBox(width: 10),
              Expanded(child: _statBlock('Warning', warning.toString())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3(color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              size: 32,
              color: AppColorPalette.charcoalGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text('No assets yet', style: AppTextStyles.h4()),
          const SizedBox(height: 6),
          Text(
            'Add your first machine, tool, or vehicle to start tracking image, status, and service details.',
            style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showQrCode(AssetItem asset) {
    debugPrint('🔍 QR Code button tapped for asset: ${asset.name}');
    debugPrint('📱 Serial Number: ${asset.serialNumber}');

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
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
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
      backgroundColor: const Color(0xFFF2EFE7),
      appBar: AppBar(
        title: Text(
          'Asset Inventory',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.transparent,
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _overviewCard(provider),
                if (provider.error != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
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
                  _emptyState()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: provider.assets.map(_assetCard).toList(),
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
  String? _selectedImageBase64;
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
  bool _submittedOnce = false;
  String? _categoryError;
  String? _fieldError;

  static const List<String> _categoryOptions = [
    'TRACTOR',
    'HARVESTER',
    'SPRAYER',
    'SEEDER',
    'IRRIGATION',
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
    if (value.contains('tractor')) return 'TRACTOR';
    if (value.contains('harvest')) return 'HARVESTER';
    if (value.contains('spray')) return 'SPRAYER';
    if (value.contains('seed')) return 'SEEDER';
    if (value.contains('irrig')) return 'IRRIGATION';
    if (value.contains('drone')) return 'Drones';
    if (value.contains('machin')) {
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

  List<String> _liveMessages() {
    final liveIssues =
        (_liveValidation?['issues'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    final liveWarnings =
        (_liveValidation?['warnings'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];
    return [...liveIssues, ...liveWarnings];
  }

  String? _fieldValidationMessage(List<String> keywords) {
    final messages = _liveMessages();
    for (final message in messages) {
      final normalized = message.toLowerCase();
      if (keywords.any((keyword) => normalized.contains(keyword))) {
        return message;
      }
    }
    return null;
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
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 960,
      maxHeight: 960,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBase64 = base64Encode(bytes);
        _liveValidation = null;
      });
      _scheduleLiveValidation();
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
    setState(() => _submittedOnce = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _categoryError = null;
      _fieldError = null;
    });

    if (_selectedCategory == null) {
      setState(() => _categoryError = 'Please select a category.');
      return;
    }

    if (_selectedFieldId == null) {
      setState(() => _fieldError = 'Please select a field.');
      return;
    }

    // --- AI Validation Step ---
    final aiPayload = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory!,
      'type': _selectedCategory!,
      'operatingHours': double.tryParse(_operatingHoursController.text.trim()),
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
    final provider = context.read<AssetProvider>();
    try {
      final assetAiService = AssetAiService();
      final aiResult = await assetAiService.validateAsset(aiPayload);
      if (mounted) {
        setState(() {
          _liveValidation = aiResult;
        });
      }
      if (aiResult['valid'] == false) {
        aiStatus = 'invalid';
      } else if ((aiResult['warnings'] as List?)?.isNotEmpty ?? false) {
        aiStatus = 'warning';
      } else if ((aiResult['confidence'] ?? 1.0) < 0.7) {
        aiStatus = 'warning';
      }
    } catch (e) {
      aiStatus = 'warning';
      aiMessage = 'AI validation unavailable. Proceeding with caution.';
    }

    // For invalid inputs, keep user on form and show field-level messages.
    if (aiStatus == 'invalid') {
      if (aiMessage.isNotEmpty && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(aiMessage)));
      }
      return;
    }

    // --- Proceed to submit asset ---
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

    if (success) {
      _showAssetAddSuccess();
      return;
    }

    _showAssetAddError(provider.error ?? 'Unable to create asset');
  }

  void _showAssetAddSuccess() {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Asset added successfully.')));
  }

  void _showAssetAddError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                                            : 'Please fix the highlighted fields below.')),
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
                        validator: Validators.assetName,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                      ),
                      if (_fieldValidationMessage(['name']) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fieldValidationMessage(['name'])!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      AssetSuggestField(
                        label: 'Brand',
                        helperText: 'AI powered brand suggestions',
                        controller: _brandController,
                        fieldType: 'brand',
                        required: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      if (_fieldValidationMessage(['brand']) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fieldValidationMessage(['brand'])!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      AssetSuggestField(
                        label: 'Model',
                        helperText: _selectedCategory == null
                            ? 'Pick a category to refine models'
                            : 'Filtered by ${_selectedCategory!}',
                        controller: _modelController,
                        fieldType: 'model',
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      if (_fieldValidationMessage(['model']) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fieldValidationMessage(['model'])!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
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
                        initialValue: _selectedCategory,
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
                          setState(() {
                            _selectedCategory = value;
                            _categoryError = null;
                          });
                          _scheduleLiveValidation();
                        },
                      ),
                      if (_categoryError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _categoryError!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
                        )
                      else if (_fieldValidationMessage(['category']) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fieldValidationMessage(['category'])!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
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
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
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
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
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
                          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                field['name']?.toString() ??
                                    'Field not available',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedFieldId = value;
                          _fieldError = null;
                        }),
                      ),
                      if (_fieldError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _fieldError!,
                            style: AppTextStyles.bodySmall(
                              color: Colors.red.shade700,
                            ),
                          ),
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
                  if (_submittedOnce &&
                      (_selectedImageBase64 == null ||
                          _selectedImageBase64!.isEmpty))
                    const SizedBox.shrink(),
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
