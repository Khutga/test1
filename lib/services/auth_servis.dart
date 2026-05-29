import 'sql_servis.dart'; // SqlServis sınıfının bulunduğu dosya yolu

class AuthServis {
  
  /// 🔐 **Kullanıcı Giriş Kontrolü (Login)**
  /// 
  /// E-posta ve şifre eşleşirse veritabanındaki kullanıcı bilgilerini döner.
  static Future<ApiResponse> girisYap({
    required String eposta,
    required String sifre,
  }) async {
    ApiResponse res = await SqlServis.cek(
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
  /// 
  /// Kayıt öncesi e-posta ve kullanıcı adının (ad) veritabanında olup olmadığını kontrol eder.
  static Future<ApiResponse> hesapOlustur({
    required String ad,
    required String eposta,
    required String sifre,
    Map<String, dynamic>? ekAlanlar,
  }) async {
    
    // 1. Adım: E-posta zaten var mı?
    ApiResponse epostaKontrol = await SqlServis.cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"eposta": eposta},
    );
    if (epostaKontrol.basarili && epostaKontrol.veri.isNotEmpty) {
      return ApiResponse(
        basarili: false,
        mesaj: "Bu e-posta adresi zaten kayıtlı.",
        veri: [],
      );
    }

    // 2. Adım: Kullanıcı adı (ad) zaten alınmış mı?
    ApiResponse adKontrol = await SqlServis.cek(
      tablo: Tablolar.hesaplar,
      sartlar: {"ad": ad},
    );
    if (adKontrol.basarili && adKontrol.veri.isNotEmpty) {
      return ApiResponse(
        basarili: false,
        mesaj: "Bu kullanıcı adı zaten alınmış.",
        veri: [],
      );
    }

    // 3. Adım: Kontroller temizse veriyi hazırla ve ekle
    Map<String, dynamic> kayitVerileri = {
      "ad": ad,
      "eposta": eposta,
      "sifre": sifre,
      "durum": "aktif",
      "bakiye": "0",
      "tarih": DateTime.now().toString().substring(0, 10)
    };

    // Formdan gelen telefon, notlar vb. ekstra kolonlar varsa ekle
    if (ekAlanlar != null) {
      kayitVerileri.addAll(ekAlanlar);
    }

    return await SqlServis.ekle(
      tablo: Tablolar.hesaplar,
      veriler: kayitVerileri,
      geriDondur: "*" // Kayıt başarılıysa kullanıcının tüm satır verisini geri döndür
    );
  }
}