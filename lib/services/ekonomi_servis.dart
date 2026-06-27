import 'package:nivi/services/sql_servis.dart';

class EkonomiServis {
  // =========================================================================
  // 1. HEDİYE GÖNDERME İŞLEMİ
  // =========================================================================
 static Future<Map<String, dynamic>> hediyeIslemiYap({
    required int gonderenId,
    required int alanId,
    required int hediyeFiyati,
    String hediyeAdi = "",
    String hediyeEmoji = "", 
    required int gizliMi,
    String kaynak = 'chat',
  }) async {
    // 1. Gönderenin bakiyesini kontrol et
    final gonderenRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': gonderenId},
    );
    if (!gonderenRes.basarili || gonderenRes.veri.isEmpty) {
      return {
        'basarili': false,
        'mesaj': 'Hesap bilgileriniz alınamadı. Lütfen tekrar deneyin.',
      };
    }

    int gonderenBakiye =
        (double.tryParse(
                  gonderenRes.veri.first['birinci_coin_bakiye'].toString(),
                ) ??
                0.0)
            .toInt();
    if (gonderenBakiye < hediyeFiyati) {
      return {
        'basarili': false,
        'mesaj': 'Bu hediyeyi göndermek için bakiyeniz yetersiz!',
      };
    }

    // 2. Komisyon Oranlarını Çek
    final komisyonRes = await SqlServis.cek(
      tablo: 'komisyon_oranlari',
      sartlar: {'id': 1},
    );
    double standartKomisyon = 20.0;
    double ajanssizEkstra = 15.0;

    if (komisyonRes.basarili && komisyonRes.veri.isNotEmpty) {
      standartKomisyon =
          double.tryParse(
            komisyonRes.veri.first['standart_komisyon_orani'].toString(),
          ) ??
          20.0;
      ajanssizEkstra =
          double.tryParse(
            komisyonRes.veri.first['ajanssiz_ekstra_komisyon'].toString(),
          ) ??
          15.0;
    }

    // 3. Alıcının ajans durumunu kontrol et
    final uyeRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'kullanici_id': alanId},
    );
    bool isAjansta = uyeRes.basarili && uyeRes.veri.isNotEmpty;

    double adminKesintisi = 0;
    double netKazanc = 0;
    String islemTuru = 'ajanssiz';

    // --- SENARYO A: KIZ AJANSTA ---
    if (isAjansta) {
      islemTuru = 'ajansli';
      adminKesintisi = (hediyeFiyati * standartKomisyon) / 100;
      netKazanc = hediyeFiyati - adminKesintisi;

      int ajansId = int.tryParse(uyeRes.veri.first['ajans_id'].toString()) ?? 0;
      final ajansRes = await SqlServis.cek(
        tablo: 'ajanslar',
        sartlar: {'id': ajansId},
      );

      if (ajansRes.basarili && ajansRes.veri.isNotEmpty) {
        double uyePayiOrani =
            double.tryParse(ajansRes.veri.first['uye_payi_orani'].toString()) ??
            60.0;
        double ajansKasa =
            double.tryParse(
              ajansRes.veri.first['ajans_kasa_bakiye'].toString(),
            ) ??
            0.0;

        // 1. Ajansın Kasasını Güncelle
        await SqlServis.guncelle(
          tablo: 'ajanslar',
          veriler: {'ajans_kasa_bakiye': ajansKasa + netKazanc},
          sartlar: {'id': ajansId},
        );

        // 2. Üyenin kazandırdığı ve bekleyen ödemesini güncelle
        double toplamKazandirilan =
            double.tryParse(
              uyeRes.veri.first['toplam_kazandirilan'].toString(),
            ) ??
            0.0;
        double bekleyenOdeme =
            double.tryParse(uyeRes.veri.first['bekleyen_odeme'].toString()) ??
            0.0;
        double kizaEklenecek = (netKazanc * uyePayiOrani) / 100;

        await SqlServis.guncelle(
          tablo: 'ajans_uyeleri',
          veriler: {
            'toplam_kazandirilan': toplamKazandirilan + netKazanc,
            'bekleyen_odeme': bekleyenOdeme + kizaEklenecek,
          },
          sartlar: {'kullanici_id': alanId},
        );
      }
    }
    // --- SENARYO B: KIZ AJANSTA DEĞİL ---
    else {
      islemTuru = 'ajanssiz';
      adminKesintisi =
          (hediyeFiyati * (standartKomisyon + ajanssizEkstra)) / 100;
      netKazanc = hediyeFiyati - adminKesintisi;

      // Alıcıya net kazancı anında ÇEKİLEBİLİR (İkinci Coin) cüzdanına ekle
      final alanRes = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: {'id': alanId},
      );
      if (alanRes.basarili && alanRes.veri.isNotEmpty) {
        double alanIkinciBakiye =
            double.tryParse(
              alanRes.veri.first['ikinci_coin_bakiye'].toString(),
            ) ??
            0.0;
        await SqlServis.guncelle(
          tablo: 'hesaplar',
          veriler: {
            'ikinci_coin_bakiye': alanIkinciBakiye + netKazanc,
          }, // 🔥 2. Coin
          sartlar: {'id': alanId},
        );
      }
    }

    // --- ORTAK İŞLEMLER ---
    // Gönderenin HARCAMA cüzdanından (1. Coin) tam tutarı düş
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {
        'birinci_coin_bakiye': gonderenBakiye - hediyeFiyati,
      }, // 🔥 1. Coin
      sartlar: {'id': gonderenId},
    );

    // İşlemi Log tablosuna kaydet
    String gonderenIsim = gonderenRes.veri.first['isim'] ?? 'Bilinmiyor';
    String alanIsim = "Bilinmiyor";
    final alanRes2 = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': alanId},
    );
    if (alanRes2.basarili && alanRes2.veri.isNotEmpty) {
      alanIsim = alanRes2.veri.first['isim'] ?? 'Bilinmiyor';
    }

    await SqlServis.ekle(
      tablo: 'hediye_gecmisi',
      veriler: {
        'gonderen_id': gonderenId,
        'gonderen_isim': gonderenIsim,
        'alan_id': alanId,
        'alan_isim': alanIsim,
        'hediye_adi': hediyeAdi,
        'hediye_emoji': hediyeEmoji,
        'coin_miktari': hediyeFiyati,
        'admin_kesintisi': adminKesintisi,
        'alici_net_kazanc': netKazanc,
        'islem_turu': islemTuru,
        'gizli_mi': gizliMi,  
        'kaynak': kaynak    
      },
    );

    //  XP SİSTEMİ ENTEGRASYONU BAŞLANGICI
    // Gönderen kişiye harcadığı coin kadar (örneğin 500 coin = 500 miktar) hediye_gonder XP'si ekle
    await SqlServis.xpEkle(gonderenId, 'hediye_gonder', hediyeFiyati);

    // Alan kişiye kazandığı/aldığı coin kadar hediye_al XP'si ekle
    await SqlServis.xpEkle(alanId, 'hediye_al', hediyeFiyati);
    //  XP SİSTEMİ ENTEGRASYONU BİTİŞİ 

    return {'basarili': true, 'mesaj': 'Hediye başarıyla gönderildi.'};
  }

  
  // =========================================================================
  // 2. NORMAL MESAJ GÖNDERME İŞLEMİ
  // =========================================================================
  static Future<Map<String, dynamic>> normalMesajIslemiYap({
    required int gonderenId,
    required int alanId,
  }) async {
    final ayarlarRes = await SqlServis.cek(tablo: 'sistem_ayarlari');
    int mesajUcreti = 1;

    if (ayarlarRes.basarili) {
      for (var a in ayarlarRes.veri) {
        if (a['ayar_adi'] == 'mesaj_ucreti') {
          mesajUcreti = int.tryParse(a['ayar_degeri'].toString()) ?? 1;
        }
      }
    }

    if (mesajUcreti <= 0) return {'basarili': true, 'kesilen_miktar': 0};

    final gonderenRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': gonderenId},
    );
    if (!gonderenRes.basarili || gonderenRes.veri.isEmpty) {
      return {'basarili': false, 'mesaj': 'Hesap bilgileri alınamadı.'};
    }

    int gonderenBakiye =
        (double.tryParse(
                  gonderenRes.veri.first['birinci_coin_bakiye'].toString(),
                ) ??
                0.0)
            .toInt();
    if (gonderenBakiye < mesajUcreti) {
      return {
        'basarili': false,
        'mesaj': 'Yetersiz bakiye! Mesaj başına $mesajUcreti Coin gerekir.',
      };
    }

    final komisyonRes = await SqlServis.cek(
      tablo: 'komisyon_oranlari',
      sartlar: {'id': 1},
    );
    double standartKomisyon = 20.0;
    double ajanssizEkstra = 15.0;

    if (komisyonRes.basarili && komisyonRes.veri.isNotEmpty) {
      standartKomisyon =
          double.tryParse(
            komisyonRes.veri.first['standart_komisyon_orani'].toString(),
          ) ??
          20.0;
      ajanssizEkstra =
          double.tryParse(
            komisyonRes.veri.first['ajanssiz_ekstra_komisyon'].toString(),
          ) ??
          15.0;
    }

    final uyeRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'kullanici_id': alanId},
    );
    bool isAjansta = uyeRes.basarili && uyeRes.veri.isNotEmpty;

    double adminKesintisi = 0;
    double netKazanc = 0;

    // --- DURUM A: KIZ AJANSTA ---
    if (isAjansta) {
      adminKesintisi = (mesajUcreti * standartKomisyon) / 100;
      netKazanc = mesajUcreti - adminKesintisi;

      int ajansId = int.tryParse(uyeRes.veri.first['ajans_id'].toString()) ?? 0;
      final ajansRes = await SqlServis.cek(
        tablo: 'ajanslar',
        sartlar: {'id': ajansId},
      );

      if (ajansRes.basarili && ajansRes.veri.isNotEmpty) {
        double uyePayiOrani =
            double.tryParse(ajansRes.veri.first['uye_payi_orani'].toString()) ??
            60.0;
        double ajansKasa =
            double.tryParse(
              ajansRes.veri.first['ajans_kasa_bakiye'].toString(),
            ) ??
            0.0;

        await SqlServis.guncelle(
          tablo: 'ajanslar',
          veriler: {'ajans_kasa_bakiye': ajansKasa + netKazanc},
          sartlar: {'id': ajansId},
        );

        double toplamKazandirilan =
            double.tryParse(
              uyeRes.veri.first['toplam_kazandirilan'].toString(),
            ) ??
            0.0;
        double bekleyenOdeme =
            double.tryParse(uyeRes.veri.first['bekleyen_odeme'].toString()) ??
            0.0;
        double kizaEklenecek = (netKazanc * uyePayiOrani) / 100;

        await SqlServis.guncelle(
          tablo: 'ajans_uyeleri',
          veriler: {
            'toplam_kazandirilan': toplamKazandirilan + netKazanc,
            'bekleyen_odeme': bekleyenOdeme + kizaEklenecek,
          },
          sartlar: {'kullanici_id': alanId},
        );
      }
    }
    // --- DURUM B: KIZ AJANSTA DEĞİL ---
    else {
      adminKesintisi =
          (mesajUcreti * (standartKomisyon + ajanssizEkstra)) / 100;
      netKazanc = mesajUcreti - adminKesintisi;

      final alanRes = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: {'id': alanId},
      );
      if (alanRes.basarili && alanRes.veri.isNotEmpty) {
        double alanIkinciBakiye =
            double.tryParse(
              alanRes.veri.first['ikinci_coin_bakiye'].toString(),
            ) ??
            0.0;
        await SqlServis.guncelle(
          tablo: 'hesaplar',
          veriler: {
            'ikinci_coin_bakiye': alanIkinciBakiye + netKazanc,
          }, // 🔥 2. Coin
          sartlar: {'id': alanId},
        );
      }
    }

    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {
        'birinci_coin_bakiye': gonderenBakiye - mesajUcreti,
      }, // 🔥 1. Coin
      sartlar: {'id': gonderenId},
    );

    return {'basarili': true, 'kesilen_miktar': mesajUcreti};
  }

  // =========================================================================
  // 🔥 3. YENİ: AJANS ÜYESİNE ÖDEME YAPMA (KASADAN DÜŞ, İKİNCİ CÜZDANA YATIR)
  // =========================================================================
  static Future<Map<String, dynamic>> ajansOdemeYap({
    required int ajansId,
    required int uyeId,
    required int odenecekMiktar,
  }) async {
    // 1. Ajans Kasa Bakiyesini Kontrol Et
    final ajansRes = await SqlServis.cek(
      tablo: 'ajanslar',
      sartlar: {'id': ajansId},
    );
    if (!ajansRes.basarili || ajansRes.veri.isEmpty) {
      return {'basarili': false, 'mesaj': 'Ajans bilgileri bulunamadı.'};
    }

    double ajansKasa =
        double.tryParse(ajansRes.veri.first['ajans_kasa_bakiye'].toString()) ??
        0.0;
    if (ajansKasa < odenecekMiktar) {
      return {
        'basarili': false,
        'mesaj': 'Ajans kasanızda yeterli bakiye yok!',
      };
    }

    // 2. Üyenin Bekleyen Alacağını Kontrol Et
    final uyeRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'kullanici_id': uyeId},
    );
    if (!uyeRes.basarili || uyeRes.veri.isEmpty) {
      return {'basarili': false, 'mesaj': 'Üye ajans tablosunda bulunamadı.'};
    }

    double bekleyenOdeme =
        double.tryParse(uyeRes.veri.first['bekleyen_odeme'].toString()) ?? 0.0;
    if (odenecekMiktar > bekleyenOdeme) {
      return {
        'basarili': false,
        'mesaj':
            'Girilen tutar, üyenin bekleyen alacağından ($bekleyenOdeme) fazla olamaz.',
      };
    }

    // --- İŞLEMLERİ UYGULA ---

    // 1. Kasadan Parayı Düş
    await SqlServis.guncelle(
      tablo: 'ajanslar',
      veriler: {'ajans_kasa_bakiye': ajansKasa - odenecekMiktar},
      sartlar: {'id': ajansId},
    );

    // 2. Üyenin Bekleyen Borcunu Düş
    await SqlServis.guncelle(
      tablo: 'ajans_uyeleri',
      veriler: {'bekleyen_odeme': bekleyenOdeme - odenecekMiktar},
      sartlar: {'kullanici_id': uyeId},
    );

    // 3. Üyenin Çekilebilir Hesabına (İkinci Coin) Parayı Ekle
    final hesapRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': uyeId},
    );
    if (hesapRes.basarili && hesapRes.veri.isNotEmpty) {
      double ikinciCoin =
          double.tryParse(
            hesapRes.veri.first['ikinci_coin_bakiye'].toString(),
          ) ??
          0.0;
      await SqlServis.guncelle(
        tablo: 'hesaplar',
        veriler: {'ikinci_coin_bakiye': ikinciCoin + odenecekMiktar},
        sartlar: {'id': uyeId},
      );
    }

    // 4. Ödemeyi Log Tablosuna Kaydet
    await SqlServis.ekle(
      tablo: 'ajans_odeme_gecmisi',
      veriler: {
        'ajans_id': ajansId,
        'kullanici_id': uyeId,
        'odenen_miktar': odenecekMiktar,
      },
    );

    return {'basarili': true, 'mesaj': 'Ödeme başarıyla gerçekleştirildi.'};
  }
}
