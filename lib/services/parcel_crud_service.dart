import '../models/parcel.dart';
import 'api_service.dart';

class ParcelCrudService {
  static const String _endpoint = '/parcels';

  Future<List<Parcel>> getParcels() async {
    final response = await ApiService.get(_endpoint, withAuth: true);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => Parcel.fromJson(json)).toList();
  }

  Future<Parcel> createParcel(Map<String, dynamic> parcelData) async {
    final response = await ApiService.post(_endpoint, parcelData, withAuth: true);
    return Parcel.fromJson(response);
  }

  Future<Parcel> getParcelById(String id) async {
    final response = await ApiService.get('$_endpoint/$id', withAuth: true);
    return Parcel.fromJson(response['data']);
  }

  Future<Parcel> updateParcel(String id, Map<String, dynamic> parcelData) async {
    final response = await ApiService.patch('$_endpoint/$id', parcelData, withAuth: true);
    return Parcel.fromJson(response);
  }

  Future<void> deleteParcel(String id) async {
    await ApiService.delete('$_endpoint/$id', withAuth: true);
  }

  Future<Crop> addCrop(String parcelId, Map<String, dynamic> cropData) async {
    final response = await ApiService.post('$_endpoint/$parcelId/crops', cropData, withAuth: true);
    return Crop.fromJson(response);
  }

  Future<Fertilization> addFertilization(String parcelId, Map<String, dynamic> fertData) async {
    final response = await ApiService.post('$_endpoint/$parcelId/fertilizations', fertData, withAuth: true);
    return Fertilization.fromJson(response);
  }

  Future<PestDisease> addPest(String parcelId, Map<String, dynamic> pestData) async {
    final response = await ApiService.post('$_endpoint/$parcelId/pests', pestData, withAuth: true);
    return PestDisease.fromJson(response);
  }

  Future<Harvest> addHarvest(String parcelId, Map<String, dynamic> harvestData) async {
    final response = await ApiService.post('$_endpoint/$parcelId/harvests', harvestData, withAuth: true);
    return Harvest.fromJson(response);
  }

  Future<String> getAiAdvice(String parcelId) async {
    final response = await ApiService.get('$_endpoint/$parcelId/ai-advice', withAuth: true);
    return response['advice'] as String? ?? 'No advice available.';
  }
}
