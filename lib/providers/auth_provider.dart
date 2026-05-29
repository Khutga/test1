import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sadece giriş yapıp yapmadığını (true/false) tutan basit bir yapı
class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _initCheck();
  }

  /// Uygulama açıldığında sadece hafızaya bakar, API'ye falan bağlanmaz.
  Future<void> _initCheck() async {
    
    try {
      
      final prefs = await SharedPreferences.getInstance();
      // Hafızada kullanıcı ID'si var mı?
      final int? kayitliId = prefs.getInt('kullanici_id');

      if (kayitliId != null) {
        // ID varsa direkt içeri al
        state = const AsyncValue.data(true);
      } else {
        // Yoksa kayıt ekranına yönlendir
        state = const AsyncValue.data(false);
      }
    } catch (e) {
      // Herhangi bir hata olursa uygulamanın çökmesi yerine kayıt ekranına at
      state = const AsyncValue.data(false);
    }
  }

  /// ŞİMDİLİK KULLANACAĞIN TEST GİRİŞİ (ID: 1)
  Future<void> testGirisYap() async {
    state = const AsyncValue.loading(); // Yükleniyor animasyonu gösterir
    final prefs = await SharedPreferences.getInstance();
    
    // Hafızaya 1 ID'sini çakıyoruz
    await prefs.setInt('kullanici_id', 1); 
    
    // Durumu giriş yapıldı (true) olarak güncelliyoruz
    state = const AsyncValue.data(true);
  }

  /// Çıkış Yap
  Future<void> cikisYap() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kullanici_id'); // Hafızadan sil
    state = const AsyncValue.data(false); // Durumu çıkış yapıldıya çek
  }
}

// Tüm projeden erişeceğimiz o basit provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier();
});