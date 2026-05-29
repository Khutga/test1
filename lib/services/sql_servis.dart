import 'dart:convert';
import 'package:http/http.dart' as http;

/// Veritabanındaki tabloları temsil eder.
class Tablolar {
  static const String hesaplar = "hesaplar";
  static const String atilanHediyeler = "atilanHediyeler";
}

/// API'den dönen yanıtları standart ve tip güvenli hale getiren model.
class ApiResponse {
  final bool basarili;
  final String mesaj;
  final List<Map<String, dynamic>> veri;
  final String? eklenenId;

  ApiResponse({
    required this.basarili,
    required this.mesaj,
    required this.veri,
    this.eklenenId,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      basarili: json['durum'] == 'basarili',
      mesaj: json['mesaj'] ?? '',
      veri: json['veri'] != null
          ? List<Map<String, dynamic>>.from(json['veri'])
          : (json['guncel_veri'] != null
              ? List<Map<String, dynamic>>.from(json['guncel_veri'])
              : []),
      eklenenId: json['id']?.toString(),
    );
  }
}

/// Veritabanı işlemlerini yürüten ana servis sınıfı.
class SqlServis {
  static const String _siteUrl = "http://codefellas.com.tr/apps/nivi/api/api.php";
  static const String _apiKey = "GizliAnahtar_Codefellas_2026!";

  static Future<ApiResponse> _istekGonder({
    required String islem,
    required String tablo,
    Map<String, dynamic>? veriler,
    Map<String, dynamic>? sartlar,
    String? geriDondur,
  }) async {
    try {
      var bodyData = {
        'api_key': _apiKey,
        'islem': islem,
        'tablo': tablo,
        'veriler': jsonEncode(veriler ?? {}),
        'sartlar': jsonEncode(sartlar ?? {}),
        'geri_dondur': geriDondur ?? '',
      };

      var response = await http.post(Uri.parse(_siteUrl), body: bodyData);

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(jsonDecode(response.body));
      } else {
        return ApiResponse(
          basarili: false,
          mesaj: "HTTP Hatası: ${response.statusCode}",
          veri: [],
        );
      }
    } catch (e) {
      return ApiResponse(
        basarili: false,
        mesaj: "Bağlantı Hatası: $e",
        veri: [],
      );
    }
  }

  // =========================================================================
  // TEMEL CRUD İŞLEMLERİ (Ekle, Güncelle, Sil, Çek)
  // =========================================================================

  static Future<ApiResponse> ekle({
    required String tablo,
    required Map<String, dynamic> veriler,
    String? geriDondur,
  }) async {
    return await _istekGonder(islem: 'ekle', tablo: tablo, veriler: veriler, geriDondur: geriDondur);
  }

  static Future<ApiResponse> guncelle({
    required String tablo,
    required Map<String, dynamic> veriler,
    required Map<String, dynamic> sartlar,
    String? geriDondur,
  }) async {
    return await _istekGonder(islem: 'guncelle', tablo: tablo, veriler: veriler, sartlar: sartlar, geriDondur: geriDondur);
  }

  static Future<ApiResponse> sil({
    required String tablo,
    required Map<String, dynamic> sartlar,
  }) async {
    return await _istekGonder(islem: 'sil', tablo: tablo, sartlar: sartlar);
  }

  static Future<ApiResponse> cek({
    required String tablo,
    Map<String, dynamic>? sartlar,
  }) async {
    String islemTipi = (sartlar == null || sartlar.isEmpty) ? 'cek' : 'ozel_cek';
    return await _istekGonder(islem: islemTipi, tablo: tablo, sartlar: sartlar);
  }

  // =========================================================================
  // AUTH (GİRİŞ / KAYIT) İŞLEMLERİ
  // =========================================================================

  /// 🔐 **Kullanıcı Giriş Kontrolü (Login)**
  /// E-posta ve şifre eşleşirse veritabanındaki kullanıcı bilgilerini döner.
  static Future<ApiResponse> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    ApiResponse res = await cek(
      tablo: Tablolar.hesaplar,
      sartlar: {
        "eposta": eposta,
        "sifre": sifre,
      },
    );

    if (res.basarili && res.veri.isEmpty) {
      return ApiResponse(
        basarili: false,
        mesaj: "E-posta veya şifre hatalı.",
        veri: [],
      );
    }
    return res;
  }

  /// 📝 **Benzersizlik Kontrollü Hesap Oluşturma (Register)**
  /// Kayıt öncesi e-posta ve kullanıcı adının (ad) veritabanında olup olmadığını kontrol eder.
  static Future<ApiResponse> hesapOlustur({
    required String ad,
    required String eposta,
    required String sifre,
    Map<String, dynamic>? ekAlanlar,
  }) async {
    
    // 1. E-posta zaten var mı?
    ApiResponse epostaKontrol = await cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"eposta": eposta},
    );
    if (epostaKontrol.basarili && epostaKontrol.veri.isNotEmpty) {
      return ApiResponse(basarili: false, mesaj: "Bu e-posta adresi zaten kayıtlı.", veri: []);
    }

    // 2. Kullanıcı adı (ad) zaten alınmış mı?
    ApiResponse adKontrol = await cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"ad": ad},
    );
    if (adKontrol.basarili && adKontrol.veri.isNotEmpty) {
      return ApiResponse(basarili: false, mesaj: "Bu kullanıcı adı zaten alınmış.", veri: []);
    }

    // 3. Kontroller temizse veriyi hazırla ve ekle
    Map<String, dynamic> kayitVerileri = {
      "ad": ad,
      "eposta": eposta,
      "sifre": sifre,
      "durum": "aktif",
      "bakiye": "0",
      "tarih": DateTime.now().toString().substring(0, 10)
    };

    if (ekAlanlar != null) {
      kayitVerileri.addAll(ekAlanlar);
    }

    return await ekle(
      tablo: Tablolar.hesaplar,
      veriler: kayitVerileri,
      geriDondur: "*" 
    );
  }
}