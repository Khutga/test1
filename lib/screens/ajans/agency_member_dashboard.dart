import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class AgencyMemberDashboard extends StatefulWidget {
  final int userId;
  final VoidCallback onStatusChanged;

  const AgencyMemberDashboard({
    super.key, 
    required this.userId,
    required this.onStatusChanged,
  });

  @override
  State<AgencyMemberDashboard> createState() => _AgencyMemberDashboardState();
}

class _AgencyMemberDashboardState extends State<AgencyMemberDashboard> {
  bool _isLoading = true;

  String _agencyName = "Yükleniyor...";
  String _leaderName = "Yükleniyor...";
  
  double _commissionRate = 60.0;
  int _totalContributed = 0; // Kıza ajans üzerinden gelen toplam net kazanç
  int _pendingPayment = 0;   // Ajansın kıza ödemesi gereken bakiye
  int _myMonthlyIncome = 0;  // Bu ayki net kazanç

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  // =========================================================================
  // ÜYE VERİLERİNİ ÇEKME
  // =========================================================================
  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    // 1. Üyenin ajans kaydını ve finansal verilerini çek
    final memberRes = await SqlServis.cek(tablo: 'ajans_uyeleri', sartlar: {'kullanici_id': widget.userId});
    
    if (memberRes.basarili && memberRes.veri.isNotEmpty) {
      final memberData = memberRes.veri.first;
      int ajansId = int.tryParse(memberData['ajans_id'].toString()) ?? 0;
      
      _totalContributed = (double.tryParse(memberData['toplam_kazandirilan'].toString()) ?? 0.0).toInt();
      _pendingPayment = (double.tryParse(memberData['bekleyen_odeme'].toString()) ?? 0.0).toInt();

      // 2. Ajansın genel bilgilerini çek
      final agencyRes = await SqlServis.cek(tablo: 'ajanslar', sartlar: {'id': ajansId});
      if (agencyRes.basarili && agencyRes.veri.isNotEmpty) {
        final agencyData = agencyRes.veri.first;
        _agencyName = agencyData['ajans_ismi'] ?? "Ajansım";
        _commissionRate = double.tryParse(agencyData['uye_payi_orani'].toString()) ?? 60.0;

        int ownerId = int.tryParse(agencyData['ajans_sahibi_id'].toString()) ?? 0;

        // 3. Ajans Sahibinin Adını Çek
        final leaderRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': ownerId});
        if (leaderRes.basarili && leaderRes.veri.isNotEmpty) {
          _leaderName = leaderRes.veri.first['isim'] ?? leaderRes.veri.first['kullanici_adi'] ?? "Bilinmiyor";
        }
      }

      // 4. Bu Ayki Geliri Hesapla (Hediye Geçmişi Tablosundan)
      int monthlyIncome = 0;
      DateTime now = DateTime.now();
      
      final gRes = await SqlServis.cek(tablo: 'hediye_gecmisi', sartlar: {'alan_id': widget.userId, 'islem_turu': 'ajansli'});
      if (gRes.basarili) {
        for (var g in gRes.veri) {
          if (g['tarih'] != null) {
            try {
              DateTime dt = DateTime.parse(g['tarih']);
              if (dt.year == now.year && dt.month == now.month) {
                // Üyenin net kazancından kendi payına düşeni hesaplıyoruz
                double netIslem = double.tryParse(g['alici_net_kazanc'].toString()) ?? 0.0;
                monthlyIncome += ((netIslem * _commissionRate) / 100).toInt();
              }
            } catch (_) {}
          }
        }
      }
      _myMonthlyIncome = monthlyIncome;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // =========================================================================
  // AJANSTAN AYRILMA
  // =========================================================================
  Future<void> _leaveAgency() async {
    // İçeride bakiyesi varsa uyarı verelim
    if (_pendingPayment > 0) {
      bool? forceLeave = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.card,
          title: Text("Ödenmemiş Bakiyeniz Var!", style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          content: Text("İçeride ödenmemiş $_pendingPayment 🪙 alacağınız bulunuyor. Ajanstan ayrılırsanız bu bakiye sıfırlanabilir veya ajans insiyatifine kalabilir. Yine de ayrılmak istiyor musunuz?", style: TextStyle(color: context.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Ayrıl", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (forceLeave != true) return;
    } else {
      bool? confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.card,
          title: Text("Ajanstan Ayrıl", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          content: Text("Mevcut ajansınızdan ayrılmak istediğinize emin misiniz?", style: TextStyle(color: context.textSecondary)),
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
    }

    setState(() => _isLoading = true);

    // 1. ajans_uyeleri tablosundan kendi kaydımı sil
    await SqlServis.sil(tablo: 'ajans_uyeleri', sartlar: {'kullanici_id': widget.userId});

    // 2. kendi hesabımı güncelle
    await SqlServis.guncelle(tablo: 'hesaplar', veriler: {'ajansvarmi': 0}, sartlar: {'id': widget.userId});

    // 3. Ana yönlendiriciyi tetikle (Başvuru ekranına düşecek)
    widget.onStatusChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.accent)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_agencyName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.textPrimary)),
            Text("Üye Paneli", style: TextStyle(fontSize: 10, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ajans Bilgileri Kartı
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
                                Text(_agencyName, style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 30, color: context.border),
                      _buildInfoRow("Ajans Lideri:", _leaderName),
                      const SizedBox(height: 10),
                      _buildInfoRow("Senin Kazanç Oranın:", "%${_commissionRate.toInt()}"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bekleyen Bakiye Kartı (En Önemli Kısım)
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Bekleyen Alacağın", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            "🪙 $_pendingPayment",
                            style: const TextStyle(color: AppTheme.accentGold, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ajans liderin tarafından ödenmesi beklenen tutar.",
                            style: TextStyle(color: context.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                      const Icon(LucideIcons.wallet, color: AppTheme.accentGold, size: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Aylık ve Toplam İstatistikler
                Row(
                  children: [
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Bu Ayki Kazancın", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                            const SizedBox(height: 8),
                            Text("+ $_myMonthlyIncome", style: const TextStyle(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Toplam Getirin", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                            const SizedBox(height: 8),
                            Text("🪙 $_totalContributed", style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),

                // Ajanstan Ayrıl Butonu
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
            ),
          ),
        ),
      ),
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
}