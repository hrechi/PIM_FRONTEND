import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../services/field_service.dart';
import '../../models/field_model.dart';
import '../../services/vaccine_service.dart';
import '../../models/vaccine_models.dart';
import 'package:intl/intl.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animal;
  const AddAnimalScreen({super.key, this.animal});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnimalService _animalService = AnimalService();
  final FieldService _fieldService = FieldService();
  final VaccineService _vaccineService = VaccineService();

  // Controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _tagController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _dailyMilkAvgController = TextEditingController();
  final _lactationNumberController = TextEditingController();

  // State
  int _currentStep = 1;
  String _selectedType = 'cow';
  String _selectedSex = 'female';
  double _ageInMonths = 24;
  bool _isVaccinated = false;
  bool? _isPregnant; // null = unknown, true = yes, false = no
  bool _isLoading = false;
  
  // Field-based ownership
  List<FieldModel> _fields = [];
  String? _selectedFieldId;

  // Species-specific state
  String? _raceCategory;   // course, loisir, sport
  String? _trainingLevel;  // debutant, intermediaire, avance, confirme, elite
  String? _meatGrade;      // A, B, C
  String? _dogRole;        // garde, berger, compagnie

  // Vaccine list (legacy/manual)
  List<Map<String, dynamic>> _vaccines = [];

  // Dynamic Vaccine Regulations
  List<VaccineRegulation> _regulations = [];
  bool _isLoadingRegulations = false;
  
  // Tracked data for each regulation/vaccine
  // Key: vaccine code, Value: {checked: bool, date: String, dose: double, isOther: bool, lot: String}
  final Map<String, Map<String, dynamic>> _vaccineSelections = {};

  bool get isEditMode => widget.animal != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final a = widget.animal!;
      _nameController.text = a.name;
      _breedController.text = a.breed ?? '';
      _tagController.text = a.tagNumber ?? '';
      _weightController.text = a.weight?.toString() ?? '';
      _notesController.text = a.notes ?? '';
      _selectedType = a.animalType.toLowerCase();
      _selectedSex = a.sex.toLowerCase();
      _ageInMonths = a.age.toDouble();
      _isVaccinated = a.vaccination;
      
      // Prefer vaccineRecords for modern sync
      if (a.vaccineRecords != null && a.vaccineRecords!.isNotEmpty) {
        _vaccines = a.vaccineRecords!.map((v) => {
          'name': (v.vaccine?.code == 'OTHER' ? v.notes : v.vaccine?.nameFr) ?? v.notes ?? 'Vaccin',
          'date': v.administeredAt.toIso8601String().split('T')[0],
        }).toList();
      }
      
      _isPregnant = a.isPregnant;
      // Start at step 2 (Details) when editing
      _currentStep = 2;
    }
    _ageMonthsController.text = _ageInMonths.toInt().toString();
    _ageMonthsController.addListener(() {
      final val = double.tryParse(_ageMonthsController.text);
      if (val != null && val >= 0 && val <= 240) {
        setState(() => _ageInMonths = val);
      }
    });
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
        if (!isEditMode && _fields.isNotEmpty) {
          _selectedFieldId = _fields.first.id;
          _fetchRegulations(); // Start fetching for default field
        } else if (isEditMode) {
          _selectedFieldId = widget.animal?.fieldId;
        }
      });
    } catch (e) {
      debugPrint('Error fetching fields: $e');
    }
  }

  Future<void> _fetchRegulations() async {
    if (_selectedFieldId == null) return;
    
    setState(() => _isLoadingRegulations = true);
    try {
      final field = _fields.firstWhere((f) => f.id == _selectedFieldId);
      final countryCode = field.countryCode;
      
      if (countryCode != null) {
        final regs = await _vaccineService.getCountryRegulations(countryCode, species: _selectedType);
        setState(() {
          _regulations = regs;
          // Pre-populate selections for existing regulations if not already present
          for (var reg in _regulations) {
             if (!_vaccineSelections.containsKey(reg.vaccineId)) {
               _vaccineSelections[reg.vaccineId] = {
                 'checked': false,
                 'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                 'dose': 1.0,
                 'lot': '',
                 'isOther': false,
                 'name': reg.vaccine?.nameEn ?? reg.vaccineId,
               };
             }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching regulations: $e');
    } finally {
      setState(() => _isLoadingRegulations = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _tagController.dispose();
    _ageMonthsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _dailyMilkAvgController.dispose();
    _lactationNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final animalData = {
        'name': _nameController.text,
        'breed': _breedController.text,
        'animalType': _selectedType,
        'age': _ageInMonths.toInt(),
        'ageYears': (_ageInMonths / 12).floor(),
        'sex': _selectedSex,
        'weight': double.tryParse(_weightController.text),
        'tagNumber': _tagController.text,
        'notes': _notesController.text,
        'fieldId': _selectedFieldId,
        'vaccination': _isVaccinated,
        'vaccines': _isVaccinated ? _vaccines : null,
        // COW + female
        'isPregnant': (_selectedType == 'cow' && _selectedSex == 'female') ? _isPregnant : null,
        'lactationNumber': (_selectedType == 'cow' && _selectedSex == 'female')
            ? int.tryParse(_lactationNumberController.text)
            : null,
        'dailyMilkAvgL': (_selectedType == 'cow' && _selectedSex == 'female')
            ? double.tryParse(_dailyMilkAvgController.text)
            : null,
        // HORSE
        'raceCategory': _selectedType == 'horse' ? _raceCategory : null,
        'trainingLevel': _selectedType == 'horse' ? _trainingLevel : null,
        // SHEEP
        'meatGrade': _selectedType == 'sheep' ? _meatGrade : null,
        // DOG
        'dogRole': _selectedType == 'dog' ? _dogRole : null,
      };

      Animal animal;
      if (isEditMode) {
        animal = await _animalService.updateAnimal(widget.animal!.nodeId, animalData);
      } else {
        animal = await _animalService.createAnimal(animalData);
      }

      // ── Record selected vaccinations ──
      final checkedSelections = _vaccineSelections.entries.where((e) => e.value['checked'] == true).toList();
      for (var entry in checkedSelections) {
        final sel = entry.value;
        try {
          await _vaccineService.createRecord(
            animalId: animal.id,
            vaccineCode: sel['isOther'] == true ? 'OTHER' : entry.key,
            administeredBy: 'Farmer',
            administeredAt: DateTime.parse(sel['date']),
            doseGiven: (sel['dose'] as num).toDouble(),
            notes: sel['isOther'] == true ? sel['name'] : null, // Store name in notes for OTHER
          );
        } catch (ve) {
          debugPrint('Failed to record vaccine ${entry.key}: $ve');
        }
      }

      // ── Generate Smart Planning ──
      if (!isEditMode) {
        try {
          await _vaccineService.generateSmartPlan(animal.id);
        } catch (pe) {
          debugPrint('Failed to generate smart plan: $pe');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Animal mis à jour avec succès !' : 'Animal enregistré avec succès ! Plan généré.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addVaccine() {
    setState(() {
      _vaccines.add({'name': '', 'date': DateTime.now().toIso8601String().split('T')[0]});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      body: Container(
        color: AppColors.sageTint,
        child: Stack(
          children: [
            // Background Mesh Gradient
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            height: 400,
            child: Opacity(
              opacity: 0.6,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.fieldFreshStart.withValues(alpha: 0.2),
                            AppColors.fieldFreshStart.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.mistyBlue.withValues(alpha: 0.2),
                            AppColors.mistyBlue.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    child: Form(
                      key: _formKey,
                      child: _buildCurrentStep(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildBottomAction(),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _buildIconButton(Symbols.arrow_back_ios_new),
                  ),
                ],
              ),
              Text(
                isEditMode ? 'Edit Animal' : 'Add Animal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
              _buildIconButton(Symbols.more_horiz),
            ],
          ),
          const SizedBox(height: 32),
          _buildStepper(),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepIndicator(1, 'Species', _currentStep >= 1),
        _buildStepIndicatorLine(_currentStep > 1),
        _buildStepIndicator(2, 'Details', _currentStep >= 2),
        _buildStepIndicatorLine(_currentStep > 2),
        _buildStepIndicator(3, 'Vaccines', _currentStep >= 3),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.mistyBlue : const Color(0xFFF1F5F9),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.mistyBlue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? AppColors.mistyBlue : const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicatorLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.mistyBlue : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  // ─── Step 1: Species & Gender ───────────────────────────────────────────────
  Widget _buildStep1() {
    final types = [
      {'id': 'cow',   'label': 'Cow',   'emoji': '🐄', 'icon': Symbols.cruelty_free},
      {'id': 'sheep', 'label': 'Sheep', 'emoji': '🐑', 'icon': Symbols.pest_control_rodent},
      {'id': 'horse', 'label': 'Horse', 'emoji': '🐎', 'icon': Symbols.emoji_nature},
      {'id': 'dog',   'label': 'Dog',   'emoji': '🐕', 'icon': Symbols.sound_detection_dog_barking},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Select Farm / Field'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFieldId,
              isExpanded: true,
              hint: const Text('Select a field'),
              items: _fields.map((field) {
                return DropdownMenuItem<String>(
                  value: field.id,
                  child: Text(field.name),
                );
              }).toList(),
              onChanged: isEditMode ? null : (value) {
                setState(() => _selectedFieldId = value);
                _fetchRegulations();
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Species',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Required',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final isSelected = _selectedType == type['id'];
            return GestureDetector(
              onTap: isEditMode ? null : () {
                setState(() => _selectedType = type['id'] as String);
                _fetchRegulations();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.mistyBlue : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.mistyBlue.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(type['emoji'] as String, style: const TextStyle(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text(
                      (type['label'] as String).toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        _buildLabel('Gender'),
        Row(
          children: [
            _buildGenderOption('female', Symbols.female, 'Femelle'),
            const SizedBox(width: 16),
            _buildGenderOption('male', Symbols.male, 'Mâle'),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String id, IconData icon, String label) {
    final isSelected = _selectedSex == id;
    return Expanded(
      child: GestureDetector(
        onTap: isEditMode ? null : () => setState(() => _selectedSex = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mistyBlue.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.mistyBlue : const Color(0xFFF1F5F9),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppColors.mistyBlue : const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.mistyBlue : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step 2: Profile Details ────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        _buildLabel('Animal Name'),
        _buildTextField(_nameController, 'e.g. Bessie'),
        const SizedBox(height: 24),
        _buildLabel('Breed'),
        _buildTextField(_breedController, 'e.g. Holstein'),
        const SizedBox(height: 24),

        _buildLabel('Weight'),
        _buildTextField(
          _weightController,
          'e.g. 450',
          keyboardType: TextInputType.number,
          prefixIcon: Symbols.weight,
          suffix: 'KG',
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel('Age'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mistyBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_ageInMonths.toInt()} Mois',
                style: const TextStyle(
                  color: AppColors.mistyBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAgeSlider(),
        const SizedBox(height: 12),
        _buildTextField(
          _ageMonthsController,
          'Âge exact en mois',
          keyboardType: TextInputType.number,
          suffix: 'MOIS',
        ),

        const SizedBox(height: 24),
        _buildLabel('Tag / Node ID'),
        _buildTextField(
          _tagController,
          'SCAN-004-921',
          prefixIcon: Symbols.qr_code_2,
          readOnly: isEditMode,
        ),
        const SizedBox(height: 32),

        // --- Species-Specific Fields (Consolidated in Step 2) ---
        if (_selectedType == 'cow' && _selectedSex == 'female') ...[
          _buildLabel('Reproduction'),
          _buildSectionCard(
            title: 'Gestation & Lactation',
            icon: Symbols.water_drop,
            iconColor: const Color(0xFF3B82F6),
            children: [
              _buildLabel('Gestante ?'),
              _buildPregnancyToggle(),
              const SizedBox(height: 20),
              _buildLabel('Numéro de lactation'),
              _buildTextField(
                _lactationNumberController,
                'Ex : 2',
                keyboardType: TextInputType.number,
                suffix: 'N°',
              ),
              const SizedBox(height: 20),
              _buildLabel('Production laitière moyenne'),
              _buildTextField(
                _dailyMilkAvgController,
                'Ex : 18.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'L/J',
              ),
            ],
          ),
        ],
        if (_selectedType == 'horse') ...[
          _buildLabel('Profil Sportif'),
          _buildSectionCard(
            title: 'Compétition',
            icon: Symbols.sprint,
            iconColor: const Color(0xFFF59E0B),
            children: [
              _buildLabel('Catégorie de course'),
              _buildDropdown(
                value: _raceCategory,
                hint: 'Sélectionner...',
                items: const [
                  DropdownMenuItem(value: 'course',  child: Text('Course')),
                  DropdownMenuItem(value: 'loisir',  child: Text('Loisir')),
                  DropdownMenuItem(value: 'sport',   child: Text('Sport')),
                ],
                onChanged: (v) => setState(() => _raceCategory = v),
              ),
              const SizedBox(height: 20),
              _buildLabel('Niveau d\'entraînement'),
              _buildDropdown(
                value: _trainingLevel,
                hint: 'Sélectionner...',
                items: const [
                  DropdownMenuItem(value: 'debutant',      child: Text('Débutant')),
                  DropdownMenuItem(value: 'intermediaire', child: Text('Intermédiaire')),
                  DropdownMenuItem(value: 'avance',        child: Text('Avancé')),
                  DropdownMenuItem(value: 'confirme',      child: Text('Confirmé')),
                  DropdownMenuItem(value: 'elite',         child: Text('Élite')),
                ],
                onChanged: (v) => setState(() => _trainingLevel = v),
              ),
            ],
          ),
        ],
        if (_selectedType == 'sheep') ...[
          _buildLabel('Qualité Viande'),
          _buildSectionCard(
            title: 'Grade',
            icon: Symbols.star,
            iconColor: const Color(0xFF10B981),
            children: [
              _buildLabel('Grade Qualité'),
              _buildDropdown(
                value: _meatGrade,
                hint: 'Optionnel...',
                items: const [
                  DropdownMenuItem(value: 'A', child: Text('Grade A — Supérieur')),
                  DropdownMenuItem(value: 'B', child: Text('Grade B — Standard')),
                  DropdownMenuItem(value: 'C', child: Text('Grade C — Économique')),
                ],
                onChanged: (v) => setState(() => _meatGrade = v),
              ),
            ],
          ),
        ],
        if (_selectedType == 'dog') ...[
          _buildLabel('Rôle Professionnel'),
          _buildSectionCard(
            title: 'Spécialisation',
            icon: Symbols.shield,
            iconColor: const Color(0xFF8B5CF6),
            children: [
              _buildLabel('Sélectionner le Rôle'),
              _buildDogRolePicker(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAgeSlider() {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: AppColors.mistyBlue,
        inactiveTrackColor: const Color(0xFFF1F5F9),
        thumbColor: Colors.white,
        overlayColor: AppColors.mistyBlue.withValues(alpha: 0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 3),
      ),
      child: Slider(
        min: 0,
        max: 240,
        value: _ageInMonths,
        onChanged: (val) {
          setState(() {
            _ageInMonths = val;
            _ageMonthsController.text = val.toInt().toString();
          });
        },
      ),
    );
  }

  // ─── Step 3: Species-specific fields ────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health & Vaccines',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enregistrer le statut vaccinal passé pour générer un planning précis.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 28),

        if (_isLoadingRegulations)
          const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          ))
        else if (_regulations.isEmpty)
          _buildSectionCard(
            title: 'No specific regulations found',
            icon: Symbols.info,
            iconColor: Colors.blue,
            children: [
              const Text('Aucun vaccin obligatoire détecté pour cette zone. Ajoutez-en manuellement.'),
              const SizedBox(height: 16),
              _buildAddOtherButton(),
            ],
          )
        else
          _buildSectionCard(
            title: 'Recommended Vaccinations',
            icon: Symbols.medical_services,
            iconColor: AppColors.mistyBlue,
            children: [
              ..._regulations.map((reg) => _buildDynamicVaccineItem(reg)).toList(),
              const Divider(height: 32),
              _buildAddOtherButton(),
            ],
          ),

        const SizedBox(height: 24),
        
        // Show selected "Other" vaccines
        ..._vaccineSelections.entries
            .where((e) => e.value['isOther'] == true)
            .map((e) => _buildOtherVaccineItem(e.key))
            .toList(),

        const SizedBox(height: 24),
        _buildLabel('Observations & Notes'),
        _buildTextField(
          _notesController, 
          'Observations particulières...', 
          maxLines: 4,
          prefixIcon: Symbols.notes,
        ),
      ],
    );
  }

  Widget _buildAddOtherButton() {
    return TextButton.icon(
      onPressed: () {
        final id = 'OTHER_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _vaccineSelections[id] = {
            'checked': true,
            'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'dose': 1.0,
            'lot': '',
            'isOther': true,
            'name': '',
          };
        });
      },
      icon: const Icon(Symbols.add_circle, size: 20),
      label: const Text('Ajouter un autre vaccin'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mistyBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDynamicVaccineItem(VaccineRegulation reg) {
    final sel = _vaccineSelections[reg.vaccineId]!;
    final isChecked = sel['checked'] as bool;
    final isMandatory = reg.isMandatory;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isChecked ? AppColors.mistyBlue.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isChecked ? AppColors.mistyBlue.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            value: isChecked,
            onChanged: (val) => setState(() => sel['checked'] = val),
            title: Text(
              reg.vaccine?.nameFr ?? reg.vaccineId,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isChecked ? AppColors.mistyBlue : Colors.black87,
              ),
            ),
            subtitle: Text(
              isMandatory ? 'Obligatoire • ${reg.status}' : 'Recommandé',
              style: TextStyle(
                fontSize: 12,
                color: isMandatory ? Colors.red.withValues(alpha: 0.7) : Colors.grey,
              ),
            ),
            secondary: Icon(
              isMandatory ? Symbols.verified_user : Symbols.vaccines,
              color: isMandatory ? Colors.red.withValues(alpha: 0.5) : AppColors.mistyBlue,
            ),
            activeColor: AppColors.mistyBlue,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          if (isChecked)
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInlineDateField(sel),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      null,
                      'Dose (ml)',
                      initialValue: sel['dose'].toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => sel['dose'] = double.tryParse(v) ?? 1.0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtherVaccineItem(String id) {
    final sel = _vaccineSelections[id]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mistyBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Symbols.edit_note, color: AppColors.mistyBlue),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: sel['name'],
                  onChanged: (v) => sel['name'] = v,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Nom du vaccin (ex: Grippe)',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Symbols.delete, color: Colors.red, size: 20),
                onPressed: () => setState(() => _vaccineSelections.remove(id)),
              )
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(child: _buildInlineDateField(sel)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  null,
                  'Dose',
                  initialValue: sel['dose'].toString(),
                  onChanged: (v) => sel['dose'] = double.tryParse(v) ?? 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineDateField(Map<String, dynamic> sel) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(sel['date']),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            sel['date'] = DateFormat('yyyy-MM-dd').format(picked);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Symbols.calendar_today, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              sel['date'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// Card container reused in Step 3
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  /// 3-state pregnancy toggle: Oui / Non / Inconnu
  Widget _buildPregnancyToggle() {
    final options = [
      {'value': true,  'label': 'Oui',      'color': const Color(0xFF10B981)},
      {'value': false, 'label': 'Non',      'color': const Color(0xFFEF4444)},
      {'value': null,  'label': 'Inconnu',  'color': const Color(0xFF94A3B8)},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _isPregnant == opt['value'];
          final color = opt['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isPregnant = opt['value'] as bool?),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Dog role picker: Garde / Berger / Compagnie
  Widget _buildDogRolePicker() {
    final roles = [
      {'id': 'garde',     'label': 'Garde',     'icon': Symbols.shield},
      {'id': 'berger',    'label': 'Berger',    'icon': Symbols.groups},
      {'id': 'compagnie', 'label': 'Compagnie', 'icon': Symbols.favorite},
    ];

    return Row(
      children: roles.map((role) {
        final isSelected = _dogRole == role['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _dogRole = role['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mistyBlue.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.mistyBlue : const Color(0xFFF1F5F9),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    role['icon'] as IconData,
                    size: 22,
                    color: isSelected ? AppColors.mistyBlue : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.mistyBlue : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Generic styled dropdown
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14)),
        items: items,
        onChanged: onChanged,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF1F2937),
        ),
        icon: const Icon(Symbols.expand_more, color: Color(0xFF94A3B8)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.mistyBlue,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Widget _buildVaccineItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTextField(
              null,
              'Nom du vaccin',
              initialValue: _vaccines[index]['name'],
              onChanged: (val) => _vaccines[index]['name'] = val,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null) {
                  setState(() {
                    _vaccines[index]['date'] = picked.toIso8601String().split('T')[0];
                  });
                }
              },
              child: AbsorbPointer(
                child: _buildTextField(
                  null,
                  'AAAA-MM-JJ',
                  initialValue: _vaccines[index]['date'],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _vaccines.removeAt(index)),
            icon: const Icon(Symbols.delete, color: Color(0xFFEF4444), size: 20),
          ),
        ],
      ),
    );
  }

  // --- Common Components ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController? controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    String? suffix,
    int maxLines = 1,
    String? initialValue,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          contentPadding: const EdgeInsets.all(20),
          border: InputBorder.none,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 22) : null,
          suffixIcon: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(suffix, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              ],
            ),
          ) : null,
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    final isLastStep = _currentStep == 3;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.9),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                if (_currentStep > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildBackButton(),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () {
                      if (isLastStep) {
                        _submit();
                      } else {
                        setState(() => _currentStep++);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.mistBlue, AppColors.mistyBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.mistyBlue.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isLastStep ? Symbols.check_circle : Symbols.arrow_forward_ios_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                isLastStep
                                  ? (isEditMode ? 'Mettre à jour' : 'Enregistrer l\'animal')
                                  : 'Continuer',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => setState(() => _currentStep--),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: const Icon(Symbols.arrow_back_ios_new, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }
}