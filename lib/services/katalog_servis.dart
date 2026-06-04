import 'package:flutter/material.dart';
import 'sql_servis.dart';

/// Hediye ve Coin Paketlerini veritabanından çekip hafızada tutan servis.
/// Tüm ekranlar bu servisten okur, her seferinde SQL'e gitmez.
class KatalogServis {
  static final ValueNotifier<List<Map<String, dynamic>>> coinPaketleri = ValueNotifier([]);
  static final ValueNotifier<List<Map<String, dynamic>>> sohbetHediyeleri = ValueNotifier([]);
  static final ValueNotifier<List<Map<String, dynamic>>> yayinHediyeleri = ValueNotifier([]);

  static bool _yuklendi = false;

  /// Uygulama açılışında 1 kere çağır (MainNavigator initState'te).
  /// force: true ile admin panelden değişiklik yapınca yeniden yükler.
  static Future<void> yukle({bool force = false}) async {
    if (_yuklendi && !force) return;

    // Coin Paketleri
    final coinRes = await SqlServis.cek(tablo: 'coin_paketleri', sartlar: {'aktif_mi': 1});
    if (coinRes.basarili) {
      final list = coinRes.veri;
      list.sort((a, b) => _safeInt(a['sira']).compareTo(_safeInt(b['sira'])));
      coinPaketleri.value = list;
    }

    // Hediyeler
    final hediyeRes = await SqlServis.cek(tablo: 'hediyeler', sartlar: {'aktif_mi': 1});
    if (hediyeRes.basarili) {
      final hepsi = hediyeRes.veri;
      hepsi.sort((a, b) => _safeInt(a['sira']).compareTo(_safeInt(b['sira'])));

      sohbetHediyeleri.value = hepsi
          .where((h) => h['kategori'] == 'sohbet' || h['kategori'] == 'hepsi')
          .map(_formatHediye)
          .toList();

      yayinHediyeleri.value = hepsi
          .where((h) => h['kategori'] == 'yayin' || h['kategori'] == 'hepsi')
          .map(_formatHediye)
          .toList();
    }

    _yuklendi = true;
  }

  static Map<String, dynamic> _formatHediye(Map<String, dynamic> h) => {
        'icon': h['emoji'] ?? '🎁',
        'name': h['hediye_adi'] ?? '',
        'cost': _safeInt(h['fiyat_coin']),
        'emoji': h['emoji'] ?? '🎁',
        'price': _safeInt(h['fiyat_coin']),
      };

  static int _safeInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
}