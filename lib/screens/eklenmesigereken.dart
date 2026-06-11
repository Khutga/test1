// ============================================================
// 4. PROFİLE TIKLAMA — Eklemen gereken yerler
//    (Tam dosya vermiyorum, sadece nereye ne ekleyeceğini söylüyorum)
// ============================================================

// Şu dosyalardaki kullanıcı isimlerine GestureDetector + UserProfileScreen
// navigasyonu eklemen gerekiyor. Import olarak her dosyanın başına ekle:
//
//   import '../../screens/accountScreen/user_profile_screen.dart';
//   (veya dosya yoluna göre düzelt)
//
// Sonra ismin gösterildiği Text widget'ını GestureDetector ile sar:
//
//   GestureDetector(
//     onTap: () => Navigator.push(context, MaterialPageRoute(
//       builder: (_) => UserProfileScreen(hedefKullaniciAdi: isim),
//     )),
//     child: Text(isim, ...),  // mevcut Text widget'ı
//   )
//
// EKLENMESİ GEREKEN DOSYALAR VE SATIRLAR:
//
// A) messages_screen.dart
//    → _chatList kartındaki msg['name'] Text widget'ı (~satır "Text(msg['name']")
//    → Zaten GlassContainer onTap ile ChatScreen'e gidiyor, ama ismin kendisine
//      tıklayınca profil açılması için isim Text'ini GestureDetector ile sar.
//      (GestureDetector içinde Absorbing kullanarak kartın onTap'ını engelle)
//      VEYA daha basit: Kart tıklamasını bırak, sadece uzun basınca profil aç:
//      onLongPress ekle GlassContainer'a.
//      Öneri: GlassContainer'ın onTap'ını ChatScreen'e bırak,
//      ismin üstüne onTap ile UserProfileScreen ekle.
//
// B) chat_screen.dart → AppBar'daki widget.chatData['name']
//    → AppBar title Row içindeki isim Text'ini GestureDetector ile sar
//
// C) audience_live_page.dart → Üst bardaki _activeHostName
//    → Host isminin gösterildiği Text'i GestureDetector ile sar
//
// D) host_live_page.dart → Chat mesajlarındaki msg.sender
//    → Zaten PK başlatma için onTap var, ama host olmayan
//      kullanıcılar için profil açma eklenebilir
//
// E) announcements_screen.dart → item['gonderen_isim']
//    → Gönderen ismini GestureDetector ile sar

