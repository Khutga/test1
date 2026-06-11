import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';
import 'user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String initialTab;
  const FollowListScreen({super.key, required this.initialTab});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late String _activeTab;
  List<Map<String, dynamic>> _userList = [];
  Set<int> _benTakipEdiyorum = {}; // Benim takip ettiğim ID'ler
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

    // Benim takip ettiğim herkesi çek (buton durumu için)
    final benTakipRes = await SqlServis.cek(tablo: 'takipciler', sartlar: {'takip_eden_id': _kendiId});
    if (benTakipRes.basarili) {
      _benTakipEdiyorum = benTakipRes.veri.map((e) => int.parse(e['takip_edilen_id'].toString())).toSet();
    }

    // Sekmeye göre listeyi çek
    String aranacakSutun = _activeTab == 'followers' ? 'takip_edilen_id' : 'takip_eden_id';
    String hedefSutun = _activeTab == 'followers' ? 'takip_eden_id' : 'takip_edilen_id';

    final relRes = await SqlServis.cek(tablo: 'takipciler', sartlar: {aranacakSutun: _kendiId});

    if (relRes.basarili && relRes.veri.isNotEmpty) {
      List<int> hedefIdler = relRes.veri.map((e) => int.parse(e[hedefSutun].toString())).toList();

      List<Map<String, dynamic>> detayliListe = [];
      for (int id in hedefIdler) {
        var userRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': id});
        if (userRes.basarili && userRes.veri.isNotEmpty) {
          detayliListe.add(userRes.veri.first);
        }
      }
      setState(() { _userList = detayliListe; _isLoading = false; });
    } else {
      setState(() { _userList = []; _isLoading = false; });
    }
  }

  Future<void> _toggleFollow(int targetUserId, bool simdiTakipEdiyorMuyum) async {
    if (simdiTakipEdiyorMuyum) {
      await SqlServis.sil(tablo: 'takipciler', sartlar: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetUserId});
    } else {
      await SqlServis.ekle(tablo: 'takipciler', veriler: {'takip_eden_id': _kendiId, 'takip_edilen_id': targetUserId});
    }
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Takip Sistemi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary))),
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
                            final String kullaniciAdi = user['kullanici_adi'] ?? '';
                            final int userId = int.parse(user['id'].toString());

                            // Gerçek takip durumu: BEN bu kişiyi takip ediyor muyum?
                            bool benTakipEdiyorum = _benTakipEdiyorum.contains(userId);

                            // Kendimi listede gösterme (takipçiler sekmesinde kendim çıkabilir)
                            if (userId == _kendiId) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar — tıklayınca profil
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => UserProfileScreen(hedefKullaniciAdi: isim),
                                      )),
                                      child: GlowAvatar(initial: isim[0].toUpperCase(), radius: 24, color: AppTheme.accent),
                                    ),
                                    const SizedBox(width: 12),

                                    // İsim + Kullanıcı adı — tıklayınca profil
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => UserProfileScreen(hedefKullaniciAdi: isim),
                                        )),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isim, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                            if (kullaniciAdi.isNotEmpty)
                                              Text("@$kullaniciAdi", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Takip butonu
                                    GestureDetector(
                                      onTap: () => _toggleFollow(userId, benTakipEdiyorum),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: benTakipEdiyorum ? Colors.transparent : AppTheme.accent,
                                          border: benTakipEdiyorum ? Border.all(color: context.textSecondary) : null,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          benTakipEdiyorum ? "Takipte" : "Takip Et",
                                          style: TextStyle(color: benTakipEdiyorum ? context.textSecondary : Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
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
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isActive ? AppTheme.accent : context.textSecondary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}