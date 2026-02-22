import '../models/animal.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AnimalService {
  // Simple helper to get farmerId from SharedPreferences 
  // (In a real app, we'd use AuthProvider, but for service isolation we check local storage)
  Future<String?> _getFarmerId() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming user data is stored as a JSON string in 'userData' or similar
    // For now, let's assume we can get it from the stored user model 
    // or just let the caller pass it if needed. 
    // But since the screen doesn't pass it, we try to find it.
    final userData = prefs.getString('user'); 
    if (userData != null) {
      final user = jsonDecode(userData);
      return user['id'];
    }
    return null;
  }

  Future<List<Animal>> getAnimals({String? animalType}) async {
    String endpoint = '/animals';
    if (animalType != null) {
      endpoint += '?animalType=$animalType';
    }
    
    final response = await ApiService.get(endpoint, withAuth: true);
    final List<dynamic> data = response is List ? response : (response['data'] ?? []);
    
    var animals = data.map((json) => Animal.fromJson(json)).toList();
    
    // For safety, apply a local case-insensitive filter as fallback
    if (animalType != null) {
      animals = animals.where((a) => a.animalType.toUpperCase() == animalType.toUpperCase()).toList();
    }
    
    return animals;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    return await ApiService.get('/animals/stats', withAuth: true);
  }

  Future<Animal> createAnimal(Map<String, dynamic> animalData) async {
    // We no longer inject farmerId here because the backend 
    // extracts it from the JWT for security and to avoid FK conflicts.
    
    if (animalData['nodeId'] == null) {
      animalData['nodeId'] = 'SCAN-${DateTime.now().millisecondsSinceEpoch}';
    }

    final response = await ApiService.post('/animals', animalData, withAuth: true);
    return Animal.fromJson(response);
  }

  Future<Animal> updateAnimal(String nodeId, Map<String, dynamic> animalData) async {
    final response = await ApiService.patch('/animals/$nodeId', animalData, withAuth: true);
    return Animal.fromJson(response);
  }

  Future<void> deleteAnimal(String nodeId) async {
    await ApiService.delete('/animals/$nodeId', withAuth: true);
  }
}
