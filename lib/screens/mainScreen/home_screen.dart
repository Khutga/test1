import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../widgets/aransWidget.dart';
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

  // 🔥 YENİ: Okunmamış duyuru kontrolü için gerekli değişkenler
  bool _hasUnreadAnnouncements = false;
  int _latestAnnouncementId = 0;

  @override
  void initState() {
    super.initState();
    _kullaniciAdimiBul();
    _checkUnreadAnnouncements(); // 🔥 YENİ: Başlangıçta okunmamış duyuru var mı kontrol et
    // Ortak Havuzu dinlemeye başla! Veri her değiştiğinde listeyi filtreleyip güncelleyecek.
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

    await SqlServis.otomatikRozetleriKontrolEt(userId);

    final res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': userId});

    if (res.basarili && res.veri.isNotEmpty && mounted) {
      setState(() {
        _myUsername = res.veri.first['kullanici_adi'] ?? "Misafir_$userId";
      });
    }
  }

  // 🔥 YENİ: MySQL'deki duyuruları kontrol eden fonksiyon
  Future<void> _checkUnreadAnnouncements() async {
    final res = await SqlServis.cek(tablo: 'duyurular');
    if (res.basarili && res.veri.isNotEmpty) {
      // En yüksek ID'ye sahip olan duyuruyu (en yenisini) bul
      int maxId = 0;
      for (var item in res.veri) {
        int id = int.tryParse(item['id'].toString()) ?? 0;
        if (id > maxId) maxId = id;
      }

      // Cihaz hafızasındaki son okunan ID'yi çek
      final prefs = await SharedPreferences.getInstance();
      int lastSeenId = prefs.getInt('son_okunan_duyuru_id') ?? 0;

      // Eğer yeni bir duyuru varsa rozeti aktif et
      if (mounted) {
        setState(() {
          _latestAnnouncementId = maxId;
          _hasUnreadAnnouncements = maxId > lastSeenId;
        });
      }
    }
  }

  Set<int> ajansliIdler = {}; // Ajanslı kullanıcı ID'lerini tutacak küme
  // MySQL'e tekrar tekrar gitmek yerine, ORTAK HAVUZ'daki veriyi alıp sıralayan fonksiyon
  Future<void> _verileriFiltrele() async {
    if (!mounted) return;
    // Hikayeleri çekerken ajanslıları işaretleyin:
    final ajansRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'onay_durumu': 'Onaylandi'},
    );
    ajansliIdler = ajansRes.veri
        .map((u) => int.parse(u['kullanici_id'].toString()))
        .toSet();
    print("Ajanslı ID'ler: ${ajansliIdler.toString()}");

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

                        // 🔥 YENİ: Bildirim Zili ve Rozet (Badge) Tasarımı
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GlassIconButton(
                              icon: LucideIcons.bell,
                              color: AppTheme.accentGold,
                              onTap: () async {
                                // 1. Tıklandığında anında rozeti temizle ve cihaza "okundu" olarak kaydet
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt(
                                  'son_okunan_duyuru_id',
                                  _latestAnnouncementId,
                                );
                                setState(() {
                                  _hasUnreadAnnouncements = false;
                                });

                                // 2. Sayfaya git
                                if (!mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AnnouncementsScreen(),
                                  ),
                                );

                                // 3. Sayfadan geri dönüldüğünde yeni bir duyuru gelmiş olabilir diye tekrar kontrol et
                                _checkUnreadAnnouncements();
                              },
                            ),
                            if (_hasUnreadAnnouncements)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.danger,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.danger,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                  // 🔥 AŞAĞI ÇEKİNCE ORTAK HAVUZU VE DUYURULARI YENİLE
                  onRefresh: () async {
                    await SharedStreamData.fetchStreams();
                    await _checkUnreadAnnouncements(); // Sayfa yenilendiğinde rozeti de kontrol et
                  },
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
                                            Flexible(
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppTheme.danger,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: AjansBadgeWrapper(
                                                  isAjans: ajansliIdler
                                                      .toString()
                                                      .contains(
                                                        stream['yayin_sahibi_id']
                                                            .toString(),
                                                      ),
                                                  child: CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor: AppTheme
                                                        .accent
                                                        .withOpacity(0.3),
                                                    child: Text(
                                                      yayinciIsmi[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
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
                                                color: AppTheme.accent,
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
                                  return AjansBadgeWrapper(
                                    isAjans: ajansliIdler.toString().contains(
                                      stream['yayin_sahibi_id'].toString(),
                                    ),
                                    child: LiveStreamCard(
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
