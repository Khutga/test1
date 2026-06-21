import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class AgencyOwnerDashboard extends StatefulWidget {
  final int userId;
  final VoidCallback onStatusChanged;

  const AgencyOwnerDashboard({
    super.key,
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  State<AgencyOwnerDashboard> createState() => _AgencyOwnerDashboardState();
}

class _AgencyOwnerDashboardState extends State<AgencyOwnerDashboard> {
  String _activeTab = 'overview';
  bool _isLoading = true;

  Map<String, dynamic>? _agencyData;
  int _agencyId = 0;
  int _agencyTotalCoins = 0;

  List<Map<String, dynamic>> _activeMembers = [];
  List<Map<String, dynamic>> _pendingMembers = [];

  double _minRate = 30.0;
  double _maxRate = 85.0;
  double _currentRate = 60.0;

  final TextEditingController _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final ownerRes = await SqlServis.cek(
      tablo: 'ajanslar',
      sartlar: {'ajans_sahibi_id': widget.userId},
    );
    if (ownerRes.basarili && ownerRes.veri.isNotEmpty) {
      _agencyData = ownerRes.veri.first;
      _agencyId = int.tryParse(_agencyData!['id'].toString()) ?? 0;
      _agencyTotalCoins =
          (double.tryParse(_agencyData!['ajans_kasa_bakiye'].toString()) ?? 0.0)
              .toInt();
      _currentRate =
          double.tryParse(_agencyData!['uye_payi_orani'].toString()) ?? 60.0;
      _rateController.text = _currentRate.toInt().toString();
    }

    final sysRes = await SqlServis.cek(tablo: 'sistem_ayarlari');
    if (sysRes.basarili) {
      for (var ayar in sysRes.veri) {
        if (ayar['ayar_adi'] == 'ajans_min_oran')
          _minRate = double.tryParse(ayar['ayar_degeri'].toString()) ?? 30.0;
        if (ayar['ayar_adi'] == 'ajans_max_oran')
          _maxRate = double.tryParse(ayar['ayar_degeri'].toString()) ?? 85.0;
      }
    }

    final membersRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'ajans_id': _agencyId},
    );

    List<Map<String, dynamic>> tempActive = [];
    List<Map<String, dynamic>> tempPending = [];

    if (membersRes.basarili) {
      DateTime now = DateTime.now();

      for (var member in membersRes.veri) {
        int mId = int.tryParse(member['kullanici_id'].toString()) ?? 0;
        String durum = member['onay_durumu']?.toString() ?? 'Bekliyor';
        String isim = "Bilinmiyor";

        // Sadece bekleyen ödeme detaylarını ve toplam kazandırmayı direkt tablodan çekiyoruz
        double toplamKazandirilan =
            double.tryParse(member['toplam_kazandirilan'].toString()) ?? 0.0;
        double bekleyenOdeme =
            double.tryParse(member['bekleyen_odeme'].toString()) ?? 0.0;

        final hRes = await SqlServis.cek(
          tablo: 'hesaplar',
          sartlar: {'id': mId},
        );
        if (hRes.basarili && hRes.veri.isNotEmpty) {
          isim =
              hRes.veri.first['isim'] ??
              hRes.veri.first['kullanici_adi'] ??
              "Bilinmiyor";
        }

        if (durum == 'Bekliyor') {
          tempPending.add({...member, 'isim': isim, 'db_id': member['id']});
          continue;
        }

        int monthlyIncome = 0;
        final gRes = await SqlServis.cek(
          tablo: 'hediye_gecmisi',
          sartlar: {'alan_id': mId, 'islem_turu': 'ajansli'},
        );
        if (gRes.basarili) {
          for (var g in gRes.veri) {
            if (g['tarih'] != null) {
              try {
                DateTime dt = DateTime.parse(g['tarih']);
                if (dt.year == now.year && dt.month == now.month) {
                  monthlyIncome +=
                      (double.tryParse(g['alici_net_kazanc'].toString()) ?? 0.0)
                          .toInt();
                }
              } catch (_) {}
            }
          }
        }

        tempActive.add({
          ...member,
          'isim': isim,
          'aylik_gelir': monthlyIncome,
          'toplam_kazandirilan': toplamKazandirilan.toInt(),
          'bekleyen_odeme': bekleyenOdeme.toInt(),
        });
      }
    }

    _activeMembers = tempActive;
    _pendingMembers = tempPending;

    if (mounted) setState(() => _isLoading = false);
  }

  // ... (Onaylama ve Çıkarma fonksiyonları bir öncekiyle aynı: _approveMember, _rejectMember, _removeMember, _updateCommissionRate) ...
  Future<void> _approveMember(int kayitId, int kullaniciId) async {
    setState(() => _isLoading = true);
    await SqlServis.guncelle(
      tablo: 'ajans_uyeleri',
      veriler: {
        'onay_durumu': 'Onaylandi',
        'katilma_tarihi': DateTime.now().toString(),
      },
      sartlar: {'id': kayitId},
    );
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'ajansvarmi': 1},
      sartlar: {'id': kullaniciId},
    );
    await _loadAllData();
  }

  Future<void> _rejectMember(int kayitId) async {
    setState(() => _isLoading = true);
    await SqlServis.sil(tablo: 'ajans_uyeleri', sartlar: {'id': kayitId});
    await _loadAllData();
  }

  Future<void> _removeMember(int kullaniciId, String isim) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text(
          "Üyeyi Çıkar",
          style: TextStyle(color: context.textPrimary),
        ),
        content: Text("$isim adlı üyeyi çıkarmak istiyor musunuz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Çıkar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    await SqlServis.sil(
      tablo: 'ajans_uyeleri',
      sartlar: {'kullanici_id': kullaniciId, 'ajans_id': _agencyId},
    );
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'ajansvarmi': 0},
      sartlar: {'id': kullaniciId},
    );
    await _loadAllData();
  }

  Future<void> _updateCommissionRate() async {
    double inputRate = double.tryParse(_rateController.text.trim()) ?? -1.0;
    if (inputRate < _minRate || inputRate > _maxRate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Oran ${_minRate.toInt()} ile ${_maxRate.toInt()} arasında olmalıdır!",
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    await SqlServis.guncelle(
      tablo: 'ajanslar',
      veriler: {'uye_payi_orani': inputRate},
      sartlar: {'id': _agencyId},
    );
    await _loadAllData();
  }

  // =========================================================================
  // 🔥 YENİ: AJANS ÜYESİNE ÖDEME YAPMA SİSTEMİ (İKİNCİ COIN'E AKTARIM)
  // =========================================================================
  Future<void> _showPaymentDialog(Map<String, dynamic> member) async {
    int maxOdeme = member['bekleyen_odeme'];
    if (maxOdeme <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bu üyenin bekleyen alacağı yok."),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    TextEditingController amountCtrl = TextEditingController(
      text: maxOdeme.toString(),
    );

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text(
          "${member['isim']} - Ödeme Yap",
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Üyenin Bekleyen Alacağı: $maxOdeme 🪙",
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: "Ödenecek Tutar",
              hint: "Örn: 500",
              controller: amountCtrl,
              icon: LucideIcons.coins,
              isNumber: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Ödemeyi Tamamla",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int odenecekMiktar = int.tryParse(amountCtrl.text.trim()) ?? 0;

    if (odenecekMiktar <= 0 || odenecekMiktar > maxOdeme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Geçersiz tutar girdiniz!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (_agencyTotalCoins < odenecekMiktar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajans kasanızda yeterli bakiye yok!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    int uyeId = int.tryParse(member['kullanici_id'].toString()) ?? 0;

    // 1. Ajans kasasından parayı düş
    await SqlServis.guncelle(
      tablo: 'ajanslar',
      veriler: {'ajans_kasa_bakiye': _agencyTotalCoins - odenecekMiktar},
      sartlar: {'id': _agencyId},
    );

    // 2. Üyenin bekleyen alacağından parayı düş
    await SqlServis.guncelle(
      tablo: 'ajans_uyeleri',
      veriler: {'bekleyen_odeme': maxOdeme - odenecekMiktar},
      sartlar: {'kullanici_id': uyeId},
    );

    // 3. Üyenin ÇEKİLEBİLİR (ikinci_coin_bakiye) cüzdanına parayı yatır
    final hRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': uyeId});
    if (hRes.basarili && hRes.veri.isNotEmpty) {
      double mevcutIkinciCoin =
          double.tryParse(hRes.veri.first['ikinci_coin_bakiye'].toString()) ??
          0.0;
      await SqlServis.guncelle(
        tablo: 'hesaplar',
        veriler: {'ikinci_coin_bakiye': mevcutIkinciCoin + odenecekMiktar},
        sartlar: {'id': uyeId},
      );
    }

    // 4. Log tablosuna kaydet
    await SqlServis.ekle(
      tablo: 'ajans_odeme_gecmisi',
      veriler: {
        'ajans_id': _agencyId,
        'kullanici_id': uyeId,
        'odenen_miktar': odenecekMiktar,
      },
    );

    await _loadAllData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${member['isim']} adlı yayıncıya $odenecekMiktar 🪙 ödendi.",
        ),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _agencyData?['ajans_ismi'] ?? "Ajansım",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: context.textPrimary,
              ),
            ),
            Text(
              "Yönetici Paneli",
              style: TextStyle(fontSize: 10, color: context.textSecondary),
            ),
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
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.border)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTabBtn("Özet", "overview"),
                      _buildTabBtn(
                        "Bekleyenler (${_pendingMembers.length})",
                        "pending",
                      ),
                      _buildTabBtn(
                        "Üyeler (${_activeMembers.length})",
                        "members",
                      ),
                      _buildTabBtn(
                        "Finans / Ödemeler",
                        "finans",
                      ), // 🔥 YENİ SEKME
                      _buildTabBtn("Ayarlar", "settings"),
                      _buildTabBtn("Davet", "invite"),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildTabContent(),
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'pending':
        return _buildPendingTab();
      case 'members':
        return _buildMembersTab();
      case 'finans':
        return _buildFinansTab(); // 🔥 YENİ SEKME EKRANI
      case 'settings':
        return _buildSettingsTab();
      case 'invite':
        return _buildInviteTab();
      default:
        return const SizedBox();
    }
  }

  // --- SEKME 1, 2, 3, 5, 6 (Öncekiyle aynı tasarımlar) ---
  Widget _buildOverviewTab() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.shieldCheck,
                    color: AppTheme.accent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Ajans Kasa Bakiyesi",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "🪙 $_agencyTotalCoins",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 30, color: context.border),
              _buildInfoRow("Ajans ID:", "#$_agencyId"),
              const SizedBox(height: 10),
              _buildInfoRow(
                "Güncel Dağıtım Oranı:",
                "%${_currentRate.toInt()}",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTab() {
    /* Önceki kodun aynısı... */
    return _pendingMembers.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                "Şu an onay bekleyen başvuru yok.",
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          )
        : Column(
            children: _pendingMembers
                .map(
                  (m) => GlassContainer(
                  
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        GlowAvatar(
                          initial: m['isim'].isNotEmpty
                              ? m['isim'][0].toUpperCase()
                              : '?',
                          radius: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            m['isim'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.xCircle,
                            color: AppTheme.danger,
                          ),
                          onPressed: () => _rejectMember(m['db_id']),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.checkCircle2,
                            color: AppTheme.success,
                          ),
                          onPressed: () => _approveMember(
                            m['db_id'],
                            int.tryParse(m['kullanici_id'].toString()) ?? 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildMembersTab() {
    /* Önceki kodun aynısı... */
    return _activeMembers.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                "Aktif üye bulunmuyor.",
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          )
        : Column(
            children: _activeMembers
                .map(
                  (m) => GlassContainer(
                    
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        GlowAvatar(
                          initial: m['isim'].isNotEmpty
                              ? m['isim'][0].toUpperCase()
                              : '?',
                          radius: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['isim'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                "Bu Ay: +${m['aylik_gelir']} 🪙",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.userMinus,
                            color: AppTheme.danger,
                            size: 20,
                          ),
                          onPressed: () => _removeMember(
                            int.tryParse(m['kullanici_id'].toString()) ?? 0,
                            m['isim'],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildSettingsTab() {
    /* Önceki kodun aynısı... */
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.settings,
                color: AppTheme.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Üye Kazanç Oranı (%)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Oran en az %${_minRate.toInt()} ve en fazla %${_maxRate.toInt()} olabilir.",
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: "Kıza Verilecek Yüzde",
                  controller: _rateController,
                  hint: 'Örn: 60',
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _updateCommissionRate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Kaydet",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    /* Önceki kodun aynısı... */
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(LucideIcons.userPlus, size: 50, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(
            "Davet Et",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: Text(
              _agencyData?['davet_kodu'] ?? "KOD YOK",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 🔥 YENİ SEKME: FİNANS / ÖDEMELER TABLOSU
  // =========================================================================
  Widget _buildFinansTab() {
    if (_activeMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            "Finansal işlem yapılacak üye bulunmuyor.",
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "💰 Ödeme Yönetimi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Aşağıdaki listeden yayıncılara kazandıkları coinleri ödeyerek onların 'Çekilebilir Bakiyesine' aktarabilirsiniz.",
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        const SizedBox(height: 16),

        ..._activeMembers.map((member) {
          int bekleyenOdeme = member['bekleyen_odeme'];
          int toplamKazandirilan = member['toplam_kazandirilan'];
          bool odemeYapilabilir = bekleyenOdeme > 0;

          return GlassContainer(
           
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GlowAvatar(
                          initial: member['isim'].isNotEmpty
                              ? member['isim'][0].toUpperCase()
                              : '?',
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          member['isim'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: odemeYapilabilir
                          ? () => _showPaymentDialog(member)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: odemeYapilabilir
                            ? AppTheme.success
                            : Colors.grey.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Ödeme Yap",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: odemeYapilabilir
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ajansa Kazandırdığı",
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "🪙 $toplamKazandirilan",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Bekleyen Alacağı",
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "🪙 $bekleyenOdeme",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
