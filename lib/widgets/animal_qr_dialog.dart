/// ============================================================
/// ANIMAL QR DIALOG — Affichage du QR code d'un animal
/// ============================================================
///
/// Ce widget affiche un QR code généré à partir du [nodeId] de l'animal.
/// Le nodeId est l'identifiant unique utilisé pour toutes les opérations
/// sur l'animal (vente, diagnostic, vaccins…).
///
/// Utilisé dans :
///   • add_animal_screen.dart → affiché automatiquement après création
///   • animal_details_screen.dart → accessible via bouton QR dans l'AppBar
///
/// L'agriculteur peut imprimer ce QR et le coller sur le collier/boucle
/// d'oreille de l'animal pour un accès rapide à sa fiche.
/// ============================================================
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/animal.dart';
import '../utils/animal_utils.dart';

class AnimalQrDialog extends StatelessWidget {
  final Animal animal;

  const AnimalQrDialog({super.key, required this.animal});

  /// Affiche le dialog QR code pour un animal.
  /// Méthode statique utilitaire pour simplifier l'appel.
  static Future<void> show(BuildContext context, Animal animal) {
    return showDialog<void>(
      context: context,
      builder: (_) => AnimalQrDialog(animal: animal),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le QR code encode le nodeId de l'animal — identifiant unique
    final qrData = animal.nodeId;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── En-tête avec emoji et nom de l'animal ──────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF309448).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AnimalUtils.getAnimalEmoji(animal.animalType),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        animal.tagNumber != null
                            ? 'Tag: ${animal.tagNumber}'
                            : animal.nodeId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── QR Code ────────────────────────────────────────────────
            // Le QR encode le nodeId — scannable pour accéder à la fiche
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF309448).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF309448).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                // Logo au centre du QR (emoji animal)
                embeddedImage: null,
              ),
            ),

            const SizedBox(height: 16),

            // ── Instruction ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scannez ce QR pour accéder directement à la fiche de ${animal.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── ID encodé ─────────────────────────────────────────────
            Text(
              'ID: $qrData',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // ── Bouton fermer ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF309448),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
