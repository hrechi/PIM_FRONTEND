class RevenueDetail {
  final String id;
  final String animalName;
  final String type;
  final double salePrice;
  final DateTime saleDate;
  final String? buyerName;
  final double? saleWeightKg;

  RevenueDetail({
    required this.id,
    required this.animalName,
    required this.type,
    required this.salePrice,
    required this.saleDate,
    this.buyerName,
    this.saleWeightKg,
  });

  factory RevenueDetail.fromJson(Map<String, dynamic> json) {
    return RevenueDetail(
      id: json['id'],
      animalName: json['animalName'] ?? 'N/A',
      type: json['type'] ?? 'Unknown',
      salePrice: (json['salePrice'] as num).toDouble(),
      saleDate: DateTime.parse(json['saleDate']),
      buyerName: json['buyerName'],
      saleWeightKg: json['saleWeightKg'] != null
          ? (json['saleWeightKg'] as num).toDouble()
          : null,
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
      data: (json['data'] as List).map((item) => RevenueDetail.fromJson(item)).toList(),
      total: json['total'],
      skip: json['skip'],
      take: json['take'],
    );
  }
}
