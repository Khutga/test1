import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../home_screen.dart';
import '../live.dart';
import '../messages_screen.dart';
import '../profile_screen.dart';
import '../search_screen.dart';

// Veritabanı işlemleri için SqlServis'i import ettik

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const Center(child: Text("Yayın Katmanı")),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
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
          onPressed: () async {
            // 1. Hafızadan anlık giriş yapmış kişinin ID'sini çekiyoruz
            final prefs = await SharedPreferences.getInstance();
            final int userId = prefs.getInt('kullanici_id') ?? 1;

            // 2. Bu ID'yi kullanarak veritabanından(hesaplar tablosu) kullanıcının gerçek adını çekiyoruz
            final response = await SqlServis.cek(
              tablo: 'hesaplar',
              sartlar: {'id': userId},
            );

            // Varsayılan bir isim belirliyoruz (Hata olursa patlamasın diye)
            String gercekKullaniciAdi = "Misafir_$userId";

            // Eğer sorgu başarılıysa ve veri boş değilse veritabanındaki kullanıcı adını al
            if (response.basarili && response.veri.isNotEmpty) {
              gercekKullaniciAdi =
                  response.veri.first['kullanici_adi'] ?? gercekKullaniciAdi;
            }

            // 3. Benzersiz yayın odası adı oluşturuyoruz
            final String aktifOdaAdi = "canli_oda_$userId";

            // Widget ağacı hala ekranda mı kontrolü
            if (!context.mounted) return;

            // 4. Bilgileri PremiumLiveStreamPage'e gönderiyoruz
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return PremiumLiveStreamPage(
                    roomName: aktifOdaAdi,
                    username:
                        gercekKullaniciAdi, // Artık veritabanından gelen gerçek ismi kullanıyoruz
                    isHost: true,
                  );
                },
              ),
            );
          },
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
                      badge: 2,
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
      onTap: () => _onTabTapped(index),
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
                      badge.toString(),
                      style: const TextStyle(
                        fontSize: 12,
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
