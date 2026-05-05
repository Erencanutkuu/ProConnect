import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class ApiService {
  static String? _token;

  // Token'ı SharedPreferences'dan yükle
  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  // Token kaydet
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Token sil (çıkış)
  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  static String? get token => _token;

  // Ortak header'lar
  static Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  // ============ AUTH ============
  static Future<Map<String, dynamic>> login(String eposta, String sifre) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'eposta': eposta, 'sifre': sifre}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['token'] != null) {
        await saveToken(data['token']);
      }
      return data;
    }
    throw Exception(res.body);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/kaydol'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(res.body);
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/me'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Kullanıcı bilgisi alınamadı');
  }

  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$apiBaseUrl/cikis'), headers: _headers());
    } catch (_) {}
    await clearToken();
  }

  // ============ İLANLAR ============
  static Future<List<dynamic>> getIlanlar() async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/ilan/aktif'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('İlanlar yüklenemedi');
  }

  static Future<List<dynamic>> aramaYap(String query) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/ara'),
      headers: _headers(),
      body: jsonEncode({'aranan': query}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  // ============ REZERVASYON ============
  static Future<Map<String, dynamic>> rezervasyonOlustur(int ilanId) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/rezervasyon/olustur'),
      headers: _headers(),
      body: jsonEncode({'ilanId': ilanId}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception(res.body);
  }

  static Future<List<dynamic>> getRezervasyon() async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/rezervasyon/benimkiler'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<void> rezervasyonIptal(int rezvId) async {
    await http.post(
      Uri.parse('$apiBaseUrl/rezervasyon/iptal'),
      headers: _headers(),
      body: jsonEncode({'rezervasyonId': rezvId}),
    );
  }

  // ============ YORUMLAR ============
  static Future<Map<String, dynamic>> getPuanOzeti(int ilanId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/yorum/puan/$ilanId'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return {'ortalama': 0, 'yorumSayisi': 0};
  }

  static Future<List<dynamic>> getYorumlar(int ilanId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/yorum/ilan/$ilanId'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<void> yorumYaz(int ilanId, int puan, String metin) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/yorum/yaz'),
      headers: _headers(),
      body: jsonEncode({'ilanId': ilanId, 'puan': puan, 'yorumMetni': metin}),
    );
    if (res.statusCode != 200) throw Exception(res.body);
  }

  // ============ MESAJLAR ============
  static Future<List<dynamic>> getKonusmalar() async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/mesaj/konusmalar'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<List<dynamic>> getMesajlar(int partnerId) async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/mesaj/oku/$partnerId'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  static Future<void> mesajGonder(int aliciId, String metin) async {
    await http.post(
      Uri.parse('$apiBaseUrl/mesaj/gonder'),
      headers: _headers(),
      body: jsonEncode({'aliciId': aliciId, 'mesajMetni': metin}),
    );
  }

  static Future<int> okunmamisSayisi() async {
    final res = await http.get(
      Uri.parse('$apiBaseUrl/mesaj/okunmamis-sayisi'),
      headers: _headers(json: false),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['sayi'] ?? 0;
    }
    return 0;
  }
}
