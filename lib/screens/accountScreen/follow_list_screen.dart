import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class FollowListScreen extends StatefulWidget {
  final String initialTab; // 'followers' veya 'following'

  const FollowListScreen({super.key, required this.initialTab});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late String _activeTab;
  List<Map<String, dynamic>> _userList = [];
  bool _isLoading = true;
  int _kendiId = 1;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _kendiId = prefs.getInt('kullanici_id') ?? 1;

    // 1. Önce Takip Tablosundan ID'leri çek
    String aranacakSutun = _activeTab == 'followers' ? 'takip_edilen_id' : 'takip_eden_id';
    String hedefSutun = _activeTab == 'followers' ? 'takip_eden_id' : 'takip_edilen_id';
    
    final relRes = await SqlServis.cek(tablo: 'takipciler', sartlar: {aranacakSutun: _kendiId});
    
    if (relRes.basarili && relRes.veri.isNotEmpty) {
      List<int> hedefIdler = relRes.veri.map((e) => int.parse(e[hedefSutun].toString())).toList();
      
      // 2. Bu ID'lere sahip kullanıcıların hesap bilgilerini çek
      // Normalde SQL'de IN operatörü veya JOIN kullanılır. SqlServis'i yormamak için basit döngü:
      List<Map<String, dynamic>> detayliListe = [];
      for (int id in hedefIdler) {
        var userRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': id});
        if (userRes.basarili && userRes.veri.isNotEmpty) {
          detayliListe.add(userRes.veri.first);
        }
      }
      
      setState(() {
        _userList = detayliListe;
        _isLoading = false;
      });
    } else {
      setState(() {
        _userList = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(int targetUserId, bool isCurrentlyFollowing) async {
    if (isCurrentlyFollowing) {
      // Takipten Çık (Veritabanından sil - SqlServis'te sil metodu olduğunu varsayarak)
      await SqlServis.sil(tablo: 'takipciler', sartlar: {
        'takip_eden_id': _kendiId,
        'takip_edilen_id': targetUserId
      });
    } else {
      // Takip Et
      await SqlServis.ekle(tablo: 'takipciler', veriler: {
        'takip_eden_id': _kendiId,
        'takip_edilen_id': targetUserId
      });
    }
    
    // Listeyi yenile
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Takip Sistemi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      body: MainBackground(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTabBtn('followers', "Takipçiler", () { setState(() => _activeTab = 'followers'); _loadUsers(); })),
                Expanded(child: _buildTabBtn('following', "Takip Edilenler", () { setState(() => _activeTab = 'following'); _loadUsers(); })),
              ],
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _userList.isEmpty 
                  ? Center(child: Text("Liste boş.", style: TextStyle(color: context.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _userList.length,
                      itemBuilder: (context, index) {
                        final user = _userList[index];
                        final String isim = user['isim'] ?? 'Bilinmeyen';
                        final int userId = int.parse(user['id'].toString());
                        
                        // Takip edilenler sekmesindeysek buton "Takipten Çık" olacak
                        bool isFollowing = _activeTab == 'following';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GlowAvatar(initial: isim[0].toUpperCase(), radius: 24, color: AppTheme.accent),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(isim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleFollow(userId, isFollowing),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isFollowing ? Colors.transparent : AppTheme.accent,
                                      border: isFollowing ? Border.all(color: context.textSecondary) : null,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(isFollowing ? "Takipten Çık" : "Geri Takip Et", 
                                      style: TextStyle(color: isFollowing ? context.textSecondary : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String id, String label, VoidCallback onTap) {
    bool isActive = _activeTab == id;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? AppTheme.accent : Colors.transparent, width: 2)),
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isActive ? AppTheme.accent : Colors.white54, fontWeight: FontWeight.bold)),
      ),
    );
  }
}