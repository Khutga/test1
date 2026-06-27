import 'package:flutter/material.dart';
import 'package:nivi/services/level_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/app_colors.dart';
import '../../../services/sql_servis.dart';
import '../../../widgets/custom_widgets.dart';
import '../../chatScreen/chat_screen.dart';
// 🔥 Yeni widget'ı buraya import et (Yolu kendi klasörüne göre düzelt)
import 'profile_stats_and_actions.dart';

class UserProfileScreen extends StatefulWidget {
  final String hedefKullaniciAdi;
  const UserProfileScreen({super.key, required this.hedefKullaniciAdi});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _targetUser;
  bool _isLoading = true;
  bool _isFollowing = false;

  int _kendiId = 1;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _kendiId = prefs.getInt('kullanici_id') ?? 1;

      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: {'kullanici_adi': widget.hedefKullaniciAdi.trim()},
      );

      if (res.basarili && res.veri.isNotEmpty) {
        _targetUser = res.veri.first;
        print("Hedef kullanıcı bulundu: $_targetUser");
        int targetId = int.parse(_targetUser!['id'].toString());

        // Takipçi Sayısını Çek
        final followerRes = await SqlServis.cek(
          tablo: 'takipciler',
          sartlar: {'takip_edilen_id': targetId},
        );
        print("Takipçi verisi: ${followerRes.veri}");

        if (followerRes.basarili) {
          _followerCount = followerRes.veri.length;
          _isFollowing = followerRes.veri.any(
            (element) =>
                element['takip_eden_id'].toString() == _kendiId.toString(),
          );
        }

        // Takip Ettiklerinin Sayısını Çek
        final followingRes = await SqlServis.cek(
          tablo: 'takipciler',
          sartlar: {'takip_eden_id': targetId},
        );

        if (followingRes.basarili) {
          _followingCount = followingRes.veri.length;
        }
      }
    } catch (e) {
      print("Hata oluştu: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_targetUser == null) return;
    int targetId = int.parse(_targetUser!['id'].toString());

    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });

    if (_isFollowing) {
      await SqlServis.ekle(
        tablo: 'takipciler',
        veriler: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetId},
      );
    } else {
      await SqlServis.sil(
        tablo: 'takipciler',
        sartlar: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetId},
      );
    }
  }

  void _sendMessage({bool gizliMi = false}) {
    if (_targetUser == null) return;

    Map<String, dynamic> fakeChatData = {
      "id": int.parse(_targetUser!['id'].toString()),
      "name": _targetUser!['isim'],
      "msg": "",
      "time": "Şimdi",
      "unread": 0,
      "gizli_mi": gizliMi,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatData: fakeChatData, gizliMod: gizliMi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_targetUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profil Bulunamadı")),
        body: const Center(
          child: Text(
            "Kullanıcı bulunamadı.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    String isim = _targetUser!['isim'] ?? 'Bilinmiyor';
    String bio =
        _targetUser!['biyografi'] ??
        'Bu kullanıcı henüz bir biyografi eklemedi.';

    int xp = int.tryParse(_targetUser!['xp_puani']?.toString() ?? '0') ?? 0;
    int targetLevel = LevelManager.getLevel(xp);
    double xpProgress = LevelManager.getProgress(xp);
    Color frameColor = LevelManager.getFrameColor(targetLevel);

    int targetId = int.parse(_targetUser!['id'].toString());
    bool kendiProfili = _kendiId.toString() == targetId.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isim,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. VIP ÇERÇEVELİ PROFİL RESMİ
                Container(
                  padding: EdgeInsets.all(
                    frameColor == Colors.transparent ? 0 : 5,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: frameColor == Colors.transparent
                          ? Colors.transparent
                          : frameColor,
                      width: frameColor == Colors.transparent ? 0 : 3.5,
                    ),
                    boxShadow: frameColor != Colors.transparent
                        ? [
                            BoxShadow(
                              color: frameColor.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : [],
                  ),
                  child: GlowAvatar(
                    initial: isim[0].toUpperCase(),
                    radius: 44,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 16),

                // 2. İSİM VE LEVEL ROZETİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isim,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: frameColor == Colors.transparent
                            ? AppTheme.accent
                            : frameColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (frameColor == Colors.transparent
                                        ? AppTheme.accent
                                        : frameColor)
                                    .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Lv. $targetLevel",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "@${_targetUser!['kullanici_adi']}",
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // 3. PROGRESS BAR
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lv. $targetLevel",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Lv. ${targetLevel + 1}",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            frameColor == Colors.transparent
                                ? AppTheme.accent
                                : frameColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$xp / ${LevelManager.getNextLevelXp(xp)} XP",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. BİYOGRAFİ
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // 🔥 5. AYRILMIŞ TAKİP DETAYLARI VE AKSİYON BUTONLARI
                ProfileStatsAndActions(
                  targetUserId:
                      targetId, // 🔥 Hedef kişinin ID'sini artık gönderiyoruz
                  followerCount: _followerCount,
                  followingCount: _followingCount,
                  isFollowing: _isFollowing,
                  kendiProfili: kendiProfili,
                  onToggleFollow: _toggleFollow,
                  onSendMessage: () => _sendMessage(gizliMi: false),
                  onSendAnonymous: () => _sendMessage(gizliMi: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
