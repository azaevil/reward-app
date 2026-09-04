import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Android Emulator için 10.0.2.2, iOS / Gerçek Cihaz için sunucu IP adresi
  static const String baseUrl = "http://10.0.2.2:8000"; 
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['access_token'], data['refresh_token']);
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> getWallet() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Cüzdan bilgileri alınamadı.');
  }

  Future<List<dynamic>> getFeed() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ads/feed'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Reklam akışı yüklenemedi.');
  }

  Future<bool> sendAdEvent(String adId, String tokenStr, int durationSeconds) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ads/event'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ad_id': adId,
        'impression_token': tokenStr,
        'duration_seconds': durationSeconds,
        'is_rewarded': true,
      }),
    );

    return response.statusCode == 200;
  }
}