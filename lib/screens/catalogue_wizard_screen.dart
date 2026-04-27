import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/catalogue_provider.dart';
import '../models/catalogue_models.dart';
import '../models/animal.dart';
import '../widgets/animal_catalogue_card.dart';
import 'animal_selector_screen.dart';
import 'catalogue_preview_screen.dart';
import 'catalogue_export_screen.dart';

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
        title: Text(widget.catalogue != null ? 'Edit Catalogue' : 'Create Catalogue'),
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
        children: List.generate(5, (index) {
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
      case 0: return 'Info';
      case 1: return 'Animals';
      case 2: return 'Settings';
      case 3: return 'Preview';
      case 4: return 'Export';
      default: return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildBasicInfoStep();
      case 1: return _buildAnimalSelectionStep();
      case 2: return _buildSettingsStep();
      case 3: return _buildPreviewStep();
      case 4: return _buildExportStep();
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
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Catalogue Title *',
                hintText: 'e.g., Spring 2024 Dairy Cattle Sale',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Farm Location, City',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Sale Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _saleDate != null
                      ? '${_saleDate!.day}/${_saleDate!.month}/${_saleDate!.year}'
                      : 'Select date',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: ['TND', 'USD', 'EUR'].map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _currency = value!);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Show Prices'),
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
                  'Selected Animals (${_selectedAnimals.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToAnimalSelector(),
                icon: const Icon(Icons.add),
                label: const Text('Add Animals'),
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
                        'No animals selected',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add animals to include in your catalogue',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToAnimalSelector(),
                        icon: const Icon(Icons.add),
                        label: const Text('Select Animals'),
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
          Text(
            'Catalogue Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            'Sections to Include',
            [
              _buildSettingSwitch('Animal Photos', _settings.showPhotos, (value) {
                setState(() => _settings = _settings.copyWith(showPhotos: value));
              }),
              _buildSettingSwitch('Animal Details', _settings.showDetails, (value) {
                setState(() => _settings = _settings.copyWith(showDetails: value));
              }),
              _buildSettingSwitch('Health Records', _settings.showHealth, (value) {
                setState(() => _settings = _settings.copyWith(showHealth: value));
              }),
              _buildSettingSwitch('Vaccination History', _settings.showVaccinations, (value) {
                setState(() => _settings = _settings.copyWith(showVaccinations: value));
              }),
              _buildSettingSwitch('Production Records', _settings.showProduction, (value) {
                setState(() => _settings = _settings.copyWith(showProduction: value));
              }),
              _buildSettingSwitch('Genetic Information', _settings.showGenetics, (value) {
                setState(() => _settings = _settings.copyWith(showGenetics: value));
              }),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Layout Options',
            [
              _buildSettingSwitch('Two Column Layout', _settings.twoColumnLayout, (value) {
                setState(() => _settings = _settings.copyWith(twoColumnLayout: value));
              }),
              _buildSettingSwitch('Show QR Codes', _settings.showQrCodes, (value) {
                setState(() => _settings = _settings.copyWith(showQrCodes: value));
              }),
              _buildSettingSwitch('Include Contact Info', _settings.showContactInfo, (value) {
                setState(() => _settings = _settings.copyWith(showContactInfo: value));
              }),
            ],
          ),
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
    // Use the saved catalogue from provider if available (has real animal data)
    final provider = context.read<CatalogueProvider>();
    final catalogue = (_savedCatalogueId != null && provider.currentCatalogue?.id == _savedCatalogueId)
        ? provider.currentCatalogue!
        : _createPreviewCatalogue();

    return CataloguePreviewScreen(
      catalogue: catalogue,
      isPreview: true,
      onBack: () => setState(() => _currentStep = 2),
      onNext: () => setState(() => _currentStep = 4),
    );
  }

  Widget _buildExportStep() {
    return CatalogueExportScreen(
      catalogue: _createPreviewCatalogue(),
      isPreview: true,
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
                child: const Text('Back'),
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
      case 0:
        // Allow proceeding if title is not empty (validate on attempt)
        return _titleController.text.trim().isNotEmpty;
      case 1: return _selectedAnimals.isNotEmpty;
      case 2: return true;
      case 3: return true;
      case 4: return true;
      default: return false;
    }
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0: return 'Select Animals';
      case 1: return 'Settings';
      case 2: return widget.catalogue != null ? 'Update' : 'Create';
      case 3: return 'Preview';
      case 4: return 'Export';
      default: return 'Next';
    }
  }

  void _handleNext() async {
    if (_currentStep == 2) {
      // Step 2 → save the catalogue before going to preview
      await _saveCatalogue();
    } else if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  Future<void> _saveCatalogue() async {
    // Validate title manually (form may not be in tree at step 2)
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final provider = context.read<CatalogueProvider>();
    SaleCatalogue? result;

    if (widget.catalogue != null) {
      // Update existing
      result = await provider.updateCatalogue(
        widget.catalogue!.id,
        title: _titleController.text.trim(),
        saleDate: _saleDate,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        currency: _currency,
        showPrices: _showPrices,
        settings: _settings,
      );
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
      // ✅ Store the catalogue ID for later use
      _savedCatalogueId = result.id;
      // ✅ Advance to preview step instead of closing
      setState(() => _currentStep++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save catalogue'),
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
        title: const Text('Exit Wizard'),
        content: const Text(
          'Are you sure you want to exit? Any unsaved changes will be lost.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close wizard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}