import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../services/shared_stream_data.dart';
import '../../services/sql_servis.dart';
import 'home_screen.dart';
import '../liveScreen/host_live_page.dart';
import '../chatScreen/messages_screen.dart';
import '../accountScreen/profile_screen.dart';
import 'search_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  String? _kullaniciCinsiyet;
  bool _bilgilerYukleniyor = true;

  // 🔥 YENİ: Okunmayan mesaj sayısını tutan değişken ve zamanlayıcı
  int _okunmayanMesajSayisi = 0;
  Timer? _mesajSayacTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // 1 rakamı İkinci Sekme (SearchScreen) anlamına gelir.
      HomeScreen(onSearchTap: () => onTabTapped(1)),
      const SearchScreen(),
      const Center(child: Text("Yayın Katmanı")),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    SharedStreamData.startPolling();
    _kullaniciBilgileriniCek();

    // 🔥 Okunmayan mesajları ilk açılışta çek ve her 3 saniyede bir arka planda kontrol et
    _okunmayanMesajlariCek();
    _mesajSayacTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _okunmayanMesajlariCek(),
    );
  }

  @override
  void dispose() {
    SharedStreamData.stopPolling();
    _mesajSayacTimer?.cancel(); // 🔥 Sayfadan çıkınca sayacı durdur
    super.dispose();
  }

  Future<void> _kullaniciBilgileriniCek() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final response = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': userId},
    );
    if (response.basarili && response.veri.isNotEmpty && mounted) {
      setState(() {
        _kullaniciCinsiyet = response.veri.first['cinsiyet'];
        _bilgilerYukleniyor = false;
      });
    } else {
      if (mounted) setState(() => _bilgilerYukleniyor = false);
    }
  }

  // 🔥 YENİ: Veritabanından okunmamış mesajları sayan fonksiyon
  Future<void> _okunmayanMesajlariCek() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final response = await SqlServis.cek(
      tablo: 'mesajlar',
      sartlar: {
        'alan_id': userId,
        'okundu_mu': 0, // Sadece okunmamış olanları getir
      },
    );

    if (response.basarili && mounted) {
      // Çekilen satır sayısı okunmamış mesaj sayısına eşittir
      if (_okunmayanMesajSayisi != response.veri.length) {
        setState(() {
          _okunmayanMesajSayisi = response.veri.length;
        });
      }
    }
  }

  void onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  // ==========================================
  // YAYIN AYARLARI (ETİKET SEÇİMİ) PANELİ
  // ==========================================
  void _showGoLiveBottomSheet() {
    String selectedTag = "Sohbet";
    final TextEditingController customTagController = TextEditingController();
    bool isCustomTag = false;

    final List<Map<String, String>> predefinedTags = [
      {"icon": "💬", "label": "Sohbet"},
      {"icon": "🎮", "label": "Oyun"},
      {"icon": "🎵", "label": "Müzik"},
      {"icon": "🎭", "label": "Eğlence"},
      {"icon": "💃", "label": "Dans"},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.radio,
                              color: AppTheme.danger,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Canlı Yayın Başlat",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Yayının için bir konu (etiket) belirle:",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // HAZIR ETİKETLER
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: predefinedTags.map((tag) {
                            final isSelected =
                                !isCustomTag && selectedTag == tag['label'];
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  isCustomTag = false;
                                  selectedTag = tag['label']!;
                                  customTagController.clear();
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.accent
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentLight
                                        : Colors.white10,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.accent.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  "${tag['icon']} ${tag['label']}",
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        // KENDİ ETİKETİNİ YAZ
                        GestureDetector(
                          onTap: () => setModalState(() => isCustomTag = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCustomTag
                                  ? AppTheme.accent.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCustomTag
                                    ? AppTheme.accent
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text("✨", style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: customTagController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    onChanged: (val) {
                                      if (!isCustomTag)
                                        setModalState(() => isCustomTag = true);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Kendi etiketini yaz...",
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // YAYINI BAŞLAT BUTONU
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppTheme.danger.withOpacity(0.5),
                            ),
                            onPressed: () async {
                              // Etiketi belirle
                              final finalTag =
                                  isCustomTag &&
                                      customTagController.text.trim().isNotEmpty
                                  ? customTagController.text.trim()
                                  : selectedTag;

                              // Menüyü Kapat
                              Navigator.pop(ctx);

                              // Verileri Çek ve Yayına Geç
                              await _startLiveWithTag(finalTag);
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.video, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Yayını Başlat",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Verileri toplayıp Host sayfasına gönderen arka plan metodu
  Future<void> _startLiveWithTag(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final response = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': userId},
    );

    String gercekKullaniciAdi = "Misafir_$userId";
    if (response.basarili && response.veri.isNotEmpty) {
      gercekKullaniciAdi =
          response.veri.first['kullanici_adi'] ?? gercekKullaniciAdi;
    }

    final String aktifOdaAdi = "canli_oda_$userId";
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HostLivePage(
          roomName: aktifOdaAdi,
          username: gercekKullaniciAdi,
          etiket: tag,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),

      floatingActionButton: SizedBox(
        height: 52,
        width: 52,
        child: FloatingActionButton(
          onPressed: _showGoLiveBottomSheet,
          backgroundColor: AppTheme.accent,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(LucideIcons.video, color: Colors.white, size: 22),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: context.card.withOpacity(context.isDark ? 0.85 : 0.92),
              border: Border(
                top: BorderSide(color: context.border.withOpacity(0.3)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: LucideIcons.home,
                      label: "Canlı",
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: LucideIcons.compass,
                      label: "Keşfet",
                      index: 1,
                    ),
                    const SizedBox(width: 40),
                    _buildNavItem(
                      icon: LucideIcons.messageCircle,
                      label: "Mesajlar",
                      index: 3,
                      badge:
                          _okunmayanMesajSayisi, // 🔥 GERÇEK VERİ BURAYA BAĞLANDI
                    ),
                    _buildNavItem(
                      icon: LucideIcons.user,
                      label: "Profil",
                      index: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    int badge = 0,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.accent : context.textSecondary,
                  size: isSelected ? 26 : 24,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.accent : context.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: -2,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.card, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      // Sayı 9'dan büyükse 9+ göster ki tasarım dışına taşmasın
                      badge > 9 ? "9+" : badge.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
