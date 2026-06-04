import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart'; // GlowAvatar vb. için
import '../chatScreen/chat_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    _kendiId = prefs.getInt('kullanici_id') ?? 1;

    // Hedef Kullanıcıyı Çek
    final res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'isim': widget.hedefKullaniciAdi});
    
    if (res.basarili && res.veri.isNotEmpty) {
      _targetUser = res.veri.first;
      int targetId = int.parse(_targetUser!['id'].toString());

      // Takipçi Sayısını Çek
      final followerRes = await SqlServis.cek(tablo: 'takipciler', sartlar: {'takip_edilen_id': targetId});
      if (followerRes.basarili) {
        _followerCount = followerRes.veri.length;
        // Ben takip ediyor muyum kontrolü
        _isFollowing = followerRes.veri.any((element) => element['takip_eden_id'].toString() == _kendiId.toString());
      }

      // Takip Ettiklerinin Sayısını Çek
      final followingRes = await SqlServis.cek(tablo: 'takipciler', sartlar: {'takip_eden_id': targetId});
      if (followingRes.basarili) {
        _followingCount = followingRes.veri.length;
      }
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _toggleFollow() async {
    if (_targetUser == null) return;
    int targetId = int.parse(_targetUser!['id'].toString());
    
    setState(() {
      _isFollowing = !_isFollowing;
      _followerCount += _isFollowing ? 1 : -1;
    });

    if (_isFollowing) {
      await SqlServis.ekle(tablo: 'takipciler', veriler: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetId});
    } else {
      await SqlServis.sil(tablo: 'takipciler', sartlar: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetId});
    }
  }

  void _sendMessage() {
    if (_targetUser == null) return;
    
    Map<String, dynamic> fakeChatData = {
      "id": int.parse(_targetUser!['id'].toString()),
      "name": _targetUser!['isim'],
      "msg": "",
      "time": "Şimdi",
      "unread": 0
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatData: fakeChatData)));
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary)),
      ],
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
        body: const Center(child: Text("Kullanıcı bulunamadı.", style: TextStyle(color: Colors.white))),
      );
    }

    String isim = _targetUser!['isim'] ?? 'Bilinmiyor';
    String bio = _targetUser!['biyografi'] ?? 'Bu kullanıcı henüz bir biyografi eklemedi.';
    int xp = int.tryParse(_targetUser!['xp_puani']?.toString() ?? '0') ?? 0;
    int seviye = (xp / 100).floor() + 1;

    // Kendine tıklamışsa butonları gizle
    bool kendiProfili = _kendiId.toString() == _targetUser!['id'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(isim, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
        centerTitle: true,
      ),
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GlowAvatar(initial: isim[0].toUpperCase(), radius: 44, color: AppTheme.accent),
                const SizedBox(height: 16),
                Text(isim, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.textPrimary)),
                const SizedBox(height: 4),
                Text("@${_targetUser!['kullanici_adi']}", style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w700)),
                
                const SizedBox(height: 24),
                
                // İSTATİSTİKLER (Takipçi, Takip Edilen, Seviye)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(context, _followerCount.toString(), "Takipçi"),
                    Container(width: 1, height: 28, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 20)),
                    _buildStatItem(context, _followingCount.toString(), "Takip Edilen"),
                    Container(width: 1, height: 28, color: context.border, margin: const EdgeInsets.symmetric(horizontal: 20)),
                    _buildStatItem(context, "Lv.$seviye", "Seviye"),
                  ],
                ),
                
                const SizedBox(height: 24),
                Text(bio, textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4)),
                const SizedBox(height: 32),

                // AKSİYON BUTONLARI (Kendi profili değilse göster)
                if (!kendiProfili)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(_isFollowing ? LucideIcons.userCheck : LucideIcons.userPlus, color: Colors.white, size: 18),
                          label: Text(_isFollowing ? "Takipte" : "Takip Et", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _isFollowing ? Colors.grey[700] : AppTheme.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 18),
                          label: const Text("Mesaj At", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}