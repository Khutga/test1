import 'dart:async'; // Timer kullanmak için eklendi
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';
import '../services/sql_servis.dart';
import 'live.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _subTab = 'trend';

  List<Map<String, dynamic>> _aktifYayinlar = [];
  bool _yukleniyor = true;
  Timer? _timer; // Otomatik yenileme sayacı

  @override
  void initState() {
    super.initState();
    _yayinlariGetir();

    // 15 Saniyede bir arka planda sessizce yenile
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _yayinlariGetir(gizliYenileme: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Sayfadan çıkıldığında sayacı durdur (Hafıza dostu)
    super.dispose();
  }

  /// MySQL'den aktif yayınları çeken fonksiyon
  /// [gizliYenileme] true ise ekranda loading yuvarlağı göstermez, veriyi arkadan günceller.
  Future<void> _yayinlariGetir({bool gizliYenileme = false}) async {
    if (!gizliYenileme) {
      setState(() => _yukleniyor = true);
    }

    final response = await SqlServis.cek(
      tablo: 'aktif_yayinlar',
      sartlar: {'yayin_durumu': 'aktif'},
    );

    // Eğer kullanıcı bu esnada başka sayfaya geçtiyse (widget öldüyse) hata vermemesi için kontrol:
    if (!mounted) return;

    if (response.basarili) {
      setState(() {
        _aktifYayinlar = response.veri;
        _yukleniyor = false;
      });
    } else {
      setState(() => _yukleniyor = false);
      debugPrint("Yayınlar çekilirken hata: ${response.mesaj}");
    }
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
                        GlassIconButton(icon: LucideIcons.search, onTap: () {}),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: LucideIcons.bell,
                          color: AppTheme.accentGold,
                          onTap: () {},
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
                        _yayinlariGetir();
                      },
                    ),
                    const SizedBox(width: 8),
                    GlassTabButton(
                      label: 'Trend 🔥',
                      isActive: _subTab == 'trend',
                      onTap: () {
                        setState(() => _subTab = 'trend');
                        _yayinlariGetir();
                      },
                    ),
                    const SizedBox(width: 8),
                    GlassTabButton(
                      label: 'Yeniler ✨',
                      isActive: _subTab == 'yeni',
                      onTap: () {
                        setState(() => _subTab = 'yeni');
                        _yayinlariGetir();
                      },
                    ),
                  ],
                ),
              ),

              // ─── İÇERİK ALANI (RefreshIndicator ile sarmalandı) ───
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.accent,
                  // Kullanıcı aşağı çektiğinde çalışacak fonksiyon
                  onRefresh: () async {
                    await _yayinlariGetir(gizliYenileme: false);
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
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                "Şu an aktif bir yayın yok.",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                      // YAYIN VARSA
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
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppTheme.accent,
                                                width: 2,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              radius: 30,
                                              backgroundColor: AppTheme.accent
                                                  .withOpacity(0.1),
                                              child: Text(
                                                yayinciIsmi[0].toUpperCase(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: AppTheme.accent,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            yayinciIsmi,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // ─── GRID (Büyük Yayın Kartları) ───
                              GridView.builder(
                                padding: const EdgeInsets.all(16),
                                shrinkWrap:
                                    true, // SingleChildScrollView içinde olduğu için şart
                                physics:
                                    const NeverScrollableScrollPhysics(), // Scroll işlemini ana SingleChildScrollView'a bırakır
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
                                        builder: (_) => PremiumLiveStreamPage(
                                          roomName: "${stream['oda_adi']}",
                                          username:
                                              'İzleyiciKullanici', // TODO: Auth'dan gelen aktif kullanıcıyı yaz
                                          isHost: false,
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
