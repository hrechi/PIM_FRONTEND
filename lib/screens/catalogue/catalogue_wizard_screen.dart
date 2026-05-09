import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../models/catalogue_models.dart';
import '../../models/animal.dart';
import '../../widgets/animal_catalogue_card.dart';
import '../../utils/currency_converter.dart';
import '../../l10n/l10n_extensions.dart';
import '../animal_selector_screen.dart';
import 'catalogue_preview_screen.dart';

class CatalogueWizardScreen extends StatefulWidget {
  final SaleCatalogue? catalogue;

  const CatalogueWizardScreen({super.key, this.catalogue});

  @override
  State<CatalogueWizardScreen> createState() => _CatalogueWizardScreenState();
}

class _CatalogueWizardScreenState extends State<CatalogueWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  String? _savedCatalogueId;

  // Step 1: Basic Info
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _saleDate;
  String _currency = 'TND';
  bool _showPrices = false;

  // Step 2: Animal Selection
  List<Animal> _selectedAnimals = [];
  List<String> _selectedAnimalIds = [];

  // Step 3: Settings
  CatalogueSettings _settings = CatalogueSettings.defaultSettings();

  // Step 4: Preview (handled by separate screen)

  @override
  void initState() {
    super.initState();
    if (widget.catalogue != null) {
      _loadExistingCatalogue();
    }
  }

  void _loadExistingCatalogue() {
    final catalogue = widget.catalogue!;
    _titleController.text = catalogue.title;
    _locationController.text = catalogue.location ?? '';
    _saleDate = catalogue.saleDate;
    _currency = catalogue.currency;
    _showPrices = catalogue.showPrices;
    _settings = catalogue.settings ?? CatalogueSettings.defaultSettings();
    _selectedAnimals = catalogue.animals
        .where((ca) => ca.animal != null)
        .map((ca) => ca.animal!)
        .toList();
    _selectedAnimalIds = catalogue.animals.map((ca) => ca.animalId).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catalogue != null ? context.l10n.editAnimal : context.l10n.createCatalogue),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(context),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= _currentStep
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= _currentStep ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepTitle(index),
                  style: TextStyle(
                    fontSize: 12,
                    color: index <= _currentStep
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return context.l10n.info;
      case 1: return context.l10n.animals;
      case 2: return context.l10n.settings;
      case 3: return context.l10n.preview;
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildBasicInfoStep();
      case 1: return _buildAnimalSelectionStep();
      case 2: return _buildSettingsStep();
      case 3: return _buildPreviewStep();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.basicInformation, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.l10n.catalogueTitle,
                hintText: context.l10n.catalogueTitleHint,
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return context.l10n.titleRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: context.l10n.location,
                hintText: context.l10n.locationHint,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.saleDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  _saleDate != null
                      ? '${_saleDate!.day}/${_saleDate!.month}/${_saleDate!.year}'
                      : context.l10n.selectDate,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(labelText: context.l10n.currency),
                    items: CurrencyConverter.supported.map((c) {
                      return DropdownMenuItem(value: c, child: Text('$c  ${CurrencyConverter.symbol(c)}'));
                    }).toList(),
                    onChanged: (value) => setState(() => _currency = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: Text(context.l10n.showPrices),
                    value: _showPrices,
                    onChanged: (value) => setState(() => _showPrices = value),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalSelectionStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${context.l10n.selectedAnimals} (${_selectedAnimals.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToAnimalSelector(),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.addAnimals),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedAnimals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noAnimalsSelected,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.addAnimalsToInclude, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAnimalSelector(),
                        icon: const Icon(Icons.add),
                        label: Text(context.l10n.selectAnimals),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _selectedAnimals.length,
                  itemBuilder: (context, index) {
                    final animal = _selectedAnimals[index];
                    return AnimalCatalogueCard(
                      animal: animal,
                      onRemove: () => _removeAnimal(animal.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.catalogueSettingsTitle, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildSettingsSection(context.l10n.sectionsToInclude, [
            _buildSettingSwitch(context.l10n.animalPhotos, _settings.showPhotos, (v) => setState(() => _settings = _settings.copyWith(showPhotos: v))),
            _buildSettingSwitch(context.l10n.animalDetailsSection, _settings.showDetails, (v) => setState(() => _settings = _settings.copyWith(showDetails: v))),
            _buildSettingSwitch(context.l10n.healthRecords, _settings.showHealth, (v) => setState(() => _settings = _settings.copyWith(showHealth: v))),
            _buildSettingSwitch(context.l10n.vaccinationHistory, _settings.showVaccinations, (v) => setState(() => _settings = _settings.copyWith(showVaccinations: v))),
            _buildSettingSwitch(context.l10n.productionRecords, _settings.showProduction, (v) => setState(() => _settings = _settings.copyWith(showProduction: v))),
            _buildSettingSwitch(context.l10n.geneticInformation, _settings.showGenetics, (v) => setState(() => _settings = _settings.copyWith(showGenetics: v))),
          ]),
          const SizedBox(height: 24),
          _buildSettingsSection(context.l10n.layoutOptions, [
            _buildSettingSwitch(context.l10n.twoColumnLayout, _settings.twoColumnLayout, (v) => setState(() => _settings = _settings.copyWith(twoColumnLayout: v))),
            _buildSettingSwitch(context.l10n.showQrCodes, _settings.showQrCodes, (v) => setState(() => _settings = _settings.copyWith(showQrCodes: v))),
            _buildSettingSwitch(context.l10n.includeContactInfo, _settings.showContactInfo, (v) => setState(() => _settings = _settings.copyWith(showContactInfo: v))),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSettingSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildPreviewStep() {
    // Use Consumer so we don't call context.read() directly inside build().
    return Consumer<CatalogueProvider>(
      builder: (context, provider, _) {
        final catalogue =
            (_savedCatalogueId != null && provider.currentCatalogue?.id == _savedCatalogueId)
                ? provider.currentCatalogue!
                : _createPreviewCatalogue();

        return CataloguePreviewScreen(
          catalogue: catalogue,
          isPreview: true,
          onBack: () => setState(() => _currentStep = 2),
          // No onNext — export is accessible from the list screen
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: Text(context.l10n.back),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _handleNext : null,
              child: Text(_getNextButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: return _titleController.text.trim().isNotEmpty;
      case 1: return _selectedAnimals.isNotEmpty;
      case 2: return true;
      case 3: return true; // Done button on preview
      default: return false;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0: return context.l10n.selectAnimals;
      case 1: return context.l10n.settings;
      case 2: return widget.catalogue != null ? context.l10n.updateRecord : context.l10n.createCatalogue;
      case 3: return context.l10n.done;
      default: return context.l10n.next;
    }
  }

  void _handleNext() async {
    if (_currentStep == 2) {
      await _saveCatalogue();
    } else if (_currentStep == 3) {
      // Preview is the last step — close wizard and return to list
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() => _currentStep++);
    }
  }

  Future<void> _saveCatalogue() async {
    // Validate title manually (form may not be in tree at step 2)
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.titleRequired)),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final provider = context.read<CatalogueProvider>();
    SaleCatalogue? result;

    if (widget.catalogue != null) {
      // Update existing catalogue metadata
      result = await provider.updateCatalogue(
        widget.catalogue!.id,
        title: _titleController.text.trim(),
        saleDate: _saleDate,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        currency: _currency,
        showPrices: _showPrices,
        settings: _settings,
      );

      if (result != null) {
        // Sync animal changes: compute diff between original and current selection
        final existingIds =
            widget.catalogue!.animals.map((a) => a.animalId).toSet();
        final newIds = _selectedAnimalIds.toSet();

        final toAdd = newIds.difference(existingIds).toList();
        final toRemove = existingIds.difference(newIds).toList();

        if (toAdd.isNotEmpty) {
          await provider.addAnimals(result.id, toAdd);
        }
        for (final id in toRemove) {
          await provider.removeAnimal(result.id, id);
        }

        // Reload to get fresh animal data
        await provider.loadCatalogue(result.id);
        result = provider.currentCatalogue ?? result;
      }
    } else {
      // Create new
      result = await provider.createCatalogue(
        title: _titleController.text.trim(),
        saleDate: _saleDate,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        currency: _currency,
        showPrices: _showPrices,
        settings: _settings,
      );

      // Add animals to the new catalogue
      if (result != null && _selectedAnimalIds.isNotEmpty) {
        await provider.addAnimals(result.id, _selectedAnimalIds);
        // Reload full catalogue so CatalogueAnimal entries have nested animal data
        await provider.loadCatalogue(result.id);
        result = provider.currentCatalogue ?? result;
      }
    }

    if (!mounted) return;

    if (result != null) {
      _savedCatalogueId = result.id;
      setState(() => _currentStep++); // → step 3 (Preview)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? context.l10n.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  SaleCatalogue _createPreviewCatalogue() {
    return SaleCatalogue(
      id: widget.catalogue?.id ?? 'preview',
      farmerId: widget.catalogue?.farmerId ?? 'preview_farmer',
      title: _titleController.text,
      location: _locationController.text.isEmpty ? null : _locationController.text,
      saleDate: _saleDate,
      currency: _currency,
      showPrices: _showPrices,
      settings: _settings,
      status: 'draft',
      animals: _selectedAnimals.asMap().entries.map((entry) {
        final animal = entry.value;
        return CatalogueAnimal(
          id: '${animal.id}-${entry.key}',
          catalogueId: widget.catalogue?.id ?? 'preview',
          animalId: animal.id,
          animal: animal,
          sortOrder: entry.key,
          priceOverride: null,
          notes: null,
        );
      }).toList(),
      shareToken: widget.catalogue?.shareToken,
      createdAt: widget.catalogue?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  void _navigateToAnimalSelector() async {
    final result = await Navigator.push<List<Animal>>(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalSelectorScreen(
          selectedAnimals: _selectedAnimals,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAnimals = result;
        _selectedAnimalIds = result.map((a) => a.id).toList();
      });
    }
  }

  void _removeAnimal(String animalId) {
    setState(() {
      _selectedAnimals.removeWhere((animal) => animal.id == animalId);
      _selectedAnimalIds.remove(animalId);
    });
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.exitWizard),
        content: Text(context.l10n.exitWizardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(context.l10n.exit),
          ),
        ],
      ),
    );
  }
}