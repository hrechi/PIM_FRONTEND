import 'package:flutter/material.dart';
import '../../models/catalogue_models.dart';

class CatalogueSettingsSheet extends StatefulWidget {
  final CatalogueSettings initialSettings;
  final ValueChanged<CatalogueSettings> onSettingsChanged;

  const CatalogueSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<CatalogueSettingsSheet> createState() => _CatalogueSettingsSheetState();
}

class _CatalogueSettingsSheetState extends State<CatalogueSettingsSheet> {
  late CatalogueSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Catalogue Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Content Sections',
                    [
                      _buildSwitchTile(
                        'Animal Photos',
                        'Include high-quality photos of each animal',
                        _settings.showPhotos,
                        (value) => _updateSettings(showPhotos: value),
                      ),
                      _buildSwitchTile(
                        'Animal Details',
                        'Basic information: age, weight, breed, etc.',
                        _settings.showDetails,
                        (value) => _updateSettings(showDetails: value),
                      ),
                      _buildSwitchTile(
                        'Health Records',
                        'Medical history and current health status',
                        _settings.showHealth,
                        (value) => _updateSettings(showHealth: value),
                      ),
                      _buildSwitchTile(
                        'Vaccination History',
                        'Complete vaccination records',
                        _settings.showVaccinations,
                        (value) => _updateSettings(showVaccinations: value),
                      ),
                      _buildSwitchTile(
                        'Production Records',
                        'Milk production, growth rates, etc.',
                        _settings.showProduction,
                        (value) => _updateSettings(showProduction: value),
                      ),
                      _buildSwitchTile(
                        'Genetic Information',
                        'Pedigree and genetic data',
                        _settings.showGenetics,
                        (value) => _updateSettings(showGenetics: value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Layout & Design',
                    [
                      _buildSwitchTile(
                        'Two Column Layout',
                        'Display animals in a two-column grid',
                        _settings.twoColumnLayout,
                        (value) => _updateSettings(twoColumnLayout: value),
                      ),
                      _buildSwitchTile(
                        'Show QR Codes',
                        'Include QR codes linking to detailed animal info',
                        _settings.showQrCodes,
                        (value) => _updateSettings(showQrCodes: value),
                      ),
                      _buildSwitchTile(
                        'Include Contact Info',
                        'Add farm contact information to the catalogue',
                        _settings.showContactInfo,
                        (value) => _updateSettings(showContactInfo: value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Advanced Options',
                    [
                      _buildSwitchTile(
                        'Show Prices',
                        'Display pricing information (if available)',
                        _settings.showPrices,
                        (value) => _updateSettings(showPrices: value),
                      ),
                      _buildSwitchTile(
                        'Include Notes',
                        'Show additional notes for each animal',
                        _settings.showNotes,
                        (value) => _updateSettings(showNotes: value),
                      ),
                      _buildSwitchTile(
                        'Compact Mode',
                        'Use smaller text and tighter spacing',
                        _settings.compactMode,
                        (value) => _updateSettings(compactMode: value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefaults,
                  child: const Text('Reset to Defaults'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSettingsChanged(_settings);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
      ),
    );
  }

  void _updateSettings({
    bool? showPhotos,
    bool? showDetails,
    bool? showHealth,
    bool? showVaccinations,
    bool? showProduction,
    bool? showGenetics,
    bool? twoColumnLayout,
    bool? showQrCodes,
    bool? showContactInfo,
    bool? showPrices,
    bool? showNotes,
    bool? compactMode,
  }) {
    setState(() {
      _settings = _settings.copyWith(
        showPhotos: showPhotos,
        showDetails: showDetails,
        showHealth: showHealth,
        showVaccinations: showVaccinations,
        showProduction: showProduction,
        showGenetics: showGenetics,
        twoColumnLayout: twoColumnLayout,
        showQrCodes: showQrCodes,
        showContactInfo: showContactInfo,
        showPrices: showPrices,
        showNotes: showNotes,
        compactMode: compactMode,
      );
    });
  }

  void _resetToDefaults() {
    setState(() {
      _settings = CatalogueSettings.defaultSettings();
    });
  }
}