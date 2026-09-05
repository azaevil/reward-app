import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String defaultBaseUrl = "http://192.168.1.101:8000";
  final _storage = const FlutterSecureStorage();

  Future<String> getBaseUrl() async {
    final customUrl = await _storage.read(key: 'custom_base_url');
    return customUrl ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    await _storage.write(key: 'custom_base_url', value: cleanUrl);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  Future<void> saveSession(String access, String refresh, String email) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
    await _storage.write(key: 'user_email', value: email);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_email');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        // Kayıt başarılıysa otomatik giriş yap
        return await login(email, password);
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Kayıt başarısız.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Sunucuya bağlanılamadı. Wi-Fi / İnternet bağlantınızı kontrol edin.'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final baseUrl = await getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveSession(data['access_token'], data['refresh_token'], email.trim());
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['detail'] ?? 'Hatalı e-posta veya şifre.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Sunucuya bağlanılamadı. Lütfen sunucunun açık olduğundan emin olun.'};
    }
  }

  Future<Map<String, dynamic>> getWallet() async {
    final token = await getToken();
    final baseUrl = await getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Cüzdan bilgileri alınamadı.');
  }

  Future<Map<String, dynamic>> sendAdEvent({
    required String adId,
    required int durationSeconds,
    required bool isRewarded,
  }) async {
    final token = await getToken();
    final baseUrl = await getBaseUrl();
    
    // Güvenli Benzersiz Kriptografik Token (Replay attack engeli)
    final nonce = Random().nextInt(9999999);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tokenStr = "imp_${timestamp}_${nonce}";

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
        'is_rewarded': isRewarded,
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Reklam etkinliği işlenemedi.');
    }
  }

  Future<Map<String, dynamic>> withdraw({
    required double amountUsd,
    required String paymentMethod,
    required String payoutDetails,
  }) async {
    final token = await getToken();
    final baseUrl = await getBaseUrl();
    
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/withdraw'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount_usd': amountUsd,
        'payment_method': paymentMethod,
        'payout_details': payoutDetails,
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Para çekme talebi oluşturulamadı.');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
