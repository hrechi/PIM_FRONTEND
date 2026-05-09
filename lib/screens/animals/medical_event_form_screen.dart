import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vaccine_models.dart' show MedicalEvent;
import '../../services/medical_event_service.dart';

class MedicalEventFormScreen extends StatefulWidget {
  final String animalId;
  final String animalName;
  final MedicalEvent? existingEvent; // null = création, non-null = édition

  const MedicalEventFormScreen({
    super.key,
    required this.animalId,
    required this.animalName,
    this.existingEvent,
  });

  @override
  State<MedicalEventFormScreen> createState() => _MedicalEventFormScreenState();
}

class _MedicalEventFormScreenState extends State<MedicalEventFormScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _vetNameCtrl   = TextEditingController();
  final _costCtrl      = TextEditingController();
  final _notesCtrl     = TextEditingController();

  String   _eventType = 'visit';
  DateTime _eventDate = DateTime.now();
  bool     _saving    = false;

  static const _kGreen = Color(0xFF309448);

  // Types disponibles avec icône + couleur
  static const _types = [
    {'value': 'visit',     'label': 'Vet Visit',    'icon': Icons.medical_services,  'color': Color(0xFF1565C0)},
    {'value': 'disease',   'label': 'Disease',      'icon': Icons.coronavirus,        'color': Color(0xFFDC2626)},
    {'value': 'surgery',   'label': 'Surgery',      'icon': Icons.healing,            'color': Color(0xFF7B1FA2)},
    {'value': 'treatment', 'label': 'Treatment',    'icon': Icons.medication,         'color': Color(0xFFE65100)},
    {'value': 'checkup',   'label': 'Checkup',      'icon': Icons.fact_check,         'color': Color(0xFF2E7D32)},
    {'value': 'other',     'label': 'Other',        'icon': Icons.more_horiz,         'color': Color(0xFF546E7A)},
  ];

  bool get _isEdit => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existingEvent!;
      _eventType           = e.eventType.toLowerCase();
      _eventDate           = e.eventDate;
      _diagnosisCtrl.text  = e.diagnosis ?? '';
      _treatmentCtrl.text  = e.treatment ?? '';
      _vetNameCtrl.text    = e.vetName   ?? '';
      _costCtrl.text       = e.cost != null ? e.cost!.toStringAsFixed(0) : '';
      _notesCtrl.text      = e.notes     ?? '';
    }
  }

  @override
  void dispose() {
    _diagnosisCtrl.dispose();
    _treatmentCtrl.dispose();
    _vetNameCtrl.dispose();
    _costCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'eventType': _eventType,
        'eventDate': _eventDate.toIso8601String(),
        if (_diagnosisCtrl.text.trim().isNotEmpty) 'diagnosis': _diagnosisCtrl.text.trim(),
        if (_treatmentCtrl.text.trim().isNotEmpty) 'treatment': _treatmentCtrl.text.trim(),
        if (_vetNameCtrl.text.trim().isNotEmpty)   'vetName':   _vetNameCtrl.text.trim(),
        if (_costCtrl.text.trim().isNotEmpty)      'cost':      double.tryParse(_costCtrl.text.trim()),
        if (_notesCtrl.text.trim().isNotEmpty)     'notes':     _notesCtrl.text.trim(),
      };

      if (_isEdit) {
        await MedicalEventService.update(
          widget.animalId,
          widget.existingEvent!.id,
          payload,
        );
      } else {
        await MedicalEventService.create(widget.animalId, payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Event updated' : 'Event added'),
            backgroundColor: _kGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // true = refresh la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  Map<String, dynamic> get _selectedType =>
      _types.firstWhere((t) => t['value'] == _eventType, orElse: () => _types.first);

  Color get _typeColor => _selectedType['color'] as Color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? 'Edit Event' : 'New Medical Event',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              widget.animalName,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen)),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Save', style: TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Event type chips ──────────────────────────
            _sectionLabel('Event Type'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _eventType == t['value'];
                final color    = t['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _eventType = t['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: 1.5),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withAlpha(60), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t['icon'] as IconData, size: 15, color: selected ? Colors.white : color),
                        const SizedBox(width: 6),
                        Text(
                          t['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Date picker ───────────────────────────────
            _sectionLabel('Event Date'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: _typeColor),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM dd, yyyy').format(_eventDate),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Diagnosis ─────────────────────────────────
            _buildField(
              controller: _diagnosisCtrl,
              label: 'Diagnosis',
              hint: 'e.g. Acute mastitis, right quarter',
              icon: Icons.search,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // ── Treatment ─────────────────────────────────
            _buildField(
              controller: _treatmentCtrl,
              label: 'Treatment',
              hint: 'e.g. Antibiotics 5 days + anti-inflammatory',
              icon: Icons.medication_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // ── Vet + Cost on same row ────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(
                    controller: _vetNameCtrl,
                    label: 'Veterinarian',
                    hint: 'Dr. Benali',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildField(
                    controller: _costCtrl,
                    label: 'Cost (TND)',
                    hint: '150',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Notes ─────────────────────────────────────
            _buildField(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'Additional observations...',
              icon: Icons.note_outlined,
              maxLines: 4,
              alignLabelWithHint: true,
            ),

            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isEdit ? Icons.save_outlined : Icons.add_circle_outline),
                label: Text(
                  _isEdit ? 'Update Event' : 'Add Event',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.3),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool alignLabelWithHint = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _typeColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
