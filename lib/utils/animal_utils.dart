import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AnimalUtils {
  /// Get emoji for animal type
  static String getAnimalEmoji(String? type) {
    if (type == null) return '🐾';
    final lowerType = type.toLowerCase();
    
    if (lowerType.contains('cow')) return '🐄';
    if (lowerType.contains('sheep')) return '🐑';
    if (lowerType.contains('goat')) return '🐐';
    if (lowerType.contains('pig')) return '🐷';
    if (lowerType.contains('chicken')) return '🐔';
    if (lowerType.contains('horse')) return '🐎';
    if (lowerType.contains('dog')) return '🐕';
    
    return '🐾';
  }

  /// Get Material Symbol icon for animal type
  static IconData getAnimalIcon(String? type) {
    if (type == null) return Symbols.pets;
    final lowerType = type.toLowerCase();
    
    if (lowerType.contains('cow')) return Symbols.cruelty_free;
    if (lowerType.contains('sheep')) return Symbols.pest_control_rodent;
    if (lowerType.contains('horse')) return Symbols.emoji_nature;
    if (lowerType.contains('dog')) return Symbols.sound_detection_dog_barking;
    
    return Symbols.pets;
  }

  /// Get animal type display name
  static String getAnimalTypeName(String? type) {
    if (type == null) return 'Unknown';
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }
}
