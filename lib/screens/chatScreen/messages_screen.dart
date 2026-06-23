import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/sql_servis.dart';
import 'chat_screen.dart';
import '../announcements_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  int _kendiId = 1;

  // İsimleri sürekli veritabanından çekip telefonu yormamak için basit bir hafıza
  final Map<int, String> _userCache = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    _kendiId = prefs.getInt('kullanici_id') ?? 1;

    await _fetchChats();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchChats();
    });
  }

  Future<void> _fetchChats() async {
    // 1. Bizim gönderdiğimiz ve bize gelen tüm mesajları çekelim
    final gidenRes = await SqlServis.cek(
      tablo: 'mesajlar',
      sartlar: {'gonderen_id': _kendiId},
    );
    final gelenRes = await SqlServis.cek(
      tablo: 'mesajlar',
      sartlar: {'alan_id': _kendiId},
    );

    // 🔥 YENİ: İLİŞKİ SEVİYELERİNİ ÇEKELİM (PHP API 'OR' Anlamadığı için 2 sorgu atıyoruz)
    final relRes1 = await SqlServis.cek(
      tablo: 'sohbet_iliskileri',
      sartlar: {'kullanici1_id': _kendiId},
    );
    final relRes2 = await SqlServis.cek(
      tablo: 'sohbet_iliskileri',
      sartlar: {'kullanici2_id': _kendiId},
    );

    if (!mounted) return;

    // Mesajları Birleştir
    List<dynamic> allMessages = [];
    if (gidenRes.basarili) allMessages.addAll(gidenRes.veri);
    if (gelenRes.basarili) allMessages.addAll(gelenRes.veri);

    if (allMessages.isEmpty) {
      setState(() {
        _chatList = [];
        _isLoading = false;
      });
      return;
    }

    // İlişki Seviyelerini Birleştir (Hangi partnerle kaçıncı seviyedeyiz?)
    Map<int, int> relationshipLevels = {};
    if (relRes1.basarili) {
      for (var r in relRes1.veri) {
        int partnerId = int.tryParse(r['kullanici2_id'].toString()) ?? 0;
        relationshipLevels[partnerId] =
            int.tryParse(r['seviye'].toString()) ?? 1;
      }
    }
    if (relRes2.basarili) {
      for (var r in relRes2.veri) {
        int partnerId = int.tryParse(r['kullanici1_id'].toString()) ?? 0;
        relationshipLevels[partnerId] =
            int.tryParse(r['seviye'].toString()) ?? 1;
      }
    }

    // 2. Konuştuğumuz benzersiz kişileri bulalım (Partner ID'leri)
    Set<int> partnerIds = {};
    for (var m in allMessages) {
      int gId = int.tryParse(m['gonderen_id'].toString()) ?? 0;
      int aId = int.tryParse(m['alan_id'].toString()) ?? 0;
      partnerIds.add(gId == _kendiId ? aId : gId);
    }

    // 3. Bilinmeyen isimleri veritabanından çekip Cache'e ekleyelim
    for (int pId in partnerIds) {
      if (!_userCache.containsKey(pId)) {
        final userRes = await SqlServis.cek(
          tablo: 'hesaplar',
          sartlar: {'id': pId},
        );
        if (userRes.basarili && userRes.veri.isNotEmpty) {
          _userCache[pId] = userRes.veri.first['isim'] ?? 'Bilinmiyor';
        } else {
          _userCache[pId] = 'Kullanıcı $pId';
        }
      }
    }

    if (!mounted) return;

    // 4. Mesajları kişilere göre grupla, son mesajı ve okunmamış sayısını bul
    List<Map<String, dynamic>> tempChatList = [];

    for (int pId in partnerIds) {
      // Bu kişiyle olan tüm mesajları filtrele
      var partnerMsgs = allMessages.where((m) {
        return (m['gonderen_id'].toString() == pId.toString() &&
                m['alan_id'].toString() == _kendiId.toString()) ||
            (m['alan_id'].toString() == pId.toString() &&
                m['gonderen_id'].toString() == _kendiId.toString());
      }).toList();

      if (partnerMsgs.isEmpty) continue;

      //  MESAJLARI İKİYE BÖLÜYORUZ: NORMAL VE GİZLİ
      var gizliMsgs = partnerMsgs
          .where((m) => m['gizli_mi'].toString() == '1')
          .toList();
      var normalMsgs = partnerMsgs
          .where((m) => m['gizli_mi'].toString() != '1')
          .toList();

      // Sohbet satırı oluşturan yardımcı fonksiyon
      void sohbetEkle(List<dynamic> mesajListesi, bool gizliSohbetMi) {
        if (mesajListesi.isEmpty) return;

        mesajListesi.sort(
          (a, b) => a['olusturulma_tarihi'].compareTo(b['olusturulma_tarihi']),
        );
        var lastMsg = mesajListesi.last;
        int unreadCount = mesajListesi
            .where(
              (m) =>
                  m['gonderen_id'].toString() == pId.toString() &&
                  m['okundu_mu'].toString() == "0",
            )
            .length;

        String msgText = lastMsg['mesaj'] ?? '';
        if (lastMsg['is_gift'].toString() == "1") {
          msgText = "🎁 Hediye gönderdi";
        } else if (lastMsg['medya_url'] != null &&
            lastMsg['medya_url'].toString().isNotEmpty) {
          msgText = lastMsg['medya_tipi'] == 'resim'
              ? "📷 Fotoğraf gönderdi"
              : "🎥 Video gönderdi";
        }

        String timeStr = "Şimdi";
        try {
          DateTime dt = DateTime.parse(lastMsg['olusturulma_tarihi']);
          timeStr =
              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
        } catch (e) {}

        //  İSİM BELİRLEME MANTIĞI: Bize geldiyse "Gizli Hayran", biz attıysak "Kişi (Gizli)"
        String gorunenIsim = _userCache[pId] ?? 'Bilinmiyor';
        if (gizliSohbetMi) {
          bool bizMiBaslattik =
              mesajListesi.first['gonderen_id'].toString() ==
              _kendiId.toString();
          gorunenIsim = bizMiBaslattik
              ? "$gorunenIsim (Gizli)"
              : "Gizli Hayran";
        }

        int gercekSeviye = relationshipLevels[pId] ?? 1;
        int dinamikUyum = min(99, 60 + (gercekSeviye * 4));

        tempChatList.add({
          'id': pId,
          'name': gorunenIsim,
          'is_gizli': gizliSohbetMi, // UI İÇİN GİZLİLİK BAYRAĞI
          'msg': msgText,
          'time': timeStr,
          'unread': unreadCount,
          'soulMatch': gizliSohbetMi
              ? null
              : dinamikUyum, // Gizli fanda seviye gizlenir
          'coupleLevel': gizliSohbetMi ? null : gercekSeviye,
          'raw_date': lastMsg['olusturulma_tarihi'],
        });
      }

      sohbetEkle(normalMsgs, false); // Normal sohbeti listeye ekle
      sohbetEkle(
        gizliMsgs,
        true,
      ); // Varsa gizli sohbeti AYRI BİR SATIR olarak listeye ekle
    }

    // 5. Listeyi son mesaj tarihine göre (Yeniden eskiye) sırala
    tempChatList.sort((a, b) => b['raw_date'].compareTo(a['raw_date']));

    if (mounted) {
      setState(() {
        _chatList = tempChatList;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mesajlar",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
          ),
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ─── DUYURU BANNER ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnnouncementsScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.zap,
                          color: AppTheme.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Sistem Duyuruları & PK",
                              style: TextStyle(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "Turnuvaları izlemek için tıklayın.",
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        color: context.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // ─── MESAJ LİSTESİ ───
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      )
                    : _chatList.isEmpty
                    ? Center(
                        child: Text(
                          "Henüz bir mesajın yok.\nYayınlara katılıp sohbet etmeye başla!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ).copyWith(bottom: 90),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _chatList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final msg = _chatList[index];
                          final bool isGizli = msg['is_gizli'] == true;
                          return GlassContainer(
                            padding: const EdgeInsets.all(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    chatData: msg,
                                    gizliMod: isGizli,
                                  ),
                                ),
                              ).then((_) {
                                _fetchChats();
                              });
                            },
                            child: Row(
                              children: [
                                // Avatar + online dot
                                Stack(
                                  children: [
                                    if (isGizli)
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.purple
                                            .withOpacity(0.2),
                                        child: const Icon(
                                          LucideIcons.venetianMask,
                                          color: Colors.purple,
                                        ),
                                      )
                                    else
                                      GlowAvatar(
                                        initial:
                                            msg['name'].toString().isNotEmpty
                                            ? msg['name'][0]
                                            : '?',
                                        radius: 25,
                                      ),

                                    if (!isGizli) // Gizli hayranın online olduğu görünmesin
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 15,
                                          height: 15,
                                          decoration: BoxDecoration(
                                            color: AppTheme.success,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.card,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 10),

                                // İçerik
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            msg['name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            msg['time'],
                                            style: TextStyle(
                                              color: context.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        msg['msg'],
                                        style: TextStyle(
                                          color: msg['unread'] > 0
                                              ? context.textPrimary
                                              : context.textSecondary,
                                          fontSize: 14,
                                          fontWeight: msg['unread'] > 0
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          if (msg['soulMatch'] != null)
                                            GradientBadge(
                                              text: "%${msg['soulMatch']} Uyum",
                                              icon: LucideIcons.zap,
                                            ),
                                          if (msg['soulMatch'] != null)
                                            const SizedBox(width: 4),

                                          // 🔥 GERÇEK SEVİYE BURADA BASILIYOR 🔥
                                          if (msg['coupleLevel'] != null)
                                            GradientBadge(
                                              text: "Lv.${msg['coupleLevel']}",
                                              icon: LucideIcons.heart,
                                              color: AppTheme.danger,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Okunmamış badge
                                if (msg['unread'] > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 15),
                                    width: 25,
                                    height: 25,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        msg['unread'].toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
