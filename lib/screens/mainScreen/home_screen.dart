import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import '../../services/sql_servis.dart';
// 🔥 YENİ: Ortak veri havuzumuzu ekledik
import '../../services/shared_stream_data.dart';
import '../announcements_screen.dart';
import '../liveScreen/audience_live_page.dart';
import '../liveScreen/live.dart';

class HomeScreen extends StatefulWidget {
  // Arama ikonuna basılınca çalışacak olan köprü
  final VoidCallback onSearchTap;

  const HomeScreen({super.key, required this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _subTab = 'trend';
  List<Map<String, dynamic>> _aktifYayinlar = [];
  bool _yukleniyor = true;
  String _myUsername = "Misafir"; // Gerçek kullanıcı adını tutacak değişken

  @override
  void initState() {
    super.initState();
    _kullaniciAdimiBul();
    // 🔥 Ortak Havuzu dinlemeye başla! Veri her değiştiğinde listeyi filtreleyip güncelleyecek.
    SharedStreamData.streamsNotifier.addListener(_verileriFiltrele);
    _verileriFiltrele(); // İlk açılışta mevcut veriyi al
  }

  @override
  void dispose() {
    // Sayfadan çıkınca dinlemeyi bırak (Hafıza dostu)
    SharedStreamData.streamsNotifier.removeListener(_verileriFiltrele);
    super.dispose();
  }

  // Gerçek kullanıcı adını MySQL'den çeken fonksiyon
  Future<void> _kullaniciAdimiBul() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': userId});

    if (res.basarili && res.veri.isNotEmpty && mounted) {
      setState(() {
        _myUsername = res.veri.first['kullanici_adi'] ?? "Misafir_$userId";
      });
    }
  }

  // MySQL'e tekrar tekrar gitmek yerine, ORTAK HAVUZ'daki veriyi alıp sıralayan fonksiyon
  Future<void> _verileriFiltrele() async {
    if (!mounted) return;

    // Veriyi havuzdan kopyala
    List<Map<String, dynamic>> hamVeri = List<Map<String, dynamic>>.from(
      SharedStreamData.streamsNotifier.value,
    );

    // --- TAKİP EDİLENLER FİLTRESİ ---
    if (_subTab == 'takip') {
      final prefs = await SharedPreferences.getInstance();
      final int userId = prefs.getInt('kullanici_id') ?? 1;

      final takipRes = await SqlServis.cek(
        tablo: 'takipciler',
        sartlar: {'takip_eden_id': userId},
      );

      if (takipRes.basarili && takipRes.veri.isNotEmpty) {
        Set<String> takipEdilenIdler = takipRes.veri
            .map((t) => t['takip_edilen_id'].toString())
            .toSet();
        hamVeri = hamVeri
            .where(
              (yayin) => takipEdilenIdler.contains(
                yayin['yayin_sahibi_id'].toString(),
              ),
            )
            .toList();
      } else {
        hamVeri = []; // Kimseyi takip etmiyorsa boş dönsün
      }
    }

    // --- SIRALAMA MANTIĞI ---
    if (_subTab == 'trend') {
      hamVeri.sort((a, b) {
        int izleyiciA = int.tryParse(a['izleyici_sayisi'].toString()) ?? 0;
        int izleyiciB = int.tryParse(b['izleyici_sayisi'].toString()) ?? 0;
        return izleyiciB.compareTo(izleyiciA);
      });
    } else if (_subTab == 'yeni') {
      hamVeri.sort((a, b) {
        String tarihA = a['baslangic_tarihi']?.toString() ?? '';
        String tarihB = b['baslangic_tarihi']?.toString() ?? '';
        return tarihB.compareTo(tarihA);
      });
    }

    // Ekranı güncelle
    if (mounted) {
      setState(() {
        _aktifYayinlar = hamVeri;
        _yukleniyor =
            SharedStreamData.streamsNotifier.value.isEmpty && _yukleniyor;
      });
    }
    _yukleniyor = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── HEADER ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "FiFi Live",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accent,
                      ),
                    ),
                    Row(
                      children: [
                        // Arama butonu ana menüyü tetikler
                        GlassIconButton(
                          icon: LucideIcons.search,
                          onTap: widget.onSearchTap,
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: LucideIcons.bell,
                          color: AppTheme.accentGold,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnnouncementsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── TABS ───
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    GlassTabButton(
                      label: 'Takip',
                      isActive: _subTab == 'takip',
                      onTap: () {
                        setState(() => _subTab = 'takip');
                        _verileriFiltrele(); // SQL'e gitmez, anında filtreler!
                      },
                    ),
                    const SizedBox(width: 8),
                    GlassTabButton(
                      label: 'Trend 🔥',
                      isActive: _subTab == 'trend',
                      onTap: () {
                        setState(() => _subTab = 'trend');
                        _verileriFiltrele();
                      },
                    ),
                    const SizedBox(width: 8),
                    GlassTabButton(
                      label: 'Yeniler ✨',
                      isActive: _subTab == 'yeni',
                      onTap: () {
                        setState(() => _subTab = 'yeni');
                        _verileriFiltrele();
                      },
                    ),
                  ],
                ),
              ),

              // ─── İÇERİK ALANI ───
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.accent,
                  // 🔥 AŞAĞI ÇEKİNCE ORTAK HAVUZU YENİLE
                  onRefresh: () async => await SharedStreamData.fetchStreams(),
                  child: _yukleniyor && _aktifYayinlar.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                          ),
                        )
                      : _aktifYayinlar.isEmpty
                      // YAYIN YOKSA
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(
                                _subTab == 'takip'
                                    ? "Takip ettiğin kimse şu an yayında değil."
                                    : "Şu an aktif bir yayın yok.",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                      // YAYIN VARSA (Senin Orijinal Tasarımın)
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              // ─── STORY ROW (Hikayeler) ───
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  itemCount: _aktifYayinlar.length,
                                  itemBuilder: (context, index) {
                                    final stream = _aktifYayinlar[index];
                                    final yayinciIsmi =
                                        stream['yayin_sahibi_isim'] ??
                                        'Bilinmiyor';
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AudienceLivePage(
                                                roomName: stream['oda_adi'],
                                                username:
                                                    _myUsername, // 🔥 GERÇEK KULLANICI ADI
                                                hostName: yayinciIsmi,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.danger,
                                                  width: 2,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 30,
                                                backgroundColor: AppTheme.accent
                                                    .withOpacity(0.3),
                                                child: Text(
                                                  yayinciIsmi[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              yayinciIsmi.length > 8
                                                  ? "${yayinciIsmi.substring(0, 8)}..."
                                                  : yayinciIsmi,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // ─── GRID (Büyük Yayın Kartları) ───
                              GridView.builder(
                                padding: const EdgeInsets.all(16),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.9,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                itemCount: _aktifYayinlar.length,
                                itemBuilder: (context, index) {
                                  final stream = _aktifYayinlar[index];
                                  return LiveStreamCard(
                                    stream: stream,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AudienceLivePage(
                                          roomName: stream['oda_adi'],
                                          username:
                                              _myUsername, // 🔥 GERÇEK KULLANICI ADI
                                          hostName:
                                              stream['yayin_sahibi_isim'] ??
                                              'Bilinmiyor',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
