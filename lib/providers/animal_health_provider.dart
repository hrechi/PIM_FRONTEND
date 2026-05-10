/// ============================================================
/// ANIMAL HEALTH PROVIDER — Gestion d'état pour le diagnostic IA
/// ============================================================
///
/// Ce Provider (pattern ChangeNotifier de Flutter) gère l'état
/// du diagnostic de santé animale basé sur l'IA PastureAI.
///
/// Architecture :
///   • Chaque animal a son propre état de diagnostic (cache par animalId)
///   • Le diagnostic appelle le backend NestJS → Python FastAPI (XGBoost)
///   • Les résultats sont mis en cache pour éviter les appels redondants
///
/// États possibles par animal :
///   idle    → Aucun diagnostic lancé
///   loading → Diagnostic en cours (appel API)
///   success → Résultat disponible dans _results[animalId]
///   error   → Erreur stockée dans _errors[animalId]
///
/// Flux de données :
///   Flutter UI → AnimalHealthProvider.runDiagnostic()
///             → AnimalHealthService.diagnose()
///             → POST /animal-health/:id/diagnose (NestJS)
///             → POST /predict (Python FastAPI — XGBoost + Isolation Forest)
///             → Résultat DiagnosisResult → UI mise à jour
///
/// Utilisé dans : animal_details_screen.dart
/// ============================================================
import 'package:flutter/foundation.dart';
import '../models/animal_health_models.dart';
import '../services/animal_health_service.dart';

export '../models/animal_health_models.dart';

/// États possibles du diagnostic pour un animal donné
enum DiagnosisState { idle, loading, success, error }

class AnimalHealthProvider extends ChangeNotifier {
  // ── Cache des résultats de diagnostic par animal ──────────
  // Clé : animalId (UUID), Valeur : dernier résultat de diagnostic
  final Map<String, DiagnosisResult> _results = {};

  // ── État de chargement par animal ─────────────────────────
  final Map<String, DiagnosisState>  _states  = {};

  // ── Messages d'erreur par animal ──────────────────────────
  final Map<String, String>          _errors  = {};

  // ── Alertes de santé globales (tous animaux) ──────────────
  List<HealthAlert> _alerts = [];
  bool _alertsLoading = false;
  String? _alertsError;

  // ── Statut du service IA Python (online/offline) ──────────
  bool? _aiOnline;

  // ── Getters publics ───────────────────────────────────────

  /// Dernier résultat de diagnostic pour un animal donné (null si pas encore diagnostiqué)
  DiagnosisResult? resultFor(String animalId) => _results[animalId];

  /// État actuel du diagnostic pour un animal
  DiagnosisState   stateFor(String animalId)  => _states[animalId] ?? DiagnosisState.idle;

  /// Message d'erreur pour un animal (null si pas d'erreur)
  String?          errorFor(String animalId)  => _errors[animalId];

  /// Raccourci : true si le diagnostic est en cours pour cet animal
  bool isLoading(String animalId)             => stateFor(animalId) == DiagnosisState.loading;

  List<HealthAlert> get alerts        => _alerts;
  bool              get alertsLoading => _alertsLoading;
  String?           get alertsError   => _alertsError;

  /// null = statut inconnu, true = IA en ligne, false = IA hors ligne
  bool?             get aiOnline      => _aiOnline;

  // ── Lancement du diagnostic IA ────────────────────────────

  /// Lance le diagnostic IA pour un animal.
  /// Appelle le backend NestJS qui transmet au serveur Python FastAPI.
  /// Le résultat est mis en cache dans _results[animalId].
  Future<DiagnosisResult?> runDiagnostic(String animalId) async {
    _states[animalId] = DiagnosisState.loading;
    _errors.remove(animalId);
    notifyListeners(); // Déclenche le rebuild des widgets qui écoutent

    try {
      final result = await AnimalHealthService.diagnose(animalId);
      _results[animalId] = result;
      _states[animalId]  = DiagnosisState.success;
      notifyListeners();
      return result;
    } catch (e) {
      _states[animalId] = DiagnosisState.error;
      _errors[animalId] = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Chargement des alertes de santé ──────────────────────

  /// Charge les dernières alertes de santé pour tous les animaux de l'agriculteur.
  /// Les alertes sont générées automatiquement par le CRON de diagnostic.
  Future<void> loadAlerts({int limit = 20}) async {
    _alertsLoading = true;
    _alertsError   = null;
    notifyListeners();
    try {
      _alerts = await AnimalHealthService.getAlerts(limit: limit);
    } catch (e) {
      _alertsError = e.toString();
    } finally {
      _alertsLoading = false;
      notifyListeners();
    }
  }

  // ── Vérification du statut du service IA ─────────────────

  /// Vérifie si le serveur Python FastAPI (PastureAI) est accessible.
  /// Utilisé pour afficher un avertissement si l'IA est hors ligne.
  Future<void> checkAiStatus() async {
    try {
      await AnimalHealthService.getAiStatus();
      _aiOnline = true;
    } catch (_) {
      _aiOnline = false;
    }
    notifyListeners();
  }

  // ── Nettoyage du cache ────────────────────────────────────

  /// Supprime les données de diagnostic d'un animal du cache.
  /// Appelé quand l'animal est supprimé ou quand on veut forcer un nouveau diagnostic.
  void clearAnimal(String animalId) {
    _results.remove(animalId);
    _states.remove(animalId);
    _errors.remove(animalId);
    notifyListeners();
  }
}
