import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';

class AddAnimalScreen extends StatefulWidget {
  final Animal? animal;
  const AddAnimalScreen({super.key, this.animal});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnimalService _animalService = AnimalService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _tagController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _notesController = TextEditingController();
  final _milkYieldController = TextEditingController();
  final _lastBirthDateController = TextEditingController();
  final _lastInseminationDateController = TextEditingController();
  final _roleController = TextEditingController();
  final _woolYieldController = TextEditingController();
  
  // State
  int _currentStep = 1;
  String _selectedType = 'COW';
  String _selectedSex = 'FEMALE';
  double _ageInMonths = 24;
  bool _isVaccinated = false;
  bool? _isPregnant = false;
  String _productionHabit = 'NORMAL';
  String _selectedRole = 'GUARD';
  bool _isLoading = false;

  // Vaccine list
  List<Map<String, dynamic>> _vaccines = [];

  bool get isEditMode => widget.animal != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final a = widget.animal!;
      _nameController.text = a.name;
      _breedController.text = a.breed ?? '';
      _tagController.text = a.tagNumber ?? '';
      _notesController.text = a.notes ?? '';
      _selectedType = a.animalType;
      _selectedSex = a.sex;
      _ageInMonths = a.age.toDouble();
      _isVaccinated = a.vaccination;
      _vaccines = a.vaccines != null ? List<Map<String, dynamic>>.from(a.vaccines!) : [];
      _productionHabit = a.productionHabit ?? 'NORMAL';
      _isPregnant = a.isPregnant;
      _selectedRole = a.role ?? 'GUARD';
      _milkYieldController.text = a.milkYield?.toString() ?? '';
      _woolYieldController.text = a.woolYield?.toString() ?? '';
      _lastBirthDateController.text = a.lastBirthDate?.toIso8601String().split('T')[0] ?? '';
      _lastInseminationDateController.text = a.lastInseminationDate?.toIso8601String().split('T')[0] ?? '';
      _roleController.text = a.role ?? '';
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _tagController.dispose();
    _ageMonthsController.dispose();
    _notesController.dispose();
    _milkYieldController.dispose();
    _woolYieldController.dispose(); // NEW
    _lastBirthDateController.dispose();
    _lastInseminationDateController.dispose();
    _roleController.dispose();
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
        'tagNumber': _tagController.text,
        'notes': _notesController.text,
        'vaccination': _isVaccinated,
        'vaccines': _isVaccinated ? _vaccines : null,
        'productionHabit': (_selectedType == 'COW' || _selectedType == 'SHEEP' || _selectedType == 'HORSE') 
            ? _productionHabit 
            : null,
        'milkYield': _selectedType == 'COW' ? double.tryParse(_milkYieldController.text) : null,
        'woolYield': _selectedType == 'SHEEP' ? double.tryParse(_woolYieldController.text) : null,
        'isPregnant': _selectedSex == 'FEMALE' ? _isPregnant : null,
        'lastInseminationDate': _selectedSex == 'FEMALE' && _lastInseminationDateController.text.isNotEmpty 
            ? DateTime.parse(_lastInseminationDateController.text).toUtc().toIso8601String()
            : null,
        'lastBirthDate': _selectedSex == 'FEMALE' && _lastBirthDateController.text.isNotEmpty 
            ? DateTime.parse(_lastBirthDateController.text).toUtc().toIso8601String()
            : null,
        'role': _selectedType == 'DOG' ? _selectedRole : null,
      };

      if (isEditMode) {
        await _animalService.updateAnimal(widget.animal!.nodeId, animalData);
      } else {
        await _animalService.createAnimal(animalData);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditMode ? 'Animal updated successfully!' : 'Animal added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _buildIconButton(Symbols.arrow_back_ios_new),
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
        _buildStepIndicator(3, 'History', _currentStep >= 3),
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

  // --- Step 1: Species Selection ---
  Widget _buildStep1() {
    final types = [
      {'id': 'COW', 'label': 'Cow', 'icon': Symbols.cruelty_free},
      {'id': 'SHEEP', 'label': 'Sheep', 'icon': Symbols.pest_control_rodent},
      {'id': 'HORSE', 'label': 'Horse', 'icon': Symbols.emoji_nature},
      {'id': 'DOG', 'label': 'Dog', 'icon': Symbols.sound_detection_dog_barking},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onTap: isEditMode ? null : () => setState(() => _selectedType = type['id'] as String),
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
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.mistyBlue.withValues(alpha: 0.1) 
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        type['icon'] as IconData,
                        size: 28,
                        color: isSelected ? AppColors.mistyBlue : const Color(0xFF94A3B8),
                      ),
                    ),
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
            _buildGenderOption('FEMALE', Symbols.female),
            const SizedBox(width: 16),
            _buildGenderOption('MALE', Symbols.male),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String id, IconData icon) {
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
                id,
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

  // --- Step 2: Profile Details ---
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
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             _buildLabel('Age Range'),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
               decoration: BoxDecoration(
                 color: AppColors.mistyBlue.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Text(
                 '${_ageInMonths.toInt()} Months',
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
          'Exact months', 
          keyboardType: TextInputType.number,
          suffix: 'MONTHS',
        ),
        
        const SizedBox(height: 24),
        _buildLabel('Tag / Node ID'),
        _buildTextField(
          _tagController, 
          'SCAN-004-921',
          prefixIcon: Symbols.qr_code_2,
          readOnly: isEditMode, // Prevent node ID edit if already exists
        ),
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

  // --- Step 3: Management & History ---
  Widget _buildStep3() {
    final showProduction = _selectedType == 'COW' || _selectedType == 'SHEEP';
    final showReproduction = _selectedSex == 'FEMALE';
    final isCow = _selectedType == 'COW';
    final isDog = _selectedType == 'DOG';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specialized Features: $_selectedType',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        
        if (isCow && showReproduction) _buildCowFemaleReproduction(),
        if (isCow && showReproduction) ...[
          const SizedBox(height: 24),
          _buildMilkProductionSection(),
        ],

        if (_selectedType == 'SHEEP' && showReproduction) ...[
          const SizedBox(height: 24),
          _buildWoolProductionSection(),
        ],
        
        if (isDog) _buildDogRoleSection(),

        const SizedBox(height: 32),
        const Text(
          'General Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        
        // Vaccination Toggle
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vaccination Status',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                      ),
                      Text(
                        'Include medical history',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Switch.adaptive(
                    value: _isVaccinated,
                    activeColor: AppColors.fieldFreshStart,
                    onChanged: (val) => setState(() => _isVaccinated = val),
                  ),
                ],
              ),
              if (_isVaccinated) ...[
                const Divider(height: 32, color: Color(0xFFF1F5F9)),
                ...List.generate(_vaccines.length, (index) => _buildVaccineItem(index)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _addVaccine,
                  icon: const Icon(Symbols.add_circle, size: 20),
                  label: const Text('Add Vaccine Record'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mistyBlue,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        if (showProduction && !isDog) ...[
          const SizedBox(height: 32),
          _buildLabel('Production Habit'),
          const SizedBox(height: 12),
          _buildSegmentedControl(),
        ],
        
        const SizedBox(height: 32),
        _buildLabel('Notes'),
        _buildTextField(_notesController, 'Any special observations...', maxLines: 3),
      ],
    );
  }

  Widget _buildCowFemaleReproduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Reproduction Status (FEMALE COW)'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Is Pregnant?', style: TextStyle(fontWeight: FontWeight.w700)),
                  Switch.adaptive(
                    value: _isPregnant ?? false,
                    onChanged: (val) => setState(() => _isPregnant = val),
                  ),
                ],
              ),
              const Divider(),
              _buildDateField(_lastInseminationDateController, 'Last Insemination'),
              const SizedBox(height: 12),
              _buildDateField(_lastBirthDateController, 'Last Calving Date'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilkProductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Milk Production'),
        _buildTextField(
          _milkYieldController, 
          'Avg Production (L/day)', 
          keyboardType: TextInputType.number,
          suffix: 'LITERS',
        ),
      ],
    );
  }

  Widget _buildWoolProductionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Wool Production'),
        _buildTextField(
          _woolYieldController, 
          'Avg Yield (kg/year)', 
          keyboardType: TextInputType.number,
          suffix: 'KG',
        ),
      ],
    );
  }

  Widget _buildDogRoleSection() {
    final roles = [
      {'id': 'GUARD', 'label': 'Guard Dog', 'icon': Symbols.shield},
      {'id': 'SHEPHERD', 'label': 'Shepherd Dog', 'icon': Symbols.groups},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Dog Role'),
        Row(
          children: roles.map((role) {
            final isSelected = _selectedRole == role['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedRole = role['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mistyBlue.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.mistyBlue : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(role['icon'] as IconData, size: 20, color: isSelected ? AppColors.mistyBlue : const Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        role['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
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
        ),
      ],
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

  Widget _buildDateField(TextEditingController controller, String label) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _selectDate(controller),
            child: AbsorbPointer(
              child: _buildTextField(controller, 'YYYY-MM-DD', prefixIcon: Symbols.calendar_month),
            ),
          ),
        ),
      ],
    );
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
              'Vaccine Name',
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
                  'YYYY-MM-DD',
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

  Widget _buildSegmentedControl() {
    final options = [
      {'id': 'ACTIVE', 'label': 'Active Producer'},
      {'id': 'NORMAL', 'label': 'Normal'},
      {'id': 'LESS', 'label': 'Less Productive'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _productionHabit == opt['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _productionHabit = opt['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF1F2937) : const Color(0xFF64748B),
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
                          colors: [AppColors.fieldFreshStart, AppColors.mistyBlue],
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
                                  ? (isEditMode ? 'Update Animal Profile' : 'Save Animal Profile') 
                                  : 'Continue',
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
