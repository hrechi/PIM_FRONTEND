import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import 'add_animal_screen.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final Animal animal;
  const AnimalDetailsScreen({super.key, required this.animal});

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  final AnimalService _animalService = AnimalService();
  late Animal _animal;
  bool _isDeleting = false;
  final DateFormat _df = DateFormat('dd MMM yyyy');
  final NumberFormat _nf = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  String _calculateFormattedAge() {
    final months = _animal.age;
    if (months < 12) return '$months Mois';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years ${years == 1 ? 'An' : 'Ans'}';
    return '$years ${years == 1 ? 'An' : 'Ans'}, $remainingMonths Mois';
  }

  Future<void> _deleteAnimal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${_animal.name} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _animalService.deleteAnimal(_animal.nodeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal supprimé'), backgroundColor: Color(0xFFEF4444)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      children: [
                        _buildHeroImage(),
                        _buildIdentitySection(),
                        _buildHealthRiskBanner(),
                        _buildStatusAndAgeTiles(),
                        _buildSpeciesSpecificInfo(),
                        _buildFinanceSection(),
                        _buildMedicalSection(),
                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIconButton(Symbols.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
          Text(
            'Profil: ${_animal.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          _buildCircleIconButton(Symbols.more_horiz, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
      ]),
      child: IconButton(icon: Icon(icon, color: AppColors.mistyBlue, size: 20), onPressed: onPressed),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(32)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _animal.profileImage != null
                ? Image.network(_animal.profileImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Container(
                    color: AppColors.mistyBlue.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(_getAnimalIcon(_animal.animalType), size: 100, color: AppColors.mistyBlue.withValues(alpha: 0.2)),
                    ),
                  ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _animal.status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    Text(_animal.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Node ID: ${_animal.nodeId}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.mistyBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_getAnimalEmoji(_animal.animalType), style: const TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChip(_animal.breed ?? 'Race inconnue', Symbols.pets),
              _buildChip(_animal.sex == 'female' ? 'Femelle' : 'Mâle', _animal.sex == 'female' ? Symbols.female : Symbols.male),
              if (_animal.tagNumber != null) _buildChip(_animal.tagNumber!, Symbols.sell),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildHealthRiskBanner() {
    final score = _animal.healthRiskScore ?? 0.0;
    Color color = Colors.green;
    String label = 'Risque Faible';
    if (score > 0.6) { color = Colors.red; label = 'Risque Élevé'; }
    else if (score > 0.3) { color = Colors.orange; label = 'Risque Modéré'; }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Symbols.analytics, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SCORE DE RISQUE SANTÉ (IA)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
          Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusAndAgeTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildInfoTile('Âge', _calculateFormattedAge(), Symbols.calendar_today, Colors.blue),
          const SizedBox(width: 16),
          _buildInfoTile('Poids', _animal.weight != null ? '${_animal.weight} kg' : 'N/A', Symbols.weight, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesSpecificInfo() {
    final type = _animal.animalType.toLowerCase();
    final isFemale = _animal.sex == 'female';

    List<Widget> children = [];

    if (type == 'cow' && isFemale) {
      children.add(_buildSectionTitle('Reproduction & Lait 🐄'));
      children.add(_buildDetailRow('Gestante', _animal.isPregnant == true ? 'OUI' : (_animal.isPregnant == false ? 'NON' : 'INCONNU')));
      if (_animal.expectedBirthDate != null) children.add(_buildDetailRow('Date mise-bas prévue', _df.format(_animal.expectedBirthDate!)));
      children.add(_buildDetailRow('Portées', '${_animal.birthCount}'));
      children.add(_buildDetailRow('Production moyenne', _animal.dailyMilkAvgL != null ? '${_animal.dailyMilkAvgL} L/j' : 'N/A'));
      children.add(_buildDetailRow('N° Lactation', _animal.lactationNumber?.toString() ?? 'N/A'));
    } else if (type == 'horse') {
      children.add(_buildSectionTitle('Performance 🐎'));
      children.add(_buildDetailRow('Catégorie', _animal.raceCategory?.toUpperCase() ?? 'N/A'));
      children.add(_buildDetailRow('Meilleur temps', _animal.bestRaceTime != null ? '${_animal.bestRaceTime}s' : 'N/A'));
      children.add(_buildDetailRow('Entraînement', _animal.trainingLevel?.toUpperCase() ?? 'N/A'));
    } else if (type == 'sheep') {
      children.add(_buildSectionTitle('Production & Qualité 🐑'));
      children.add(_buildDetailRow('Dernière tonte', _animal.woolLastShearDate != null ? _df.format(_animal.woolLastShearDate!) : 'N/A'));
      children.add(_buildDetailRow('Grade viande', _animal.meatGrade ?? 'N/A'));
    } else if (type == 'dog') {
      children.add(_buildSectionTitle('Utilisation 🐕'));
      children.add(_buildDetailRow('Rôle', _animal.dogRole?.toUpperCase() ?? 'N/A'));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildFinanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Finance & Valeur 💰'),
          _buildDetailRow('Prix d\'achat', _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
          _buildDetailRow('Date d\'achat', _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
          _buildDetailRow('Valeur estimée', _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A'),
          if (_animal.status == 'sold') ...[
            _buildDetailRow('Prix de vente', _animal.salePrice != null ? _nf.format(_animal.salePrice) : 'N/A'),
            _buildDetailRow('Date de vente', _animal.saleDate != null ? _df.format(_animal.saleDate!) : 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Historique Médical 🩺'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${_animal.diseaseHistoryCount} Événements', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_animal.vaccineRecords == null || _animal.vaccineRecords!.isEmpty)
            const Text('Aucun vaccin enregistré.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))
          else
            ..._animal.vaccineRecords!.map((v) => _buildMedicalItem(v.vaccineName, _df.format(v.vaccineDate), Symbols.vaccines, Colors.amber)),
          
          if (_animal.medicalEvents != null && _animal.medicalEvents!.isNotEmpty) ...[
            const Divider(height: 32),
            ..._animal.medicalEvents!.map((e) => _buildMedicalItem(e.eventType.toUpperCase(), _df.format(e.eventDate), Symbols.medical_services, Colors.blue, subtitle: e.diagnosis)),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalItem(String title, String date, IconData icon, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    if (_animal.notes == null || _animal.notes!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFEF3C7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOTES 📝', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
          const SizedBox(height: 12),
          Text(_animal.notes!, style: const TextStyle(fontSize: 14, color: Color(0xFF92400E), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: _isDeleting ? null : _deleteAnimal,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0), width: 2)),
                  child: const Center(child: Text('Supprimer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF64748B)))),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddAnimalScreen(animal: _animal)));
                  if (updated == true && mounted) Navigator.pop(context, true);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF32ADE6)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF34C759).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Symbols.edit, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier le profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAnimalIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cow': return Symbols.cruelty_free;
      case 'sheep': return Symbols.pest_control_rodent;
      case 'horse': return Symbols.emoji_nature;
      case 'dog': return Symbols.sound_detection_dog_barking;
      default: return Symbols.pets;
    }
  }

  String _getAnimalEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'cow': return '🐄';
      case 'sheep': return '🐑';
      case 'horse': return '🐎';
      case 'dog': return '🐕';
      default: return '🐾';
    }
  }
}