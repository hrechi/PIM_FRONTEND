import 'package:intl/intl.dart';

class CropCalendarItem {
  final String id;
  final String cropName;
  final String variety;
  final DateTime plantingDate;
  final DateTime expectedHarvestDate;
  final String status;
  final String? parcelName;

  CropCalendarItem({
    required this.id,
    required this.cropName,
    required this.variety,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.status,
    this.parcelName,
  });

  factory CropCalendarItem.fromJson(Map<String, dynamic> json) {
    return CropCalendarItem(
      id: json['id'],
      cropName: json['cropName'],
      variety: json['variety'],
      plantingDate: DateTime.parse(json['plantingDate']),
      expectedHarvestDate: DateTime.parse(json['expectedHarvestDate']),
      status: json['status'],
      parcelName: json['parcelName'],
    );
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(plantingDate)) return 0.0;
    if (now.isAfter(expectedHarvestDate)) return 1.0;
    
    final totalDuration = expectedHarvestDate.difference(plantingDate).inSeconds;
    final elapsedDuration = now.difference(plantingDate).inSeconds;
    
    if (totalDuration == 0) return 1.0;
    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }

  String get formattedPlantingDate => DateFormat('MMM dd, yyyy').format(plantingDate);
  String get formattedHarvestDate => DateFormat('MMM dd, yyyy').format(expectedHarvestDate);
  
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expectedHarvestDate)) return 0;
    return expectedHarvestDate.difference(now).inDays;
  }
}
