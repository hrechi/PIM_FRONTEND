/// Service for generating plant recommendations based on soil conditions
class PlantRecommendationService {
  /// Get plant recommendations based on soil conditions
  static PlantRecommendations getRecommendations({
    required double ph,
    required double soilMoisture,
    required double temperature,
    required double sunlight,
  }) {
    // Check if soil conditions are too extreme for any plants
    final isExtreme = _isSoilTooExtreme(ph, soilMoisture, temperature);
    
    if (isExtreme) {
      return PlantRecommendations(
        vegetables: [],
        fruits: [],
        trees: [],
        herbs: [],
        soilType: '',
        isExtreme: true,
        extremeMessage: _getExtremeConditionMessage(ph, soilMoisture, temperature),
      );
    }
    
    final vegetables = _getVegetableRecommendations(ph, soilMoisture, temperature);
    final fruits = _getFruitRecommendations(ph, soilMoisture, temperature);
    final trees = _getTreeRecommendations(ph, soilMoisture, temperature);
    final herbs = _getHerbRecommendations(ph, soilMoisture, temperature);
    
    return PlantRecommendations(
      vegetables: vegetables,
      fruits: fruits,
      trees: trees,
      herbs: herbs,
      soilType: _determineSoilType(ph, soilMoisture),
      isExtreme: false,
      extremeMessage: null,
    );
  }
  
  /// Check if soil conditions are too extreme for any plants
  static bool _isSoilTooExtreme(double ph, double soilMoisture, double temperature) {
    // Extreme pH (below 4.0 or above 9.5 - almost nothing grows)
    if (ph < 4.0 || ph > 9.5) return true;
    
    // Extreme moisture (below 5% or above 95% - root damage)
    if (soilMoisture < 5 || soilMoisture > 95) return true;
    
    // Extreme temperature (below 5°C or above 45°C - plant damage)
    if (temperature < 5 || temperature > 45) return true;
    
    return false;
  }
  
  /// Get message explaining extreme conditions
  static String _getExtremeConditionMessage(double ph, double soilMoisture, double temperature) {
    final issues = <String>[];
    
    if (ph < 4.0) {
      issues.add('pH is critically acidic (${ph.toStringAsFixed(1)}). Most plants cannot survive below pH 4.0.');
    } else if (ph > 9.5) {
      issues.add('pH is critically alkaline (${ph.toStringAsFixed(1)}). Most plants cannot survive above pH 9.5.');
    }
    
    if (soilMoisture < 5) {
      issues.add('Soil is extremely dry (${soilMoisture.toStringAsFixed(0)}%). Plants cannot extract water.');
    } else if (soilMoisture > 95) {
      issues.add('Soil is waterlogged (${soilMoisture.toStringAsFixed(0)}%). Roots will rot due to lack of oxygen.');
    }
    
    if (temperature < 5) {
      issues.add('Temperature is too cold (${temperature.toStringAsFixed(1)}°C). Freezing temperatures damage plant cells.');
    } else if (temperature > 45) {
      issues.add('Temperature is too hot (${temperature.toStringAsFixed(1)}°C). Extreme heat kills plant tissues.');
    }
    
    return issues.join('\n\n');
  }
  
  /// Determine soil type description
  static String _determineSoilType(double ph, double soilMoisture) {
    String acidity;
    if (ph < 6.0) {
      acidity = 'acidic';
    } else if (ph > 7.5) {
      acidity = 'alkaline';
    } else {
      acidity = 'neutral';
    }
    
    String moisture;
    if (soilMoisture < 30) {
      moisture = 'dry';
    } else if (soilMoisture > 70) {
      moisture = 'moist';
    } else {
      moisture = 'moderately moist';
    }
    
    return 'Your soil is $acidity and $moisture, which is suitable for the following plants:';
  }
  
  /// Get vegetable recommendations
  static List<PlantRecommendation> _getVegetableRecommendations(
    double ph,
    double soilMoisture,
    double temperature,
  ) {
    final recommendations = <PlantRecommendation>[];
    
    // Tomatoes (pH 6.0-6.8, moderate moisture, warm)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 40 && soilMoisture <= 70 && temperature >= 20) {
      recommendations.add(PlantRecommendation(
        name: 'Tomatoes',
        icon: '🍅',
        suitability: _calculateSuitability(ph, 6.4, soilMoisture, 55, temperature, 25),
        reasons: [
          'Ideal pH range for tomatoes (6.0-6.8)',
          'Good moisture levels for fruit development',
          'Temperature suitable for tomato growth',
        ],
        tips: 'Add organic compost and stake plants for best results.',
      ));
    }
    
    // Lettuce (pH 6.0-7.0, high moisture, cool-moderate)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture >= 50 && temperature >= 10 && temperature <= 25) {
      recommendations.add(PlantRecommendation(
        name: 'Lettuce',
        icon: '🥬',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 65, temperature, 18),
        reasons: [
          'Lettuce thrives in neutral to slightly acidic soil',
          'High moisture content perfect for leafy greens',
          'Temperature ideal for crisp lettuce',
        ],
        tips: 'Plant in partial shade if temperatures exceed 20°C.',
      ));
    }
    
    // Carrots (pH 6.0-7.0, moderate moisture)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 35 && soilMoisture <= 65) {
      recommendations.add(PlantRecommendation(
        name: 'Carrots',
        icon: '🥕',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 50, temperature, 18),
        reasons: [
          'pH perfect for root development',
          'Moderate moisture prevents root splitting',
          'Well-draining soil ideal for carrots',
        ],
        tips: 'Ensure deep, loose soil for straight root growth.',
      ));
    }
    
    // Peppers (pH 6.0-7.0, moderate-warm)
    if (ph >= 6.0 && ph <= 7.0 && temperature >= 20 && soilMoisture >= 40) {
      recommendations.add(PlantRecommendation(
        name: 'Peppers',
        icon: '🌶️',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 55, temperature, 25),
        reasons: [
          'Soil pH excellent for pepper plants',
          'Warm temperature promotes fruiting',
          'Good moisture supports healthy growth',
        ],
        tips: 'Mulch around plants to maintain consistent soil moisture.',
      ));
    }
    
    // Potatoes (pH 5.0-6.5, moderate moisture)
    if (ph >= 5.0 && ph <= 7.0 && soilMoisture >= 40 && soilMoisture <= 70) {
      recommendations.add(PlantRecommendation(
        name: 'Potatoes',
        icon: '🥔',
        suitability: _calculateSuitability(ph, 5.8, soilMoisture, 55, temperature, 18),
        reasons: [
          'Slightly acidic soil reduces scab disease',
          'Moisture level good for tuber development',
          'Cool to moderate temperatures ideal',
        ],
        tips: 'Hill soil around plants as they grow to increase yield.',
      ));
    }
    
    // Spinach (pH 6.5-7.5, high moisture, cool)
    if (ph >= 6.5 && ph <= 7.8 && soilMoisture >= 55 && temperature <= 25) {
      recommendations.add(PlantRecommendation(
        name: 'Spinach',
        icon: '🥬',
        suitability: _calculateSuitability(ph, 7.0, soilMoisture, 65, temperature, 15),
        reasons: [
          'Slightly alkaline soil perfect for spinach',
          'High moisture supports leaf growth',
          'Cool temperatures prevent bolting',
        ],
        tips: 'Harvest leaves regularly to encourage new growth.',
      ));
    }
    
    // Beans (pH 6.0-7.5, moderate moisture)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture >= 40 && soilMoisture <= 65) {
      recommendations.add(PlantRecommendation(
        name: 'Beans',
        icon: '🫘',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 52, temperature, 22),
        reasons: [
          'Wide pH tolerance makes beans versatile',
          'Moderate moisture prevents root rot',
          'Beans fix nitrogen, improving soil',
        ],
        tips: 'Provide support for climbing varieties.',
      ));
    }
    
    // Cucumbers (pH 6.0-7.0, high moisture, warm)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 55 && temperature >= 20) {
      recommendations.add(PlantRecommendation(
        name: 'Cucumbers',
        icon: '🥒',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 65, temperature, 25),
        reasons: [
          'pH range perfect for cucumbers',
          'High moisture needed for fruit quality',
          'Warm temperatures promote fast growth',
        ],
        tips: 'Trellis plants vertically to save space and improve air circulation.',
      ));
    }
    
    return recommendations..sort((a, b) => b.suitability.compareTo(a.suitability));
  }
  
  /// Get fruit recommendations
  static List<PlantRecommendation> _getFruitRecommendations(
    double ph,
    double soilMoisture,
    double temperature,
  ) {
    final recommendations = <PlantRecommendation>[];
    
    // Strawberries (pH 5.5-6.5, moderate moisture)
    if (ph >= 5.5 && ph <= 6.8 && soilMoisture >= 45 && soilMoisture <= 70) {
      recommendations.add(PlantRecommendation(
        name: 'Strawberries',
        icon: '🍓',
        suitability: _calculateSuitability(ph, 6.0, soilMoisture, 57, temperature, 20),
        reasons: [
          'Slightly acidic soil perfect for strawberries',
          'Moisture level ideal for fruit sweetness',
          'Perennial plants for multiple harvests',
        ],
        tips: 'Mulch with straw to keep fruit clean and reduce weeds.',
      ));
    }
    
    // Blueberries (pH 4.5-5.5, acidic, moist)
    if (ph >= 4.0 && ph <= 6.0 && soilMoisture >= 50) {
      recommendations.add(PlantRecommendation(
        name: 'Blueberries',
        icon: '🫐',
        suitability: _calculateSuitability(ph, 5.0, soilMoisture, 60, temperature, 20),
        reasons: [
          'Highly acidic soil required for blueberries',
          'Consistent moisture crucial for berry production',
          'Long-lived plants with high yields',
        ],
        tips: 'Add sulfur to maintain acidic pH. Plant multiple varieties for better pollination.',
      ));
    }
    
    // Watermelon (pH 6.0-7.0, moderate moisture, hot)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 40 && soilMoisture <= 65 && temperature >= 22) {
      recommendations.add(PlantRecommendation(
        name: 'Watermelon',
        icon: '🍉',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 52, temperature, 28),
        reasons: [
          'Neutral pH perfect for melons',
          'Well-drained soil prevents rot',
          'Hot temperatures produce sweet fruit',
        ],
        tips: 'Space plants well apart - they need lots of room to spread.',
      ));
    }
    
    // Raspberries (pH 5.5-6.5, moderate moisture)
    if (ph >= 5.5 && ph <= 6.8 && soilMoisture >= 45 && soilMoisture <= 70) {
      recommendations.add(PlantRecommendation(
        name: 'Raspberries',
        icon: '🫐',
        suitability: _calculateSuitability(ph, 6.0, soilMoisture, 57, temperature, 18),
        reasons: [
          'Slightly acidic soil ideal for raspberries',
          'Good drainage prevents root diseases',
          'Productive perennial fruit',
        ],
        tips: 'Prune old canes after fruiting to encourage new growth.',
      ));
    }
    
    // Grapes (pH 6.0-7.0, moderate-dry)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture >= 30 && soilMoisture <= 60) {
      recommendations.add(PlantRecommendation(
        name: 'Grapes',
        icon: '🍇',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 45, temperature, 25),
        reasons: [
          'Well-drained soil prevents root rot',
          'Moderate pH supports healthy vines',
          'Long-term investment with high rewards',
        ],
        tips: 'Establish strong support system. Training and pruning are essential.',
      ));
    }
    
    return recommendations..sort((a, b) => b.suitability.compareTo(a.suitability));
  }
  
  /// Get tree recommendations
  static List<PlantRecommendation> _getTreeRecommendations(
    double ph,
    double soilMoisture,
    double temperature,
  ) {
    final recommendations = <PlantRecommendation>[];
    
    // Apple trees (pH 6.0-7.0, moderate moisture)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 40 && soilMoisture <= 70) {
      recommendations.add(PlantRecommendation(
        name: 'Apple Trees',
        icon: '🍎',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 55, temperature, 18),
        reasons: [
          'Neutral soil perfect for apple trees',
          'Good drainage essential for root health',
          'Produces fruit for decades',
        ],
        tips: 'Plant two varieties for cross-pollination. Prune annually in late winter.',
      ));
    }
    
    // Citrus trees (pH 6.0-7.5, moderate moisture, warm)
    if (ph >= 6.0 && ph <= 7.5 && temperature >= 18 && soilMoisture >= 40) {
      recommendations.add(PlantRecommendation(
        name: 'Citrus Trees (Lemon, Orange)',
        icon: '🍋',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 52, temperature, 25),
        reasons: [
          'pH range ideal for citrus',
          'Warm climate suitable for fruiting',
          'High-value fruit production',
        ],
        tips: 'Protect from frost. Feed regularly with citrus-specific fertilizer.',
      ));
    }
    
    // Olive trees (pH 6.5-8.0, dry-moderate, warm)
    if (ph >= 6.5 && ph <= 8.5 && soilMoisture <= 55 && temperature >= 15) {
      recommendations.add(PlantRecommendation(
        name: 'Olive Trees',
        icon: '🫒',
        suitability: _calculateSuitability(ph, 7.5, soilMoisture, 40, temperature, 25),
        reasons: [
          'Alkaline-tolerant and drought-resistant',
          'Low moisture requirements',
          'Long-lived and low maintenance',
        ],
        tips: 'Excellent drainage essential. Very drought-tolerant once established.',
      ));
    }
    
    // Avocado trees (pH 6.0-7.0, well-drained, warm)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 35 && soilMoisture <= 60 && temperature >= 20) {
      recommendations.add(PlantRecommendation(
        name: 'Avocado Trees',
        icon: '🥑',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 47, temperature, 25),
        reasons: [
          'Well-drained soil critical for avocados',
          'Warm climate supports growth',
          'High-value crop',
        ],
        tips: 'Sensitive to overwatering. Mulch heavily but keep away from trunk.',
      ));
    }
    
    // Walnut trees (pH 6.0-7.5, deep soil)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture >= 40 && soilMoisture <= 65) {
      recommendations.add(PlantRecommendation(
        name: 'Walnut Trees',
        icon: '🌰',
        suitability: _calculateSuitability(ph, 6.8, soilMoisture, 52, temperature, 20),
        reasons: [
          'Deep, well-drained soil suits walnuts',
          'pH range supports nut development',
          'Valuable timber and nut production',
        ],
        tips: 'Needs deep soil (2m+). Produces chemicals that inhibit some plants nearby.',
      ));
    }
    
    return recommendations..sort((a, b) => b.suitability.compareTo(a.suitability));
  }
  
  /// Get herb recommendations
  static List<PlantRecommendation> _getHerbRecommendations(
    double ph,
    double soilMoisture,
    double temperature,
  ) {
    final recommendations = <PlantRecommendation>[];
    
    // Basil (pH 6.0-7.5, moderate moisture, warm)
    if (ph >= 6.0 && ph <= 7.5 && temperature >= 18 && soilMoisture >= 45) {
      recommendations.add(PlantRecommendation(
        name: 'Basil',
        icon: '🌿',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 55, temperature, 25),
        reasons: [
          'Warm-season herb thrives in these conditions',
          'Good moisture supports leaf production',
          'Fast-growing and productive',
        ],
        tips: 'Pinch flowers to promote bushy growth and more leaves.',
      ));
    }
    
    // Rosemary (pH 6.0-7.5, dry-moderate, warm)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture <= 55) {
      recommendations.add(PlantRecommendation(
        name: 'Rosemary',
        icon: '🌿',
        suitability: _calculateSuitability(ph, 7.0, soilMoisture, 40, temperature, 20),
        reasons: [
          'Drought-tolerant Mediterranean herb',
          'Well-drained soil prevents root rot',
          'Perennial - returns year after year',
        ],
        tips: 'Minimal watering once established. Prune regularly for bushy growth.',
      ));
    }
    
    // Mint (pH 6.0-7.5, high moisture)
    if (ph >= 6.0 && ph <= 7.5 && soilMoisture >= 55) {
      recommendations.add(PlantRecommendation(
        name: 'Mint',
        icon: '🌿',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 65, temperature, 20),
        reasons: [
          'Loves moist soil',
          'Very hardy and fast-growing',
          'Multiple varieties available',
        ],
        tips: 'Grow in containers - spreads aggressively! Harvest regularly.',
      ));
    }
    
    // Thyme (pH 6.0-8.0, dry-moderate)
    if (ph >= 6.0 && ph <= 8.0 && soilMoisture <= 55) {
      recommendations.add(PlantRecommendation(
        name: 'Thyme',
        icon: '🌿',
        suitability: _calculateSuitability(ph, 7.0, soilMoisture, 42, temperature, 18),
        reasons: [
          'Drought-tolerant herb',
          'Alkaline-tolerant',
          'Low maintenance perennial',
        ],
        tips: 'Excellent drainage required. Perfect for rock gardens.',
      ));
    }
    
    // Parsley (pH 6.0-7.0, moderate moisture)
    if (ph >= 6.0 && ph <= 7.0 && soilMoisture >= 45 && soilMoisture <= 70) {
      recommendations.add(PlantRecommendation(
        name: 'Parsley',
        icon: '🌿',
        suitability: _calculateSuitability(ph, 6.5, soilMoisture, 57, temperature, 18),
        reasons: [
          'Neutral soil perfect for parsley',
          'Moderate moisture supports growth',
          'Biennial providing two seasons',
        ],
        tips: 'Soak seeds before planting to speed germination.',
      ));
    }
    
    return recommendations..sort((a, b) => b.suitability.compareTo(a.suitability));
  }
  
  /// Calculate suitability score (0-100)
  static double _calculateSuitability(
    double actualPh,
    double idealPh,
    double actualMoisture,
    double idealMoisture,
    double actualTemp,
    double idealTemp,
  ) {
    // Calculate deviation from ideal for each parameter
    final phDeviation = ((actualPh - idealPh).abs() / 2.0).clamp(0.0, 1.0);
    final moistureDeviation = ((actualMoisture - idealMoisture).abs() / 50.0).clamp(0.0, 1.0);
    final tempDeviation = ((actualTemp - idealTemp).abs() / 15.0).clamp(0.0, 1.0);
    
    // Weight: pH (40%), moisture (35%), temperature (25%)
    final score = 100 - (phDeviation * 40 + moistureDeviation * 35 + tempDeviation * 25);
    return score.clamp(0.0, 100.0);
  }
}

/// Plant recommendations result
class PlantRecommendations {
  final List<PlantRecommendation> vegetables;
  final List<PlantRecommendation> fruits;
  final List<PlantRecommendation> trees;
  final List<PlantRecommendation> herbs;
  final String soilType;
  final bool isExtreme;
  final String? extremeMessage;
  
  const PlantRecommendations({
    required this.vegetables,
    required this.fruits,
    required this.trees,
    required this.herbs,
    required this.soilType,
    this.isExtreme = false,
    this.extremeMessage,
  });
  
  /// Get all recommendations sorted by suitability
  List<PlantRecommendation> get allRecommendations {
    return [...vegetables, ...fruits, ...trees, ...herbs]
      ..sort((a, b) => b.suitability.compareTo(a.suitability));
  }
  
  /// Get top recommendations (top 6)
  List<PlantRecommendation> get topRecommendations {
    return allRecommendations.take(6).toList();
  }
}

/// Individual plant recommendation
class PlantRecommendation {
  final String name;
  final String icon;
  final double suitability; // 0-100
  final List<String> reasons;
  final String tips;
  
  const PlantRecommendation({
    required this.name,
    required this.icon,
    required this.suitability,
    required this.reasons,
    required this.tips,
  });
  
  /// Get suitability level
  String get suitabilityLevel {
    if (suitability >= 85) return 'Excellent';
    if (suitability >= 70) return 'Very Good';
    if (suitability >= 55) return 'Good';
    return 'Fair';
  }
  
  /// Get suitability color
  int get suitabilityColor {
    if (suitability >= 85) return 0xFF4CAF50; // Green
    if (suitability >= 70) return 0xFF8BC34A; // Light green
    if (suitability >= 55) return 0xFFFF9800; // Orange
    return 0xFFFF5722; // Red-orange
  }
}
