import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart'; // Kendi widget yollarını kontrol et

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Yükleme durumları
  bool _isLoadingYayincilar = true;
  bool _isLoadingCutlukler = true;
  bool _isLoadingAjanslar = true;

  // Veri listeleri
  List<dynamic> _yayincilar = [];
  List<dynamic> _cutlukler = [];
  List<dynamic> _ajanslar = [];

  // API Adresi
  final String apiUrl = "https://codefellas.com.tr/apps/nivi/api/leaderboard.php";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  // Sayfa açıldığında 3 kategoriyi de aynı anda çeker
  Future<void> _fetchAllData() async {
    _fetchTab('yayinci');
    _fetchTab('cutluk');
    _fetchTab('ajans');
  }

  Future<void> _fetchTab(String type) async {
    try {
      final response = await http.get(Uri.parse("$apiUrl?type=$type"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['durum'] == 'basarili') {
          if (mounted) {
            setState(() {
              if (type == 'yayinci') {
                _yayincilar = data['veri'];
                _isLoadingYayincilar = false;
              } else if (type == 'cutluk') {
                _cutlukler = data['veri'];
                _isLoadingCutlukler = false;
              } else if (type == 'ajans') {
                _ajanslar = data['veri'];
                _isLoadingAjanslar = false;
              }
            });
          }
        } else {
          print("API Hatası ($type): ${data['mesaj']}");
          _stopLoading(type);
        }
      } else {
        _stopLoading(type);
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      _stopLoading(type);
    }
  }

  void _stopLoading(String type) {
    if (mounted) {
      setState(() {
        if (type == 'yayinci') _isLoadingYayincilar = false;
        if (type == 'cutluk') _isLoadingCutlukler = false;
        if (type == 'ajans') _isLoadingAjanslar = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Haftalık Yarışlar", // 🔥 Həftəlik -> Haftalık
          style: TextStyle(fontWeight: FontWeight.w900, color: context.textPrimary)
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(LucideIcons.video), text: "Yayıncılar"), // 🔥 Yayınçılar -> Yayıncılar
            Tab(icon: Icon(LucideIcons.heart), text: "Çiftler"),    // 🔥 Cütlüklər -> Çiftler
            Tab(icon: Icon(LucideIcons.shield), text: "Ajanslar"),
          ],
        ),
      ),
      body: MainBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_yayincilar, _isLoadingYayincilar, 'yayinci'),
            _buildList(_cutlukler, _isLoadingCutlukler, 'cutluk'),
            _buildList(_ajanslar, _isLoadingAjanslar, 'ajans'),
          ],
        ),
      ),
    );
  }

  // Dinamik Liste Oluşturucu
  Widget _buildList(List<dynamic> list, bool isLoading, String type) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentGold));
    }

    if (list.isEmpty) {
      return const Center(
        child: Text(
          "Bu hafta için henüz sonuç bulunmuyor.", // 🔥 Hələ nəticə yoxdur -> Henüz sonuç bulunmuyor
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        int sira = index + 1;
        
        String isim = "";
        String skorText = "";
        IconData icon = LucideIcons.star;

        // Sekmeye göre JSON'dan verileri eşleştiriyoruz
        if (type == 'yayinci') {
          isim = item['isim'] ?? 'Bilinmiyor';
          skorText = "${item['skor']} Coin";
          icon = LucideIcons.video;
        } else if (type == 'cutluk') {
          isim = "${item['isim1']} & ${item['isim2']}";
          skorText = "Puan: ${item['skor']} (Sv. ${item['seviye']})"; // 🔥 Xal ve Lv. -> Puan ve Sv.
          icon = LucideIcons.heart;
        } else if (type == 'ajans') {
          isim = item['isim'] ?? 'Bilinmeyen Ajans';
          skorText = "${item['skor']} Coin";
          icon = LucideIcons.shieldCheck;
        }

        int kazanilanOdul = int.tryParse(item['kazanilan_odul'].toString()) ?? 0;

        return _buildSiralamaKarti(
          sira: sira,
          isim: isim,
          skorText: skorText,
          icon: icon,
          odul: kazanilanOdul,
        );
      },
    );
  }

  // Sıralama Kartı Tasarımı (Altın, Gümüş, Bronz Detaylı)
  Widget _buildSiralamaKarti({
    required int sira, 
    required String isim, 
    required String skorText, 
    required IconData icon,  int odul=0
  }) {
    Color siraRengi = Colors.grey;
    if (sira == 1) siraRengi = Colors.amber; // Altın (1.)
    if (sira == 2) siraRengi = Colors.grey.shade400; // Gümüş (2.)
    if (sira == 3) siraRengi = Colors.brown.shade300; // Bronz (3.)

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sira <= 3 ? siraRengi.withOpacity(0.6) : Colors.transparent, 
          width: 1.5
        ),
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 25,
              child: Text(
                "#$sira", 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: sira <= 3 ? siraRengi : Colors.grey
                )
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: siraRengi.withOpacity(0.2),
              child: Icon(icon, color: sira <= 3 ? siraRengi : Colors.grey, size: 20),
            ),
          ],
        ),
        title: Text(isim, style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
          ),
          child: Text(
            skorText, 
            style: const TextStyle(
              color: AppTheme.accentGold, 
              fontWeight: FontWeight.w800, 
              fontSize: 12
            )
          ),
        ),
      ),
    );
  }
}