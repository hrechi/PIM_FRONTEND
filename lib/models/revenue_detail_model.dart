/// ============================================================
/// REVENUE DETAIL MODEL — Modèle de données pour les revenus
/// ============================================================
///
/// Ce modèle représente une entrée de revenu dans le tableau de bord
/// financier. Il supporte deux sources de revenus :
///
///   1. animalSale  → Vente d'un animal (automatique, depuis le modèle Animal)
///      Champs renseignés : animalName, type (race), salePrice, saleDate,
///                          buyerName, saleWeightKg
///
///   2. manual      → Revenu saisi manuellement par l'agriculteur
///      Champs renseignés : type (catégorie), salePrice (montant),
///                          saleDate (date), description
///
/// Le champ [source] permet à l'UI de distinguer les deux types
/// et d'afficher des icônes/couleurs différentes.
///
/// Utilisé dans : RevenuesDetailsScreen, FinanceDashboardScreen
/// ============================================================

/// Source d'un revenu : vente automatique d'animal ou saisie manuelle
enum RevenueSource { animalSale, manual }

class RevenueDetail {
  final String id;
  final String? animalName;   // null for manual revenues
  final String type;          // animalType for sales, category for manual
  final double salePrice;
  final DateTime saleDate;
  final String? buyerName;
  final double? saleWeightKg;
  final String? description;  // only for manual revenues
  final RevenueSource source;

  RevenueDetail({
    required this.id,
    this.animalName,
    required this.type,
    required this.salePrice,
    required this.saleDate,
    this.buyerName,
    this.saleWeightKg,
    this.description,
    required this.source,
  });

  factory RevenueDetail.fromJson(Map<String, dynamic> json) {
    final src = json['source'] == 'manual'
        ? RevenueSource.manual
        : RevenueSource.animalSale;
    return RevenueDetail(
      id: json['id'],
      animalName: json['animalName'] as String?,
      type: json['type'] ?? 'other',
      salePrice: (json['salePrice'] as num).toDouble(),
      saleDate: DateTime.parse(json['saleDate']),
      buyerName: json['buyerName'] as String?,
      saleWeightKg: json['saleWeightKg'] != null
          ? (json['saleWeightKg'] as num).toDouble()
          : null,
      description: json['description'] as String?,
      source: src,
    );
  }
}

class RevenuesResponse {
  final List<RevenueDetail> data;
  final int total;
  final int skip;
  final int take;

  RevenuesResponse({
    required this.data,
    required this.total,
    required this.skip,
    required this.take,
  });

  factory RevenuesResponse.fromJson(Map<String, dynamic> json) {
    return RevenuesResponse(
      data: (json['data'] as List)
          .map((item) => RevenueDetail.fromJson(item))
          .toList(),
      total: json['total'],
      skip: json['skip'],
      take: json['take'],
    );
  }
}
