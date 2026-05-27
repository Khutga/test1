import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import 'coin_shop_screen.dart';
import 'edit_profile_screen.dart';
import 'gift_history_screen.dart';
import 'relationship_screen.dart';
import 'agency_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar ve İsim
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryPurple,
                child: Text("A", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Alexander", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.edit2, color: AppColors.primaryPurple, size: 18),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text("Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGray, fontSize: 12)),
              
              const SizedBox(height: 24),
              
              // Cüzdan Alanı (Wallet)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryPurple.withOpacity(0.3), AppColors.primaryPink.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Şəxsi Balans", style: TextStyle(fontSize: 12, color: AppColors.textGray)),
                        Text("54,200 Coin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CoinShopScreen()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
                      child: const Text("Yükle", style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Menü Listesi ve Sayfa Geçiş Bağlantıları
              _buildMenuRow(context, LucideIcons.gift, "Hediye Geçmişi", Colors.pink, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftHistoryScreen()));
              }),
              _buildMenuRow(context, LucideIcons.heart, "Birliktelik Alanım", Colors.red, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipScreen()));
              }, badge: "Seviye 4"),
              _buildMenuRow(context, LucideIcons.activity, "Ajans Sistemi & Paneli", Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AgencyScreen()));
              }, badge: "Giriş"),
              _buildMenuRow(context, LucideIcons.shield, "Ayarlar ve Gizlilik", Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, IconData icon, String label, Color iconColor, VoidCallback onTap, {String? badge}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderWhite),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.moreVertical, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}