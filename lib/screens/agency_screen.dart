import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/services/sql_servis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';
import 'accountScreen/user_profile_screen.dart'; // Profil yönlendirmesi için eklendi

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  // Sekme ve Liste Değişkenleri
  String _activeTab = 'dashboard';
  double _simulatedAgencyCoins = 12000000;
  List<Map<String, dynamic>> _agencyMembers = [];
  
  // Durum ve Hesap Değişkenleri
  bool _isLoading = true;
  int _userId = 1;
  int _userCoins = 0;
  bool _hasAgency = false;
  Map<String, dynamic>? _agencyData;

  // Form ve Arama Controller'ları
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _agencyLogoController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkAgencyStatus();
  }

  /// Kullanıcının ajans sahipliğini ve bakiye durumunu kontrol eden fonksiyon
  Future<void> _checkAgencyStatus() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;

    // 1. Kullanıcı hesap bilgilerini çek
    final userRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': _userId},
    );

    if (userRes.basarili && userRes.veri.isNotEmpty) {
      final userRow = userRes.veri.first;
      _userCoins = (double.tryParse(userRow['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
      
      int ajansVarMi = int.tryParse(userRow['ajansvarmi']?.toString() ?? '0') ?? 0;
      _hasAgency = (ajansVarMi == 1);
    }

    // 2. Eğer ajans kurulmuşsa ajanslar tablosundaki detayları ve üyeleri çek
    if (_hasAgency) {
      final agencyRes = await SqlServis.cek(
        tablo: 'ajanslar',
        sartlar: {'ajans_sahibi_id': _userId},
      );
      if (agencyRes.basarili && agencyRes.veri.isNotEmpty) {
        _agencyData = agencyRes.veri.first;
      }
      await _loadMembers();
    }

    setState(() => _isLoading = false);
  }

  /// Ajansa kayıtlı mevcut üyeleri getiren fonksiyon
  Future<void> _loadMembers() async {
    final res = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'ajans_sahibi_id': _userId},
    );
    if (res.basarili) {
      setState(() {
        _agencyMembers = res.veri;
      });
    }
  }

  /// 10000 Coin karşılığında yeni ajans oluşturan fonksiyon
  Future<void> _createAgency() async {
    final name = _agencyNameController.text.trim();
    final logo = _agencyLogoController.text.trim().isEmpty 
        ? "https://via.placeholder.com/150" 
        : _agencyLogoController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen geçerli bir ajans ismi girin!"), backgroundColor: AppTheme.danger)
      );
      return;
    }

    if (_userCoins < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yetersiz bakiye! Ajans açmak için 10,000 Coin gereklidir."), backgroundColor: AppTheme.danger)
      );
      return;
    }

    setState(() => _isLoading = true);

    int yeniBakiye = _userCoins - 10000;
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': yeniBakiye, 'ajansvarmi': 1},
      sartlar: {'id': _userId}
    );

    await SqlServis.ekle(
      tablo: 'ajanslar',
      veriler: {
        'ajans_ismi': name,
        'ajans_sahibi_id': _userId,
        'ajans_logo': logo,
        'olusturulma_tarihi': DateTime.now().toString().substring(0, 10)
      }
    );

    _agencyNameController.clear();
    _agencyLogoController.clear();

    await _checkAgencyStatus();
  }

  /// Hesaplar tablosunda isim veya kullanıcı adına göre arama yapan fonksiyon
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);

    var res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'isim': query.trim()});
    
    if (!res.basarili || res.veri.isEmpty) {
      res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'kullanici_adi': query.trim()});
    }

    setState(() {
      _searchResults = res.basarili ? res.veri : [];
      _isSearching = false;
    });
  }

  /// Seçilen hesabı ajans üyelerine dahil eden fonksiyon
  Future<void> _addMember(Map<String, dynamic> user) async {
    final String targetName = user['isim'] ?? user['kullanici_adi'] ?? 'Bilinmeyen';
    final int targetUserId = int.tryParse(user['id'].toString()) ?? 0;

    bool zatenUye = _agencyMembers.any((m) => m['isim'] == targetName);
    if (zatenUye) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu kullanıcı zaten ajansınızın üyesi!"), backgroundColor: AppTheme.warning)
      );
      return;
    }

    setState(() => _isLoading = true);
    final randomCode = "LV-${100 + Random().nextInt(900)}${Random().nextInt(10)}";

    // ajans_uyeleri tablosuna 'uye_id' ile birlikte ekleme yapılıyor
    await SqlServis.ekle(
      tablo: 'ajans_uyeleri',
      veriler: {
        'ajans_sahibi_id': _userId,
        'uye_id': targetUserId, // YENİ ALAN VERİ TABANINA GÖNDERİLİYOR
        'isim': targetName,
        'id_kodu': randomCode,
        'durum': 'Aktif',
        'katilim_tarihi': DateTime.now().toString().substring(0, 10)
      }
    );

    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'ajansvarmi': 1},
      sartlar: {'id': targetUserId}
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$targetName ajansınıza başarıyla eklendi!"), backgroundColor: AppTheme.success)
    );

    _memberSearchController.clear();
    _searchResults = [];
    await _loadMembers();
    setState(() => _isLoading = false);
  }

  Map<String, dynamic> _getCommissionRate(double coins) {
    if (coins >= 30000000) return {"level": 4, "rate": 74, "nextQuota": null};
    if (coins >= 20000000) return {"level": 3, "rate": 68, "nextQuota": 30000000.0};
    if (coins >= 10000000) return {"level": 2, "rate": 63, "nextQuota": 20000000.0};
    if (coins >= 3000000) return {"level": 1, "rate": 59, "nextQuota": 10000000.0};
    return {"level": 0, "rate": 50, "nextQuota": 3000000.0};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
    }

    if (!_hasAgency) {
      return _buildCreateAgencyUi();
    }

    final quotaInfo = _getCommissionRate(_simulatedAgencyCoins);
    final String currentAgencyName = _agencyData?['ajans_ismi'] ?? "Ajans Paneli";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentAgencyName,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary),
            ),
            Text("Yönetim v2.6", style: TextStyle(fontSize: 9, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.border))),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTabBtn("İstatistik", "dashboard"),
                      _buildTabBtn("Üye Yönetimi", "members"),
                      _buildTabBtn("Ödeme & Çekim", "payout"),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _activeTab == 'dashboard'
                      ? _buildDashboard(quotaInfo)
                      : _activeTab == 'members'
                          ? _buildMembersList()
                          : Center(child: Text("Ödeme sistemi yakında aktif edilecektir.", style: TextStyle(color: context.textSecondary))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAgencyUi() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajans Kurulumu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.building, size: 48, color: AppTheme.accentGold),
                      const SizedBox(height: 12),
                      Text(
                        "Kendi Ajansınızı Kurun",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ajansınızı kurarak platformdaki yayıncıları ekibinize dahil edebilir, canlı yayın cirolarından yüksek komisyonlar kazanmaya başlayabilirsiniz.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mevcut Coin Bakiyeniz:", style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    Text("🪙 $_userCoins Coin", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: "Ajans İsmi",
                  hint: "Örn: Alfa Elite Ajans",
                  controller: _agencyNameController,
                  icon: LucideIcons.briefcase,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: "Ajans Logo URL (İsteğe Bağlı)",
                  hint: "https://site.com/logo.jpg",
                  controller: _agencyLogoController,
                  icon: LucideIcons.image,
                ),
                const SizedBox(height: 28),
                PremiumButton(
                  text: "Ajans Kur (10,000 Coin)",
                  icon: LucideIcons.plusCircle,
                  onPressed: _createAgency,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, String id) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent
              : (context.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> quotaInfo) {
    final logoUrl = _agencyData?['ajans_logo'] ?? "";
    return Column(
      children: [
        if (logoUrl.isNotEmpty && logoUrl.startsWith("http"))
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.network(logoUrl, width: 80, height: 80, fit: BoxFit.cover, 
                  errorBuilder: (c, e, s) => const CircleAvatar(radius: 40, backgroundColor: AppTheme.accent, child: Icon(LucideIcons.building, color: Colors.white)),
                ),
              ),
            ),
          ),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Komisyon Seviyesi", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.normal, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(8)),
                    child: Text("LEVEL ${quotaInfo['level']}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _simulatedAgencyCoins.toInt().toString(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accentGold),
                  ),
                  Text("%${quotaInfo['rate']} Pay", style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              Text("Kota Simülatörü", style: TextStyle(fontSize: 12, color: context.textSecondary)),
              Slider(
                value: _simulatedAgencyCoins,
                min: 100000,
                max: 40000000,
                activeColor: AppTheme.accent,
                inactiveColor: context.border,
                onChanged: (val) => setState(() => _simulatedAgencyCoins = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Yeni Yayıncı Davet Et", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _memberSearchController,
                style: TextStyle(fontSize: 13, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: "Tam isim veya kullanıcı adı yazın...",
                  hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _searchUsers(_memberSearchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text("Ara", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isSearching)
          const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: AppTheme.accent)))
        else if (_searchResults.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Column(
              children: _searchResults.map((user) {
                final name = user['isim'] ?? user['kullanici_adi'] ?? 'Bilinmeyen';
                final username = user['kullanici_adi'] ?? '';
                return ListTile(
                  leading: GlowAvatar(initial: name[0].toUpperCase(), radius: 18),
                  title: Text(name, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("@$username", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                  trailing: ElevatedButton(
                    onPressed: () => _addMember(user),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: const Text("Ajansa Ekle", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 24),
        Text("Ajans Bünyesindeki Üyeler (${_agencyMembers.length})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
        const SizedBox(height: 10),

        if (_agencyMembers.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text("Ajansınızda henüz kayıtlı yayıncı bulunmuyor.", style: TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          )
        else
          ..._agencyMembers.map((member) {
            String isim = member['isim'] ?? 'Bilinmeyen';
            String idCode = member['id_kodu'] ?? '---';
            String status = member['durum'] ?? 'Pasif';

            // Kartın tıklanabilir olması ve UserProfileScreen'e yönlendirmesi sağlandı
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(
                        hedefKullaniciAdi: isim,
                      ),
                    ),
                  );
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      GlowAvatar(initial: isim.isNotEmpty ? isim[0].toUpperCase() : '?', radius: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isim, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary)),
                            Text(idCode, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (status == 'Aktif' ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: status == 'Aktif' ? AppTheme.success : AppTheme.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _agencyLogoController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }
}