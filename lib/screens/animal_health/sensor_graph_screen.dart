import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/sensor_history.dart';
import '../../services/animal_health_service.dart';

class SensorGraphScreen extends StatefulWidget {
  final String animalId;
  final String animalName;

  const SensorGraphScreen({
    Key? key,
    required this.animalId,
    required this.animalName,
  }) : super(key: key);

  @override
  State<SensorGraphScreen> createState() => _SensorGraphScreenState();
}

class _SensorGraphScreenState extends State<SensorGraphScreen> {
  SensorHistory? _history;
  bool _isLoading = true;
  String? _error;
  int _selectedPeriod = 24; // heures

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await AnimalHealthService.getSensorHistory(
        widget.animalId,
        periodHours: _selectedPeriod,
      );
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capteurs — ${widget.animalName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _history == null
                  ? const Center(child: Text('Aucune donnée'))
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPeriodSelector(),
          _buildSummaryCards(),
          _buildTemperatureChart(),
          _buildHeartRateChart(),
          _buildActivityChart(),
          _buildAlertsList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Période : ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('6h'),
            selected: _selectedPeriod == 6,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPeriod = 6);
                _loadData();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('24h'),
            selected: _selectedPeriod == 24,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPeriod = 24);
                _loadData();
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('7j'),
            selected: _selectedPeriod == 168,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedPeriod = 168);
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _history!.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Température',
              summary.avgTemperature != null
                  ? '${summary.avgTemperature!.toStringAsFixed(1)}°C'
                  : 'N/A',
              Icons.thermostat,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Fréquence',
              summary.avgHeartRate != null
                  ? '${summary.avgHeartRate!.toStringAsFixed(0)} bpm'
                  : 'N/A',
              Icons.favorite,
              Colors.pink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Activité',
              summary.avgActivity != null
                  ? '${summary.avgActivity!.toStringAsFixed(0)}/100'
                  : 'N/A',
              Icons.directions_run,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return _buildChartCard(
      title: '🌡️ Température (°C)',
      color: Colors.red,
      data: _history!.data
          .where((d) => d.temperature?.avg != null)
          .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(),
                d.temperature!.avg!,
              ))
          .toList(),
      minY: 37.0,
      maxY: 41.0,
      normalRange: [38.0, 39.5],
    );
  }

  Widget _buildHeartRateChart() {
    return _buildChartCard(
      title: '❤️ Fréquence Cardiaque (bpm)',
      color: Colors.pink,
      data: _history!.data
          .where((d) => d.heartRate?.avg != null)
          .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(),
                d.heartRate!.avg!,
              ))
          .toList(),
      minY: 40.0,
      maxY: 100.0,
      normalRange: [50.0, 80.0],
    );
  }

  Widget _buildActivityChart() {
    return _buildChartCard(
      title: '🏃 Score d\'Activité',
      color: Colors.green,
      data: _history!.data
          .where((d) => d.activity?.avg != null)
          .map((d) => FlSpot(
                d.timestamp.millisecondsSinceEpoch.toDouble(),
                d.activity!.avg!,
              ))
          .toList(),
      minY: 0.0,
      maxY: 100.0,
      normalRange: [30.0, 70.0],
    );
  }

  Widget _buildChartCard({
    required String title,
    required Color color,
    required List<FlSpot> data,
    required double minY,
    required double maxY,
    List<double>? normalRange,
  }) {
    if (data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Aucune donnée disponible'),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 5,
                  ),
                  borderData: FlBorderData(show: false),
                  // Zones d'alerte
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: normalRange != null
                        ? [
                            HorizontalRangeAnnotation(
                              y1: normalRange[0],
                              y2: normalRange[1],
                              color: Colors.green.withOpacity(0.1),
                            ),
                          ]
                        : [],
                    verticalRangeAnnotations: _history!.alertZones
                        .map((zone) => VerticalRangeAnnotation(
                              x1: zone.startTime.millisecondsSinceEpoch.toDouble(),
                              x2: zone.endTime.millisecondsSinceEpoch.toDouble(),
                              color: _getAlertColor(zone.level).withOpacity(0.2),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            if (normalRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Zone normale : ${normalRange[0].toStringAsFixed(1)} - ${normalRange[1].toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    if (_history!.alertZones.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚨 Alertes Détectées',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._history!.alertZones.map((zone) => _buildAlertItem(zone)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(AlertZone zone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAlertColor(zone.level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getAlertColor(zone.level)),
      ),
      child: Row(
        children: [
          Icon(_getAlertIcon(zone.level), color: _getAlertColor(zone.level)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.disease ?? 'Anomalie détectée',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd/MM HH:mm').format(zone.startTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (zone.confidence != null)
                  Text(
                    'Confiance : ${(zone.confidence! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(
              zone.level.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: _getAlertColor(zone.level),
            labelStyle: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Color _getAlertColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Icons.warning;
      case 'high':
        return Icons.error_outline;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }
}
