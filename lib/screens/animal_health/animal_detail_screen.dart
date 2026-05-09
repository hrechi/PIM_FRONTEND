import 'package:flutter/material.dart';
import 'sensor_graph_screen.dart';
import '../../services/animal_health_service.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;
  final String animalName;

  const AnimalDetailScreen({
    Key? key,
    required this.animalId,
    required this.animalName,
  }) : super(key: key);

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  Map<String, dynamic>? _diagnosis;
  bool _isLoading = false;

  Future<void> _runDiagnosis() async {
    setState(() => _isLoading = true);
    try {
      final result = await AnimalHealthService.diagnoseAnimal(widget.animalId);
      setState(() {
        _diagnosis = result;
        _isLoading = false;
      });
      
      // Afficher un snackbar avec le résultat
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Score de santé : ${result['health_score']}/100',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: _getHealthColor(result['alert_level']),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getHealthColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animalName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte de diagnostic
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      '🩺 Diagnostic IA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_diagnosis != null) ...[
                      _buildDiagnosisResult(),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runDiagnosis,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isLoading ? 'Analyse en cours...' : 'Lancer le diagnostic'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton vers les graphiques
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorGraphScreen(
                      animalId: widget.animalId,
                      animalName: widget.animalName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.show_chart),
              label: const Text('Voir les graphiques capteurs'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisResult() {
    final healthScore = _diagnosis!['health_score'];
    final alertLevel = _diagnosis!['alert_level'];
    final disease = _diagnosis!['predicted_disease'];
    final confidence = _diagnosis!['confidence'];

    return Column(
      children: [
        // Score de santé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getHealthColor(alertLevel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getHealthColor(alertLevel)),
          ),
          child: Column(
            children: [
              Text(
                '$healthScore',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getHealthColor(alertLevel),
                ),
              ),
              const Text(
                'Score de Vitalité',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Maladie détectée
        if (disease != null) ...[
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pathologie suspectée',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      disease,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Confiance : ${(confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                'Animal en bonne santé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
