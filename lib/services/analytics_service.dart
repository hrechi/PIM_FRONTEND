import '../services/api_service.dart';
import '../models/harvest_analytics_model.dart';

class AnalyticsService {
  // ── Summary ──────────────────────────────────────────────
  static Future<YieldSummary> getYieldSummary() async {
    final response =
        await ApiService.get('/analytics/yield/summary', withAuth: true);
    final data = response['data'] as Map<String, dynamic>;
    return YieldSummary.fromJson(data);
  }

  // ── By Parcel ─────────────────────────────────────────────
  static Future<List<YieldTrend>> getYieldByParcel(String parcelId) async {
    final response = await ApiService.get(
      '/analytics/yield/parcel/$parcelId',
      withAuth: true,
    );
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => YieldTrend.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── By Crop ───────────────────────────────────────────────
  static Future<List<CropComparison>> getYieldByCrop(String cropName) async {
    final response = await ApiService.get(
      '/analytics/yield/crop/$cropName',
      withAuth: true,
    );
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => CropComparison.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
