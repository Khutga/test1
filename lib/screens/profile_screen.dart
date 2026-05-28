import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';
import 'coin_shop_screen.dart';
import 'edit_profile_screen.dart';
import 'gift_history_screen.dart';
import 'agency_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGray),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const GlowAvatar(
                  initial: "A",
                  radius: 44,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Alexander",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.edit2,
                        color: AppColors.primaryPurple,
                        size: 18,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ),
                    ),
                  ],
                ), // "Alexander" Row'undan sonra, bio Text'inden önce ekle:
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem("12.4K", "Takipçi"),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white12,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem("348", "Takip"),
                    Container(
                      width: 1,
                      height: 28,
                      color: Colors.white12,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem("Lv.42", "Seviye"),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  gradientColors: [
                    AppColors.primaryPurple.withOpacity(0.2),
                    AppColors.primaryPink.withOpacity(0.1),
                  ],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bakiye",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "54,200 Coin",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CoinShopScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          shadowColor: AppColors.primaryPink.withOpacity(0.5),
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Yükle",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                MenuActionTile(
                  icon: LucideIcons.gift,
                  label: "Hediye Geçmişi",
                  iconColor: Colors.pink,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GiftHistoryScreen(),
                    ),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.activity,
                  label: "Ajans Sistemi & Paneli",
                  iconColor: Colors.greenAccent,
                  badge: "VIP",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgencyScreen()),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.shield,
                  label: "Ayarlar ve Gizlilik",
                  iconColor: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
