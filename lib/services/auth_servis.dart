import 'dart:convert';

import 'package:http/http.dart' as http;

import 'sql_servis.dart';

class AuthServis {
  static Future<ApiResponse> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    ApiResponse res = await SqlServis.cek(
      tablo: Tablolar.hesaplar,
      sartlar: {
        "eposta": eposta,
        "sifre_hash": sifre, // DB'deki sütun adı
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

  static Future<ApiResponse> hesapOlustur({
    required String kullaniciAdi,
    required String eposta,
    required String sifre,
    required String dogumTarihi,
    required String cinsiyet,
    Map<String, dynamic>? ekAlanlar,
  }) async {
    // E-posta ve Kullanıcı adı kontrolü
    ApiResponse epostaKontrol = await SqlServis.cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"eposta": eposta},
    );
    if (epostaKontrol.basarili && epostaKontrol.veri.isNotEmpty)
      return ApiResponse(
        basarili: false,
        mesaj: "Bu e-posta kayıtlı.",
        veri: [],
      );

    ApiResponse adKontrol = await SqlServis.cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"kullanici_adi": kullaniciAdi},
    );
    if (adKontrol.basarili && adKontrol.veri.isNotEmpty)
      return ApiResponse(
        basarili: false,
        mesaj: "Bu kullanıcı adı alınmış.",
        veri: [],
      );

    // Veritabanı şemasına uygun kayıt
    Map<String, dynamic> kayitVerileri = {
      "kullanici_adi": kullaniciAdi,
      "isim": kullaniciAdi, // Başlangıçta aynı yapıyoruz
      "soy_isim": "",
      "eposta": eposta,
      "sifre_hash": sifre,
      "dogum_tarihi": dogumTarihi,
      "cinsiyet": cinsiyet,
      "xp_puani": 0,
      "birinci_coin_bakiye": 0,
      "yasakli_mi": 0,
      "onayli_hesap": 0,
      "ajansvarmi": 0,
    };

    if (ekAlanlar != null) kayitVerileri.addAll(ekAlanlar);

    return await SqlServis.ekle(
      tablo: Tablolar.hesaplar,
      veriler: kayitVerileri,
      geriDondur: "*",
    );
  }

  // =========================================================================
  // E-POSTA DOĞRULAMA KODU GÖNDERME
  // =========================================================================
  static Future<Map<String, dynamic>> epostaDogrulamaKoduGonder(
    String eposta,
  ) async {
    try {
      // FTP'ye attığımız send_email.php dosyasının tam yolu
      final response = await http.post(
        Uri.parse('https://codefellas.com.tr/apps/nivi/mail/send_email.php'),
        body: {'eposta': eposta},
      );

      final data = jsonDecode(response.body);

      if (data['durum'] == 'basarili') {
        return {
          'basarili': true,
          'kod': data['dogrulama_kodu']
              .toString(), // PHP'den dönen 6 haneli kod
        };
      } else {
        return {
          'basarili': false,
          'mesaj': data['mesaj'] ?? 'Mail gönderilemedi.',
        };
      }
    } catch (e) {
      return {'basarili': false, 'mesaj': 'Bağlantı hatası: $e'};
    }
  }
}
