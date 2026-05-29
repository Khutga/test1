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

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.textPrimary, // Temadan çekildi
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textSecondary), // Temadan çekildi
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
                GlowAvatar(
                  initial: "A",
                  radius: 44,
                  color: AppTheme.accent, // Hatalı primaryPurple değiştirildi
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Alexander",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.edit2,
                        color: AppTheme.accent,
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
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(context, "12.4K", "Takipçi"),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.border, // Temadan çekildi
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(context, "348", "Takip"),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.border,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(context, "Lv.42", "Seviye"),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bakiye",
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "54,200 Coin",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentGold, // Temaya uygun
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
                          backgroundColor: AppTheme.accent,
                          shadowColor: AppTheme.accent.withOpacity(0.3),
                          elevation: 4,
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
                  iconColor: AppTheme.danger,
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
                  iconColor: AppTheme.success,
                  badge: "VIP",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgencyScreen()),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.shield,
                  label: "Ayarlar ve Gizlilik",
                  iconColor: AppTheme.accent,
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