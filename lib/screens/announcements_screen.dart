import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final TextEditingController _annController = TextEditingController();
  int _userCoins = 0;
  int _userId = 1;
  String _userName = "Sen";
  
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;

    // Kullanıcı Bakiyesi ve Adını Çek
    final userRes = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': _userId});
    if (userRes.basarili && userRes.veri.isNotEmpty) {
      _userCoins = int.tryParse(userRes.veri.first['birinci_coin_bakiye'].toString()) ?? 0;
      _userName = userRes.veri.first['isim'] ?? 'Sen';
    }

    // Duyuruları Çek (Yeniden eskiye sıralamak için SQL'de ORDER BY gerekir ama serviste şimdilik tersten listeye ekleyebiliriz)
    final annRes = await SqlServis.cek(tablo: 'duyurular');
    if (annRes.basarili) {
      _announcements = annRes.veri.reversed.toList(); // En yeniler en üstte
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handlePublish() async {
    if (_annController.text.trim().isEmpty) return;
    const int cost = 15000;
    
    if (_userCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz coin!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    // Bakiyeyi Düş
    int yeniBakiye = _userCoins - cost;
    await SqlServis.guncelle(tablo: 'hesaplar', veriler: {'birinci_coin_bakiye': yeniBakiye}, sartlar: {'id': _userId});

    // Duyuruyu Ekle
    await SqlServis.ekle(
      tablo: 'duyurular', 
      veriler: {
        'gonderen_id': _userId,
        'gonderen_isim': _userName,
        'tip': 'pk',
        'mesaj': _annController.text.trim(),
        'maliyet': cost
      }
    );

    _annController.clear();
    await _initData(); // Listeyi ve bakiyeyi yenile
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Duyuru yayınlandı!"), backgroundColor: AppTheme.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Duyurular", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textPrimary)),
            Text("Bakiye: $_userCoins Coin", style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _announcements.isEmpty 
                  ? const Center(child: Text("Henüz duyuru yok.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _announcements.length,
                  itemBuilder: (_, index) {
                    final item = _announcements[index];
                    final isSystem = item['tip'] == 'sistem';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['gonderen_isim'] ?? 'Sistem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSystem ? AppTheme.accent : AppTheme.accentGold)),
                                Text((item['tarih'] ?? '').toString().split(' ').first, style: TextStyle(fontSize: 10, color: context.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(item['mesaj'] ?? '', style: TextStyle(fontSize: 14, color: context.textPrimary)),
                            if (int.tryParse(item['maliyet'].toString()) != null && int.parse(item['maliyet'].toString()) > 0)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: const Text("Sponsorlu", style: TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.w700)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: context.card,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.warning.withOpacity(0.15))),
                      child: Row(
                        children: [
                          Icon(LucideIcons.shieldAlert, color: AppTheme.warning, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text("15,000 Coin ile tüm sunucuya duyuru gönderebilirsiniz.", style: TextStyle(color: AppTheme.warning, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _annController,
                            style: TextStyle(fontSize: 14, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Duyuru yaz...",
                              hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
                              filled: true,
                              fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handlePublish,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                          child: const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ],
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