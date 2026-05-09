# 📈 Module Graphiques Capteurs Temps Réel

## 🎯 Fonctionnalités

### ✅ Implémenté

1. **SensorGraphScreen** — Écran principal avec 3 graphiques :
   - 🌡️ Température (°C) avec zone normale 38-39.5°C
   - ❤️ Fréquence cardiaque (bpm) avec zone normale 50-80 bpm
   - 🏃 Score d'activité (0-100) avec zone normale 30-70

2. **Zones d'alerte colorées** :
   - Bandes verticales rouges/orange/jaunes sur les graphiques
   - Indiquent les périodes où l'IA a détecté une anomalie

3. **Sélecteur de période** :
   - 6 heures
   - 24 heures (par défaut)
   - 7 jours

4. **Bouton actualiser** :
   - Recharge les données en temps réel
   - Icône refresh dans l'AppBar

5. **Cartes résumé** :
   - Moyennes sur la période sélectionnée
   - Température / FC / Activité

6. **Liste des alertes** :
   - Affiche toutes les alertes détectées
   - Niveau (critical/medium/low)
   - Maladie suspectée
   - Confiance du modèle

---

## 🚀 Utilisation

### Navigation vers l'écran

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SensorGraphScreen(
      animalId: 'uuid-de-l-animal',
      animalName: 'Marguerite',
    ),
  ),
);
```

### Exemple d'intégration dans une liste d'animaux

```dart
ListTile(
  title: Text(animal.name),
  subtitle: Text('Score santé : ${animal.healthScore}/100'),
  trailing: IconButton(
    icon: const Icon(Icons.show_chart),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SensorGraphScreen(
            animalId: animal.id,
            animalName: animal.name,
          ),
        ),
      );
    },
  ),
)
```

---

## 📊 Structure des Données

### Endpoint Backend

```
GET /animal-health/sensors/:animalId/history?period=24
```

**Réponse** :
```json
{
  "animal": {
    "id": "uuid",
    "name": "Marguerite",
    "type": "cow",
    "healthStatus": "OPTIMAL"
  },
  "period": {
    "hours": 24,
    "start": "2026-05-03T10:00:00.000Z",
    "end": "2026-05-04T10:00:00.000Z"
  },
  "data": [
    {
      "timestamp": "2026-05-03T10:00:00.000Z",
      "temperature": { "avg": 38.7, "min": 38.5, "max": 38.9 },
      "heartRate": { "avg": 65, "min": 60, "max": 70 },
      "activity": { "avg": 45, "min": 30, "max": 60 },
      "accelerometer": { "x": 0.1, "y": 9.7, "z": 0.2 },
      "lyingPercent": 45,
      "readingsCount": 12
    }
  ],
  "alertZones": [
    {
      "startTime": "2026-05-03T14:00:00.000Z",
      "endTime": "2026-05-03T15:00:00.000Z",
      "level": "medium",
      "disease": "mammite",
      "confidence": 0.75,
      "anomalyScore": 0.82
    }
  ],
  "summary": {
    "totalReadings": 288,
    "dataPoints": 24,
    "alertsCount": 1,
    "avgTemperature": 38.7,
    "avgHeartRate": 65,
    "avgActivity": 45
  }
}
```

---

## 🎨 Personnalisation

### Changer les couleurs des graphiques

Dans `sensor_graph_screen.dart` :

```dart
Widget _buildTemperatureChart() {
  return _buildChartCard(
    title: '🌡️ Température (°C)',
    color: Colors.red,  // ← Changer ici
    // ...
  );
}
```

### Modifier les zones normales

```dart
Widget _buildTemperatureChart() {
  return _buildChartCard(
    // ...
    normalRange: [38.0, 39.5],  // ← Ajuster ici
  );
}
```

### Ajouter un nouveau graphique

```dart
Widget _buildRuminationChart() {
  return _buildChartCard(
    title: '🐮 Rumination (min/h)',
    color: Colors.purple,
    data: _history!.data
        .where((d) => d.rumination?.avg != null)
        .map((d) => FlSpot(
              d.timestamp.millisecondsSinceEpoch.toDouble(),
              d.rumination!.avg!,
            ))
        .toList(),
    minY: 0.0,
    maxY: 60.0,
    normalRange: [20.0, 40.0],
  );
}
```

---

## 🐛 Dépannage

### Erreur "Animal not found"
- Vérifier que l'`animalId` est correct
- Vérifier que l'utilisateur a accès à cet animal

### Graphiques vides
- Vérifier qu'il y a des données capteurs dans `SensorReading`
- Vérifier la période sélectionnée (peut-être pas de données sur 7j)

### Zones d'alerte ne s'affichent pas
- Vérifier qu'il y a des `HealthAlert` dans la base
- Vérifier que les timestamps correspondent

### Performance lente
- Réduire la période (6h au lieu de 7j)
- Implémenter le cache Redis côté backend
- Limiter le nombre de points affichés

---

## 🔄 Améliorations Futures

### Court terme
- [ ] Pull-to-refresh
- [ ] Export PDF des graphiques
- [ ] Zoom/pan sur les graphiques
- [ ] Comparaison multi-animaux

### Moyen terme
- [ ] Graphiques en temps réel (WebSocket)
- [ ] Prédictions futures (tendances)
- [ ] Alertes push quand anomalie détectée
- [ ] Mode hors-ligne avec cache local

### Long terme
- [ ] Dashboard personnalisable
- [ ] Rapports vétérinaires automatiques
- [ ] Intégration avec capteurs IoT
- [ ] Machine learning on-device

---

## 📚 Dépendances

```yaml
dependencies:
  fl_chart: ^0.68.0  # Graphiques
  intl: ^0.20.2      # Formatage dates
  http: ^1.2.2       # Requêtes API
```

---

## 🤝 Contribution

Pour ajouter un nouveau type de graphique :

1. Ajouter le champ dans `SensorDataPoint` (models/sensor_history.dart)
2. Modifier l'agrégation backend (animal-health.service.ts)
3. Créer la méthode `_buildXxxChart()` dans sensor_graph_screen.dart
4. Ajouter l'appel dans `_buildContent()`

---

**Auteur** : Équipe PastureAI  
**Date** : 2026-05-04  
**Version** : 1.0
