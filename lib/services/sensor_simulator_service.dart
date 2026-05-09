import 'api_service.dart';

enum SimulatorScenario {
  saine,
  mammite,
  fievre,
  boiterie,
  stress_thermique,
}

extension SimulatorScenarioExt on SimulatorScenario {
  String get value {
    switch (this) {
      case SimulatorScenario.saine:            return 'saine';
      case SimulatorScenario.mammite:          return 'mammite';
      case SimulatorScenario.fievre:           return 'fievre';
      case SimulatorScenario.boiterie:         return 'boiterie';
      case SimulatorScenario.stress_thermique: return 'stress_thermique';
    }
  }

  String get label {
    switch (this) {
      case SimulatorScenario.saine:            return '🟢 Healthy';
      case SimulatorScenario.mammite:          return '🔴 Mastitis';
      case SimulatorScenario.fievre:           return '🔴 Fever';
      case SimulatorScenario.boiterie:         return '🟡 Lameness';
      case SimulatorScenario.stress_thermique: return '🟡 Heat Stress';
    }
  }

  String get description {
    switch (this) {
      case SimulatorScenario.saine:
        return 'Normal physiological parameters. Temp ~38.7°C, HR ~65 bpm.';
      case SimulatorScenario.mammite:
        return 'Temp +0.9°C, HR +12 bpm, activity -25%. Mammary infection.';
      case SimulatorScenario.fievre:
        return 'Temp +1.8°C, HR +20 bpm, activity -40%. Bacterial/viral fever.';
      case SimulatorScenario.boiterie:
        return 'Gait asymmetry, activity -35%, lying +3h. Claw disease.';
      case SimulatorScenario.stress_thermique:
        return 'Temp +1.1°C, HR +15 bpm, activity -20%. Heat stress.';
    }
  }

  String get expectedScore {
    switch (this) {
      case SimulatorScenario.saine:            return '85–100';
      case SimulatorScenario.mammite:          return '40–60';
      case SimulatorScenario.fievre:           return '15–35';
      case SimulatorScenario.boiterie:         return '35–55';
      case SimulatorScenario.stress_thermique: return '60–75';
    }
  }
}

class SensorSimulatorService {
  /// Génère N jours d'historique simulé pour un animal
  static Future<Map<String, dynamic>> generateHistory({
    required String animalId,
    required SimulatorScenario scenario,
    int days = 2,
  }) async {
    final data = await ApiService.post(
      '/sensors/simulate/history',
      {
        'animalId': animalId,
        'scenario': scenario.value,
        'days': days,
      },
      withAuth: true,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Génère une seule lecture
  static Future<Map<String, dynamic>> generateReading({
    required String animalId,
    required SimulatorScenario scenario,
  }) async {
    final data = await ApiService.post(
      '/sensors/simulate',
      {
        'animalId': animalId,
        'scenario': scenario.value,
      },
      withAuth: true,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Supprime toutes les lectures d'un animal
  static Future<Map<String, dynamic>> clearReadings(String animalId) async {
    final data = await ApiService.delete(
      '/sensors/$animalId/clear',
      withAuth: true,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}
