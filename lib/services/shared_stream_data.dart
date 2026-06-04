import 'dart:async';
import 'package:flutter/material.dart';
import 'sql_servis.dart'; // Kendi dosya yoluna göre düzelt

class SharedStreamData {
  // Tüm uygulamanın dinleyeceği ORTAK YAYIN HAVUZU
  static final ValueNotifier<List<Map<String, dynamic>>> streamsNotifier =
      ValueNotifier([]);
  static Timer? _timer;

  // MySQL'den veriyi çeken tek merkez fonksiyon
  static Future<void> fetchStreams() async {
    final res = await SqlServis.cek(
      tablo: 'aktif_yayinlar',
      sartlar: {'yayin_durumu': 'aktif'},
    );
    if (res.basarili) {
      // Veri geldiğinde havuza atar, havuzu dinleyen tüm sayfalar anında güncellenir
      streamsNotifier.value = List<Map<String, dynamic>>.from(res.veri);
      print(
        'Yayın verileri güncellendi: ${streamsNotifier.value.length} yayın bulundu.',
      );
    }
  }

  // Sadece MainNavigator açıldığında 1 kere tetiklenir (15 sn'de bir yeniler)
  static void startPolling() {
    fetchStreams();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchStreams());
  }

  // Uygulama kapanırken arkada çalışmayı durdurur
  static void stopPolling() {
    _timer?.cancel();
  }
}
