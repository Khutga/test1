import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';
import 'accountScreen/user_profile_screen.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  String _activeTab = 'overview';
  
  bool _isLoading = true;
  int _userId = 1;
  int _userCoins = 0;
  bool _hasAgency = false;
  bool _isAgencyOwner = false;
  
  Map<String, dynamic>? _agencyData;
  String _leaderName = "Bilinmiyor";
  String _myUserName = "Bilinmiyor";
  int _agencyTotalCoins = 0;
  String _inviteCode = "";
  
  int _myMonthlyIncome = 0;
  
  List<Map<String, dynamic>> _enrichedMembers = [];

  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _agencyLogoController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  bool _showJoinForm = false; 

  @override
  void initState() {
    super.initState();
    _checkAgencyStatus();
  }

  Future<void> _checkAgencyStatus() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;

    final userRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': _userId});
    if (userRes.basarili && userRes.veri.isNotEmpty) {
      final userRow = userRes.veri.first;
      _userCoins = (double.tryParse(userRow['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
      _hasAgency = (int.tryParse(userRow['ajansvarmi']?.toString() ?? '0') == 1);
      _myUserName = userRow['isim'] ?? userRow['kullanici_adi'] ?? "Bilinmiyor";
    }

    if (_hasAgency) {
      final ownerRes = await SqlServis.cek(tablo: 'ajanslar', sartlar: {'ajans_sahibi_id': _userId});
      
      if (ownerRes.basarili && ownerRes.veri.isNotEmpty) {
        _isAgencyOwner = true;
        _agencyData = ownerRes.veri.first;
        _inviteCode = _agencyData?['davet_kodu'] ?? "";
        _leaderName = _myUserName;

        if (_inviteCode.isEmpty) {
          _inviteCode = "AJ-${Random().nextInt(90000) + 10000}";
          await SqlServis.guncelle(
            tablo: 'ajanslar', 
            veriler: {'davet_kodu': _inviteCode}, 
            sartlar: {'id': _agencyData!['id']}
          );
        }
        await _loadMembersAndStats();
      } else {
        final memberRes = await SqlServis.cek(tablo: 'ajans_uyeleri', sartlar: {'uye_id': _userId});
        if (memberRes.basarili && memberRes.veri.isNotEmpty) {
          _isAgencyOwner = false;
          int ownerId = int.tryParse(memberRes.veri.first['ajans_sahibi_id'].toString()) ?? 0;
          
          final agencyRes = await SqlServis.cek(tablo: 'ajanslar', sartlar: {'ajans_sahibi_id': ownerId});
          if (agencyRes.basarili && agencyRes.veri.isNotEmpty) {
            _agencyData = agencyRes.veri.first;
          }
          
          final leaderRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': ownerId});
          if (leaderRes.basarili && leaderRes.veri.isNotEmpty) {
            _leaderName = leaderRes.veri.first['isim'] ?? leaderRes.veri.first['kullanici_adi'] ?? "Bilinmiyor";
          }
          
          await _calculateMyIncome();
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _calculateMyIncome() async {
    int income = 0;
    DateTime now = DateTime.now();
    final gRes = await SqlServis.cek(tablo: 'hediye_gecmisi', sartlar: {'alan_id': _userId});
    
    if (gRes.basarili) {
      for (var g in gRes.veri) {
        if (g['tarih'] != null) {
          try {
            DateTime dt = DateTime.parse(g['tarih']);
            if (dt.year == now.year && dt.month == now.month) {
              income += (int.tryParse(g['coin_miktari'].toString()) ?? 0);
            }
          } catch (e) {}
        }
      }
    }
    _myMonthlyIncome = income;
  }

  Future<void> _loadMembersAndStats() async {
    final res = await SqlServis.cek(tablo: 'ajans_uyeleri', sartlar: {'ajans_sahibi_id': _userId});
    
    if (res.basarili) {
      List<Map<String, dynamic>> tempEnriched = [];
      int totalCoins = 0; 
      DateTime now = DateTime.now();

      for (var member in res.veri) {
        int mId = int.tryParse(member['uye_id'].toString()) ?? 0;
        int mCoin = 0;
        int monthlyIncome = 0;

        final hRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': mId});
        if (hRes.basarili && hRes.veri.isNotEmpty) {
          mCoin = (double.tryParse(hRes.veri.first['birinci_coin_bakiye'].toString()) ?? 0.0).toInt();
        }

        final gRes = await SqlServis.cek(tablo: 'hediye_gecmisi', sartlar: {'alan_id': mId});
        if (gRes.basarili) {
          for (var g in gRes.veri) {
            if (g['tarih'] != null) {
              try {
                DateTime dt = DateTime.parse(g['tarih']);
                if (dt.year == now.year && dt.month == now.month) {
                  monthlyIncome += (int.tryParse(g['coin_miktari'].toString()) ?? 0);
                }
              } catch (e) {}
            }
          }
        }

        totalCoins += mCoin; 
        tempEnriched.add({
          ...member,
          'mevcut_coin': mCoin,
          'aylik_gelir': monthlyIncome,
        });
      }

      _agencyTotalCoins = totalCoins;
      _enrichedMembers = tempEnriched;
    }
  }

  Future<void> _createAgency() async {
    final name = _agencyNameController.text.trim();
    if (name.isEmpty) return;
    if (_userCoins < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz bakiye!"), backgroundColor: AppTheme.danger));
      return;
    }

    setState(() => _isLoading = true);
    final yeniDavetKodu = "AJ-${Random().nextInt(90000) + 10000}";

    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': _userCoins - 10000, 'ajansvarmi': 1},
      sartlar: {'id': _userId}
    );

    await SqlServis.ekle(
      tablo: 'ajanslar',
      veriler: {
        'ajans_ismi': name,
        'ajans_sahibi_id': _userId,
        'ajans_logo': _agencyLogoController.text.trim().isEmpty ? "https://via.placeholder.com/150" : _agencyLogoController.text.trim(),
        'davet_kodu': yeniDavetKodu,
        'olusturulma_tarihi': DateTime.now().toString().substring(0, 10)
      }
    );

    await _checkAgencyStatus();
  }

  Future<void> _joinAgency() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    final res = await SqlServis.cek(tablo: 'ajanslar', sartlar: {'davet_kodu': code});
    if (res.basarili && res.veri.isNotEmpty) {
      final agency = res.veri.first;
      int ownerId = int.tryParse(agency['ajans_sahibi_id'].toString()) ?? 0;
      final randomCode = "LV-${100 + Random().nextInt(900)}${Random().nextInt(10)}";

      await SqlServis.ekle(
        tablo: 'ajans_uyeleri',
        veriler: {
          'ajans_sahibi_id': ownerId,
          'uye_id': _userId,
          'isim': _myUserName,
          'id_kodu': randomCode,
          'durum': 'Aktif',
          'katilim_tarihi': DateTime.now().toString().substring(0, 10)
        }
      );

      await SqlServis.guncelle(
        tablo: 'hesaplar',
        veriler: {'ajansvarmi': 1},
        sartlar: {'id': _userId}
      );

      await _checkAgencyStatus();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Geçersiz davet kodu!"), backgroundColor: AppTheme.danger));
    }
  }

  // 🔥 YENİ: Ajans Liderinin Bir Üyeyi Ajanstan Çıkarması
  Future<void> _removeMember(int memberId, String memberName) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text("Üyeyi Çıkar", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text("$memberName adlı yayıncıyı ajansınızdan çıkarmak istediğinize emin misiniz?", style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Çıkar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    // 1. ajans_uyeleri tablosundan sil
    await SqlServis.sil(tablo: 'ajans_uyeleri', sartlar: {'uye_id': memberId});

    // 2. kullanıcının kendi hesap tablosunda ajans durumunu 0 yap
    await SqlServis.guncelle(tablo: 'hesaplar', veriler: {'ajansvarmi': 0}, sartlar: {'id': memberId});

    // 3. Listeyi yeniden yükle
    await _loadMembersAndStats();
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$memberName ajanstan çıkarıldı."), backgroundColor: AppTheme.success));
    }
  }

  // 🔥 YENİ: Üyenin Kendi İsteğiyle Ajanstan Ayrılması
  Future<void> _leaveAgency() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text("Ajanstan Ayrıl", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text("Mevcut ajansınızdan ayrılmak istediğinize emin misiniz? Bu işlem geri alınamaz.", style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Ayrıl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    // 1. ajans_uyeleri tablosundan kendi kaydımı sil
    await SqlServis.sil(tablo: 'ajans_uyeleri', sartlar: {'uye_id': _userId});

    // 2. kendi hesabımı güncelle
    await SqlServis.guncelle(tablo: 'hesaplar', veriler: {'ajansvarmi': 0}, sartlar: {'id': _userId});

    // 3. Ekranı sıfırla ve durumu baştan kontrol et (Kur/Katıl ekranına düşecek)
    await _checkAgencyStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
    
    if (!_hasAgency) return _buildSetupAgencyUi();

    final String agencyName = _agencyData?['ajans_ismi'] ?? "Ajansım";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agencyName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.textPrimary)),
            Text(_isAgencyOwner ? "Ajans Yönetimi" : "Üye Paneli", style: TextStyle(fontSize: 10, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_isAgencyOwner)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.border))),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildTabBtn("Özet", "overview"),
                        _buildTabBtn("Üyeler", "members"),
                        _buildTabBtn("Davet", "invite"),
                        _buildTabBtn("Çekim Yöntemi", "payout"),
                      ],
                    ),
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _isAgencyOwner ? _buildOwnerTabContent() : _buildMemberOverviewTab(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerTabContent() {
    switch (_activeTab) {
      case 'overview': return _buildOverviewTab();
      case 'members': return _buildMembersTab();
      case 'invite': return _buildInviteTab();
      case 'payout': return _buildPayoutTab();
      default: return const SizedBox();
    }
  }

  Widget _buildMemberOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppTheme.accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kayıtlı Olduğun Ajans", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                        Text(_agencyData?['ajans_ismi'] ?? "-", style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 30, color: context.border),
              _buildInfoRow("Ajans Lideri:", _leaderName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Senin Bu Ayki Katkın", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    "🪙 $_myMonthlyIncome",
                    style: const TextStyle(color: AppTheme.accentGold, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const Icon(LucideIcons.trendingUp, color: AppTheme.success, size: 40),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // 🔥 YENİ: Üye için Ajanstan Ayrılma Butonu
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _leaveAgency,
            icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
            label: const Text("Ajanstan Ayrıl", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: AppTheme.accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ajans Bilgileri", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                        Text(_agencyData?['ajans_ismi'] ?? "-", style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 30, color: context.border),
              _buildInfoRow("Ajans ID:", "#${_agencyData?['id'] ?? '-'}"),
              const SizedBox(height: 10),
              _buildInfoRow("Ajans Lideri:", _leaderName),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ajans Toplam Hacmi", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    "🪙 $_agencyTotalCoins",
                    style: const TextStyle(color: AppTheme.accentGold, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const Icon(LucideIcons.coins, color: AppTheme.accentGold, size: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 13)),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_enrichedMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text("Ajansınızda henüz üye bulunmuyor.", style: TextStyle(color: context.textSecondary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _enrichedMembers.map((member) {
        String isim = member['isim'] ?? 'Bilinmeyen';
        int targetUserId = int.tryParse(member['uye_id']?.toString() ?? '0') ?? 0;
        String memberIdCode = member['id_kodu']?.toString() ?? '-';
        int mevcutCoin = member['mevcut_coin'] ?? 0;
        int aylikGelir = member['aylik_gelir'] ?? 0;

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(hedefKullaniciAdi: isim)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  GlowAvatar(initial: isim.isNotEmpty ? isim[0].toUpperCase() : '?', radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isim, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
                        Text("ID: $memberIdCode", style: TextStyle(fontSize: 11, color: context.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Mevcut: $mevcutCoin 🪙", style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Bu Ay: +$aylikGelir", style: const TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  // 🔥 YENİ: Ajans Lideri İçin Çıkarma Butonu
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(LucideIcons.userMinus, color: AppTheme.danger, size: 22),
                    onPressed: () => _removeMember(targetUserId, isim),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInviteTab() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(LucideIcons.userPlus, size: 50, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text("Yayıncıları Davet Et", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            "Aşağıdaki ajans kodunu yayıncılarla paylaşarak onları ajansına dahil edebilirsin.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_inviteCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.banknote, size: 60, color: context.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("Çekim Sistemi Yapılandırılıyor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            "IBAN ve Kripto ile ödeme alma seçenekleri çok yakında aktif edilecektir.",
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String label, String id) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isActive ? Colors.white : context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSetupAgencyUi() {
    return Scaffold(
      appBar: AppBar(title: const Text("Ajans İşlemleri")),
      body: MainBackground(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showJoinForm = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_showJoinForm ? AppTheme.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text("Ajans Kur", style: TextStyle(color: !_showJoinForm ? Colors.white : context.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showJoinForm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _showJoinForm ? AppTheme.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text("Ajansa Katıl", style: TextStyle(color: _showJoinForm ? Colors.white : context.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: !_showJoinForm 
                    ? _buildCreateForm() 
                    : _buildJoinForm(),  
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Column(
      children: [
        CustomTextField(label: "Ajans İsmi", controller: _agencyNameController, icon: LucideIcons.briefcase, hint: 'Ajans ismini girin'),
        const SizedBox(height: 14),
        CustomTextField(label: "Ajans Logo URL (İsteğe Bağlı)", controller: _agencyLogoController, icon: LucideIcons.image, hint: 'https://example.com/logo.png'),
        const SizedBox(height: 28),
        PremiumButton(text: "Ajans Kur (10,000 Coin)", icon: LucideIcons.plusCircle, onPressed: _createAgency),
      ],
    );
  }

  Widget _buildJoinForm() {
    return Column(
      children: [
        Icon(LucideIcons.users, size: 60, color: AppTheme.accent.withOpacity(0.8)),
        const SizedBox(height: 16),
        Text("Davet Kodun Var Mı?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary)),
        const SizedBox(height: 8),
        Text(
          "Ajans sahibinden aldığın davet kodunu girerek hemen ekibe katılabilirsin.",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 30),
        CustomTextField(label: "Örn: AJ-12345", controller: _inviteCodeController, icon: LucideIcons.key, hint: 'Davet Kodu'),
        const SizedBox(height: 28),
        PremiumButton(text: "Ajansa Katıl", icon: LucideIcons.logIn, onPressed: _joinAgency),
      ],
    );
  }
}