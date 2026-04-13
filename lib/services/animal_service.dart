import '../models/animal.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  Future<List<Animal>> getAnimals({String? animalType, String? fieldId}) async {
    String endpoint = '/animals';
    List<String> params = [];
    if (animalType != null) {
      params.add('animalType=$animalType');
    }
    if (fieldId != null) {
      params.add('fieldId=$fieldId');
    }
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }
    
    try {
      final response = await ApiService.get(endpoint, withAuth: true);
      debugPrint('📡 Response type: ${response.runtimeType}');
      debugPrint('📡 Response: $response');
      
      final List<dynamic> data = response is List ? response : (response['data'] ?? []);
      debugPrint('📡 Data type: ${data.runtimeType}, length: ${data.length}');
      
      List<Animal> animals = [];
      for (var json in data) {
        try {
          animals.add(Animal.fromJson(json));
        } catch (e) {
          debugPrint('⚠️ Failed to parse animal: $e, json: $json');
        }
      }
      
      debugPrint('✅ Parsed ${animals.length} animals from response');
      
      // If fieldId was requested but no animals found, fallback to all farmer animals
      if (animals.isEmpty && fieldId != null) {
        debugPrint('⚠️ No animals found for fieldId=$fieldId, fetching all farmer animals...');
        try {
          final fallbackResponse = await ApiService.get('/animals', withAuth: true);
          debugPrint('📡 Fallback response type: ${fallbackResponse.runtimeType}');
          
          final List<dynamic> fallbackData = fallbackResponse is List ? fallbackResponse : (fallbackResponse['data'] ?? []);
          debugPrint('📡 Fallback data length: ${fallbackData.length}');
          
          for (var json in fallbackData) {
            try {
              animals.add(Animal.fromJson(json));
            } catch (e) {
              debugPrint('⚠️ Failed to parse fallback animal: $e');
            }
          }
          
          debugPrint('📌 Fallback: found ${animals.length} total farmer animals');
        } catch (e) {
          debugPrint('❌ Fallback fetch failed: $e');
        }
      }
      
      // For safety, apply a local case-insensitive filter as fallback
      if (animalType != null) {
        animals = animals.where((a) => a.animalType.toUpperCase() == animalType.toUpperCase()).toList();
      }
      
      return animals;
    } catch (e) {
      debugPrint('❌ Fatal error in getAnimals: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStatistics({String? fieldId}) async {
    String endpoint = '/animals/stats';
    if (fieldId != null) {
      endpoint += '?fieldId=$fieldId';
    }
    return await ApiService.get(endpoint, withAuth: true);
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

  Future<Animal> getAnimalById(String id) async {
    final response = await ApiService.get('/animals/id/$id', withAuth: true);
    return Animal.fromJson(response);
  }

  Future<Animal> updateAnimal(String nodeId, Map<String, dynamic> animalData) async {
    final response = await ApiService.patch('/animals/$nodeId', animalData, withAuth: true);
    return Animal.fromJson(response);
  }

  Future<void> deleteAnimal(String nodeId) async {
    await ApiService.delete('/animals/$nodeId', withAuth: true);
  }

  Future<Animal> sellAnimal(String nodeId, Map<String, dynamic> sellData) async {
    final response = await ApiService.patch('/animals/$nodeId/sell', sellData, withAuth: true);
    return Animal.fromJson(response);
  }

  Future<Animal> cancelSale(String nodeId) async {
    final response = await ApiService.patch('/animals/$nodeId/cancel-sale', {}, withAuth: true);
    return Animal.fromJson(response);
  }

  Future<List<Animal>> getSoldAnimals({String? fieldId}) async {
    String endpoint = '/animals/sold';
    if (fieldId != null) {
      endpoint += '?fieldId=$fieldId';
    }
    final response = await ApiService.get(endpoint, withAuth: true);
    final List<dynamic> data = response is List ? response : (response['data'] ?? []);
    return data.map((json) => Animal.fromJson(json)).toList();
  }
}
