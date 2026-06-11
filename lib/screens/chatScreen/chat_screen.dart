import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/services/sql_servis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import '../relationship_screen.dart';
import 'chat_call_screen.dart';
import '../../services/katalog_servis.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const ChatScreen({super.key, required this.chatData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  int _userCoins = 0;
  int _kendiId = 1;
  String _kendiIsmim = "Ben";
  String _kendiCinsiyet = "Erkek";
  int _currentRelationshipLevel = 1; // 🔥 SEVİYE KONTROLÜ İÇİN KRİTİK DEĞİŞKEN

  List<Map<String, dynamic>> _messages = [];
  Timer? _messageCheckTimer;
  bool _isLoading = true;

  List<Map<String, dynamic>> get _giftsList =>
      KatalogServis.sohbetHediyeleri.value;
  final String phpApiUrl = 'http://codefellas.com.tr/apps/nivi/api/api.php';
  final String phpUploadUrl =
      'http://codefellas.com.tr/apps/nivi/api/upload.php';
  final String phpApiKey = 'GizliAnahtar_Codefellas_2026!';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserData();
    await _loadRelationshipLevel();
    await _fetchMessages(scrollToBottom: true);
    _startMessagePolling();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _kendiId = prefs.getInt('kullanici_id') ?? 1;

    final res = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': _kendiId},
    );
    if (res.basarili && res.veri.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _userCoins =
            (double.tryParse(
                      res.veri.first['birinci_coin_bakiye'].toString(),
                    ) ??
                    0.0)
                .toInt();
        _kendiIsmim = res.veri.first['isim'] ?? 'Bilinmiyor';
        _kendiCinsiyet = res.veri.first['cinsiyet'] ?? 'Erkek';
      });
    }
  }

  Future<void> _loadRelationshipLevel() async {
    int karsiId = int.tryParse(widget.chatData['id'].toString()) ?? 0;
    int kucukId = _kendiId < karsiId ? _kendiId : karsiId;
    int buyukId = _kendiId > karsiId ? _kendiId : karsiId;

    final relRes = await SqlServis.cek(
      tablo: 'sohbet_iliskileri',
      sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
    );
    if (relRes.basarili && relRes.veri.isNotEmpty) {
      _currentRelationshipLevel =
          int.tryParse(relRes.veri.first['seviye'].toString()) ?? 1;
    }
  }

  Future<void> _fetchMessages({bool scrollToBottom = false}) async {
    int karsiId = int.tryParse(widget.chatData['id'].toString()) ?? 0;

    final gidenRes = await SqlServis.cek(
      tablo: 'mesajlar',
      sartlar: {'gonderen_id': _kendiId, 'alan_id': karsiId},
    );
    final gelenRes = await SqlServis.cek(
      tablo: 'mesajlar',
      sartlar: {'gonderen_id': karsiId, 'alan_id': _kendiId},
    );

    List<Map<String, dynamic>> yeniMesajlar = [];
    if (gidenRes.basarili)
      yeniMesajlar.addAll(List<Map<String, dynamic>>.from(gidenRes.veri));
    if (gelenRes.basarili)
      yeniMesajlar.addAll(List<Map<String, dynamic>>.from(gelenRes.veri));

    if (yeniMesajlar.isNotEmpty) {
      yeniMesajlar.sort(
        (a, b) => a['olusturulma_tarihi'].compareTo(b['olusturulma_tarihi']),
      );
      if (!mounted) return;

      bool isAtBottom = true;
      if (_scrollController.hasClients) {
        isAtBottom =
            _scrollController.position.pixels >=
            (_scrollController.position.maxScrollExtent - 50);
      }

      setState(() => _messages = yeniMesajlar);

      if (scrollToBottom || isAtBottom) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients)
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
        });
      }
      _markMessagesAsRead(karsiId);
    }
  }

  void _markMessagesAsRead(int karsiId) async {
    await SqlServis.guncelle(
      tablo: 'mesajlar',
      veriler: {'okundu_mu': 1},
      sartlar: {'gonderen_id': karsiId, 'alan_id': _kendiId, 'okundu_mu': 0},
    );
  }

  void _startMessagePolling() {
    _messageCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
      _loadUserData();
    });
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📷 Fotoğraf sunucuya yükleniyor..."),
          duration: Duration(seconds: 2),
        ),
      );

      var request = http.MultipartRequest('POST', Uri.parse(phpUploadUrl));
      request.fields['api_key'] = phpApiKey;
      request.files.add(
        await http.MultipartFile.fromPath('fotoğraf', image.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      if (data['durum'] == 'basarili' && data['url'] != null) {
        String yuklenenUrl = data['url'];
        await _sendMessage(
          textOverride: "📷 Fotoğraf gönderildi",
          mediaUrl: yuklenenUrl,
          mediaType: "resim",
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Yükleme Hatası: ${data['mesaj'] ?? 'Bilinmiyor'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Fotoğraf yükleme hatası: $e");
    }
  }

  Future<void> _sendMessage({
    required String textOverride,
    bool isGift = false,
    String mediaUrl = "",
    String mediaType = "yok",
  }) async {
    final text = textOverride.isEmpty ? _controller.text.trim() : textOverride;
    if (text.isEmpty && mediaUrl.isEmpty) return;

    if (!isGift) {
      if (_userCoins < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Yetersiz Bakiye! Mesaj basına 1 Coin alınır."),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }

      int yeniBakiye = _userCoins - 1;
      await SqlServis.guncelle(
        tablo: 'hesaplar',
        veriler: {'birinci_coin_bakiye': yeniBakiye},
        sartlar: {'id': _kendiId},
      );

      int karsiId = int.tryParse(widget.chatData['id'].toString()) ?? 0;
      if (_kendiCinsiyet == 'Erkek') {
        int kucukId = _kendiId < karsiId ? _kendiId : karsiId;
        int buyukId = _kendiId > karsiId ? _kendiId : karsiId;

        final relRes = await SqlServis.cek(
          tablo: 'sohbet_iliskileri',
          sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
        );
        if (relRes.basarili && relRes.veri.isNotEmpty) {
          int eskiPuan =
              int.tryParse(relRes.veri.first['iliski_puani'].toString()) ?? 0;
          int yeniPuan = eskiPuan + 10;
          int yeniSeviye = (yeniPuan / 1000).floor() + 1;

          await SqlServis.guncelle(
            tablo: 'sohbet_iliskileri',
            veriler: {'iliski_puani': yeniPuan, 'seviye': yeniSeviye},
            sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
          );
          _currentRelationshipLevel = yeniSeviye;
        }
      }
      setState(() => _userCoins = yeniBakiye);
    }

    int alanId = int.tryParse(widget.chatData['id'].toString()) ?? 0;

    setState(() {
      _messages.add({
        "gonderen_id": _kendiId.toString(),
        "mesaj": text,
        "medya_url": mediaUrl.isEmpty ? null : mediaUrl,
        "medya_tipi": mediaType,
        "is_gift": isGift ? "1" : "0",
        "olusturulma_tarihi": DateTime.now().toString(),
      });
      if (textOverride.isEmpty) _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients)
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    });

    await SqlServis.ekle(
      tablo: 'mesajlar',
      veriler: {
        'gonderen_id': _kendiId,
        'alan_id': alanId,
        'mesaj': text,
        'medya_url': mediaUrl,
        'medya_tipi': mediaType,
        'is_gift': isGift ? 1 : 0,
        'okundu_mu': 0,
      },
    );
  }

  Future<void>  _hediyeyiVeritabaninaKaydetVeGonder(
    Map<String, dynamic> gift,
  ) async {
    int hediyeFiyati = gift['cost'] ?? 0;
    if (_userCoins < hediyeFiyati) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yetersiz Coin!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    int yeniBakiye = _userCoins - hediyeFiyati;
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': yeniBakiye},
      sartlar: {'id': _kendiId},
    );

    int alanId = int.tryParse(widget.chatData['id'].toString()) ?? 0;
    await SqlServis.ekle(
      tablo: 'hediye_gecmisi',
      veriler: {
        'gonderen_id': _kendiId,
        'gonderen_isim': _kendiIsmim,
        'alan_id': alanId,
        'alan_isim': widget.chatData['name'],
        'hediye_adi': gift['name'],
        'hediye_emoji': gift['icon'],
        'coin_miktari': hediyeFiyati,
      },
    );
  
    if (mounted) setState(() => _userCoins = yeniBakiye);
     int kazanilanXP = (hediyeFiyati / 10).ceil(); // Her 10 coin = 1 XP
    int karsiId = int.tryParse(widget.chatData['id'].toString()) ?? 0;
    int kucukId = _kendiId < karsiId ? _kendiId : karsiId;
    int buyukId = _kendiId > karsiId ? _kendiId : karsiId;

    // İlişki puanını güncelle
    final relRes = await SqlServis.cek(
      tablo: 'sohbet_iliskileri',
      sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
    );
    if (relRes.basarili && relRes.veri.isNotEmpty) {
      int eskiPuan = int.tryParse(relRes.veri.first['iliski_puani'].toString()) ?? 0;
      int yeniPuan = eskiPuan + kazanilanXP;
      int yeniSeviye = (yeniPuan / 1000).floor() + 1;
      await SqlServis.guncelle(
        tablo: 'sohbet_iliskileri',
        veriler: {'iliski_puani': yeniPuan, 'seviye': yeniSeviye},
        sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
      );
      _currentRelationshipLevel = yeniSeviye;
    } else {
      // İlişki kaydı yoksa oluştur
      await SqlServis.ekle(tablo: 'sohbet_iliskileri', veriler: {
        'kullanici1_id': kucukId, 'kullanici2_id': buyukId,
        'iliski_puani': kazanilanXP, 'seviye': 1,
      });
    }

    // Gönderenin XP'sini artır
    final xpRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': _kendiId});
    if (xpRes.basarili && xpRes.veri.isNotEmpty) {
      int mevcutXP = int.tryParse(xpRes.veri.first['xp_puani'].toString()) ?? 0;
      await SqlServis.guncelle(
        tablo: 'hesaplar',
        veriler: {'xp_puani': mevcutXP + kazanilanXP},
        sartlar: {'id': _kendiId},
      );
    }
    await _sendMessage(
      textOverride: "${gift['icon']} sana ${gift['name']} hediye etti!",
      isGift: true,
    );
  }

  void _showGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hediye Gönder",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "🪙 $_userCoins",
                    style: const TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _giftsList.length,
              itemBuilder: (_, index) {
                final gift = _giftsList[index];
                return InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _hediyeyiVeritabaninaKaydetVeGonder(gift);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          gift['icon'],
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          gift['name'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          "${gift['cost']} Coin",
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MEDYA MENÜSÜ KONTROLLERİ (SEVİYE 2)
  // ==========================================
  void _showMediaOptions() {
    // ⚠️ SEVİYE 2 KONTROLÜ
    if (_currentRelationshipLevel < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "🔒 Fotoğraf ve video göndermek için Seviye 2 olmalısınız!",
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppTheme.accent),
              title: const Text('Fotoğraf Gönder'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(
                LucideIcons.video,
                color: AppTheme.accentGold,
              ),
              title: const Text('Video Gönder'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ⚠️ SESLİ MESAJ KONTROLÜ (SEVİYE 3)
  void _handleVoiceMessage() {
    if (_currentRelationshipLevel < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 Sesli mesaj göndermek için Seviye 3 olmalısınız!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    // Burada ses kayıt kodu çalışacak
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🎙️ Ses kaydediliyor..."),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  @override
  void dispose() {
    _messageCheckTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GlowAvatar(initial: widget.chatData['name'][0], radius: 16),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatData['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      "Çevrimiçi",
                      style: TextStyle(fontSize: 9, color: AppTheme.success),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          // ⚠️ SEVİYE 4 KONTROLÜ (Sesli Arama)
          IconButton(
            icon: const Icon(
              LucideIcons.phone,
              color: AppTheme.accent,
              size: 18,
            ),
            onPressed: () {
              if (_currentRelationshipLevel < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🔒 Sesli arama yapmak için Seviye 4 olmalısınız!",
                    ),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatCallScreen(
                    chatData: widget.chatData,
                    username: _kendiIsmim,
                    isVideoCall: false,
                    currentRelationshipLevel: _currentRelationshipLevel,
                  ),
                ),
              );
            },
          ),
          // ⚠️ SEVİYE 5 KONTROLÜ (Görüntülü Arama)
          IconButton(
            icon: const Icon(
              LucideIcons.video,
              color: AppTheme.accentGold,
              size: 18,
            ),
            onPressed: () {
              if (_currentRelationshipLevel < 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "🔒 Görüntülü arama yapmak için Seviye 5 olmalısınız!",
                    ),
                    backgroundColor: AppTheme.danger,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatCallScreen(
                    chatData: widget.chatData,
                    username: _kendiIsmim,
                    isVideoCall: true,
                    currentRelationshipLevel: _currentRelationshipLevel,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.heart,
              color: AppTheme.danger,
              size: 18,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RelationshipScreen(chatData: widget.chatData),
              ),
            ),
          ),
        ],
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (_, index) {
                          final m = _messages[index];
                          final isMe =
                              m['gonderen_id'].toString() ==
                              _kendiId.toString();
                          final isGift = m['is_gift'].toString() == "1";
                          final mediaUrl = m['medya_url'];
                          final mediaType = m['medya_tipi'] ?? 'yok';

                          String saat = "Şimdi";
                          if (m['olusturulma_tarihi'] != null) {
                            try {
                              DateTime dt = DateTime.parse(
                                m['olusturulma_tarihi'],
                              );
                              saat =
                                  "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                            } catch (e) {}
                          }

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: screenWidth * 0.72,
                              ),
                              decoration: BoxDecoration(
                                color: isGift
                                    ? AppTheme.accentGold.withOpacity(0.15)
                                    : isMe
                                    ? AppTheme.accent
                                    : (context.isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.grey.withOpacity(0.08)),
                                border: (!isMe && !isGift)
                                    ? Border.all(color: context.border)
                                    : null,
                                borderRadius: BorderRadius.circular(14)
                                    .copyWith(
                                      bottomRight: isMe
                                          ? const Radius.circular(4)
                                          : null,
                                      bottomLeft: !isMe
                                          ? const Radius.circular(4)
                                          : null,
                                    ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (mediaUrl != null &&
                                      mediaUrl.toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: mediaType == 'resim'
                                            ? Image.network(
                                                mediaUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                LucideIcons.video,
                                                size: 50,
                                                color: Colors.white54,
                                              ),
                                      ),
                                    ),
                                  if (m['mesaj'] != null &&
                                      m['mesaj'].toString().isNotEmpty)
                                    Text(
                                      m['mesaj'],
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isGift
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isMe && !isGift
                                            ? Colors.white
                                            : context.textPrimary,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        saat,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isMe && !isGift
                                              ? Colors.white70
                                              : context.textSecondary,
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          m['okundu_mu'].toString() == "1"
                                              ? LucideIcons.checkCheck
                                              : LucideIcons.check,
                                          size: 10,
                                          color:
                                              m['okundu_mu'].toString() == "1"
                                              ? Colors.blueAccent
                                              : Colors.white54,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.card,
                  border: Border(
                    top: BorderSide(color: context.border.withOpacity(0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    // Medya (Level 2)
                    GestureDetector(
                      onTap: _showMediaOptions,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Hediye (Sınırsız)
                    GestureDetector(
                      onTap: _showGiftPanel,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.gift,
                          color: AppTheme.accentGold,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sesli Mesaj (Level 3)
                    GestureDetector(
                      onTap: _handleVoiceMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.mic,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mesaj Input
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Mesaj yaz...",
                          hintStyle: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: context.isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Gönder
                    GestureDetector(
                      onTap: () => _sendMessage(textOverride: ""),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.send,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
