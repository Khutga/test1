import 'package:nivi/services/sql_servis.dart';

class EkonomiServis {
  /// Hediye gönderildiğinde çalışır.
  /// Gönderenden tam fiyatı düşer, alıcıya (ve varsa ajans liderine) komisyonlu dağıtır.
  static Future<Map<String, dynamic>> hediyeIslemiYap({
    required int gonderenId,
    required int alanId,
    required int hediyeFiyati,
  }) async {
    // 1. Gönderenin bakiyesini kontrol et
    final gonderenRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': gonderenId});
    if (!gonderenRes.basarili || gonderenRes.veri.isEmpty) {
      return {'basarili': false, 'mesaj': 'Hesap bilgileriniz alınamadı. Lütfen tekrar deneyin.'};
    }

    int gonderenBakiye = (double.tryParse(gonderenRes.veri.first['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
    if (gonderenBakiye < hediyeFiyati) {
      return {'basarili': false, 'mesaj': 'Bu hediyeyi göndermek için bakiyeniz yetersiz!'};
    }

    // 2. Alıcının bilgilerini ve Ajans durumunu çek
    final alanRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': alanId});
    if (!alanRes.basarili || alanRes.veri.isEmpty) {
       return {'basarili': false, 'mesaj': 'Alıcı bilgileri bulunamadı.'};
    }

    int alanBakiye = (double.tryParse(alanRes.veri.first['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
    bool ajansVarMi = (int.tryParse(alanRes.veri.first['ajansvarmi'].toString()) ?? 0) == 1;

    int netKazanc = hediyeFiyati; 
    int liderKazanci = 0;
    int liderId = 0;

    // 3. Alıcı bir ajansa üyeyse komisyonu hesapla
    if (ajansVarMi) {
      final uyeRes = await SqlServis.cek(tablo: 'ajans_uyeleri', sartlar: {'uye_id': alanId});
      if (uyeRes.basarili && uyeRes.veri.isNotEmpty) {
        liderId = int.tryParse(uyeRes.veri.first['ajans_sahibi_id'].toString()) ?? 0;

        // 🔥 YENİ: Admin panelden dinamik oranı çek. Başarısız olursa işlemi anında İPTAL ET.
        final ayarRes = await SqlServis.cek(tablo: 'sistem_ayarlari', sartlar: {'ayar_adi': 'ajans_komisyon_orani'});
        if (!ayarRes.basarili || ayarRes.veri.isEmpty) {
          return {'basarili': false, 'mesaj': 'Sistem hatası: Komisyon oranı veritabanından çekilemedi! İşlem iptal edildi.'};
        }

        // Değeri parse et, sayı değilse veya null ise yine hata ver
        int komisyonOrani = int.tryParse(ayarRes.veri.first['ayar_degeri'].toString()) ?? -1;
        if (komisyonOrani < 0) {
           return {'basarili': false, 'mesaj': 'Sistem hatası: Geçersiz komisyon oranı tanımlı! İşlem iptal edildi.'};
        }

        // Kesinti Matematiği
        liderKazanci = ((hediyeFiyati * komisyonOrani) / 100).floor();
        netKazanc = hediyeFiyati - liderKazanci;
      }
    }

    // -- SQL BAĞLANTISI VE MATEMATİK DOĞRULANDI, ARTIK PARAYI DAĞITABİLİRİZ --
    
    // Gönderenden tam coini düş
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': gonderenBakiye - hediyeFiyati},
      sartlar: {'id': gonderenId},
    );

    // Alıcıya net kazancı ekle (Kesilmiş hali)
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': alanBakiye + netKazanc},
      sartlar: {'id': alanId},
    );

    // Lider varsa lidere komisyonu ekle
    if (liderKazanci > 0 && liderId > 0 && liderId != alanId) {
      final liderRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': liderId});
      if (liderRes.basarili && liderRes.veri.isNotEmpty) {
        int liderBakiye = (double.tryParse(liderRes.veri.first['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
        await SqlServis.guncelle(
          tablo: 'hesaplar',
          veriler: {'birinci_coin_bakiye': liderBakiye + liderKazanci},
          sartlar: {'id': liderId},
        );
      }
    }

    return {'basarili': true, 'mesaj': 'Başarılı'}; 
  }
}