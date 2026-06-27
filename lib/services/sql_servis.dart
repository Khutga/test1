import 'dart:convert';
import 'package:http/http.dart' as http;

/// Veritabanındaki tabloları temsil eder.
class Tablolar {
  static const String hesaplar = "hesaplar";
  static const String atilanHediyeler = "atilanHediyeler";
  static const String basarimlar = "basarimlar";
  static const String kullaniciBasarimlari = "kullanici_basarimlari";
  static const String rozetler = "rozetler";
  static const String kullaniciRozetleri = "kullanici_rozetleri";
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
    String? islem, // 🔥 Yeni: Dışarıdan özel işlem tipi belirtebilmek için isteğe bağlı parametre
  }) async {
    // Eğer dışarıdan özel bir işlem (örn: 'arama_cek') gönderilmediyse eski mantık çalışır
    String islemTipi = islem ?? ((sartlar == null || sartlar.isEmpty) ? 'cek' : 'ozel_cek');
    
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
  

  static Future<void> otomatikRozetleriKontrolEt(int kullaniciId) async {
    
    var rozetRes = await cek(tablo: Tablolar.rozetler, sartlar: {'otomatik_verilecek_mi': '1'});
    if (!rozetRes.basarili || rozetRes.veri.isEmpty) return;

    var userRes = await cek(tablo: 'hesaplar', sartlar: {'id': kullaniciId.toString()});
    if (!userRes.basarili || userRes.veri.isEmpty) return;
    var user = userRes.veri.first;
    
    String olusturulmaStr = user['olusturulma_tarihi']?.toString() ?? '';
    if (olusturulmaStr.isEmpty) return;
    DateTime olusturulmaTarihi = DateTime.tryParse(olusturulmaStr) ?? DateTime.now();
    int hesapYasiGun = DateTime.now().difference(olusturulmaTarihi).inDays;

    var kbRes = await cek(tablo: Tablolar.kullaniciRozetleri, sartlar: {'kullanici_id': kullaniciId.toString()});
    List<String> sahipOlunanRozetIdleri = [];
    if (kbRes.basarili && kbRes.veri.isNotEmpty) {
      sahipOlunanRozetIdleri = kbRes.veri.map((e) => e['rozet_id'].toString()).toList();
    }

    int toplamEklenecekOdul = 0;

    for (var rozet in rozetRes.veri) {
      String rId = rozet['id'].toString();
      int gerekenGun = int.tryParse(rozet['gereken_gun_sayisi']?.toString() ?? '0') ?? 0;
      int odul = int.tryParse(rozet['odul_coin']?.toString() ?? '0') ?? 0;

      if (hesapYasiGun >= gerekenGun && !sahipOlunanRozetIdleri.contains(rId)) {
        await ekle(
          tablo: Tablolar.kullaniciRozetleri,
          veriler: {
            'kullanici_id': kullaniciId.toString(),
            'rozet_id': rId,
          }
        );
        toplamEklenecekOdul += odul;
      }
    }

    if (toplamEklenecekOdul > 0) {
      double mevcutParaDouble = double.tryParse(user['birinci_coin_bakiye']?.toString() ?? '0') ?? 0;
      int yeniBakiye = mevcutParaDouble.toInt() + toplamEklenecekOdul;
      
      await guncelle(
        tablo: 'hesaplar',
        veriler: {'birinci_coin_bakiye': yeniBakiye.toString()},
        sartlar: {'id': kullaniciId.toString()}
      );
    }
  }

  // 🔥 XP EKLEME SERVİSİ
  static Future<bool> xpEkle(int kullaniciId, String islemTipi, int miktar) async {
    try {
      final response = await http.post(
        Uri.parse("http://codefellas.com.tr/apps/nivi/api/xp_islem.php"), // Kendi API yoluna göre kontrol et
        body: {
          'kullanici_id': kullaniciId.toString(),
          'islem_tipi': islemTipi, // Örn: 'mesaj', 'hediye_gonder', 'yayin_dakika'
          'miktar': miktar.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['durum'] == 'basarili';
      }
    } catch (e) {
      print("XP Ekleme Hatası: $e");
    }
    return false;
  }
  
  }