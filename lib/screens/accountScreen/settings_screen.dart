import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_widgets.dart';
import 'login_screen.dart';
import '../adminScreen/admin_panel_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kullanici_id');

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ayarlar",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: context.textPrimary,
          ),
        ),
      ),
      body: MainBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Hesap",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            MenuActionTile(
              iconColor: AppTheme.accentGold,
              icon: LucideIcons.bell,
              label: "Bildirimler",
              onTap: () {},
            ),
            MenuActionTile(
              iconColor: AppTheme.accentGold,
              icon: LucideIcons.lock,
              label: "Gizlilik ve Güvenlik",
              onTap: () {},
            ),

            MenuActionTile(
              iconColor: AppTheme.accentGold,
              icon: LucideIcons.fileText,
              label: "Kullanım Koşulları",
              onTap: () {},
            ),
            MenuActionTile(
              iconColor: AppTheme.accentGold,
              icon: LucideIcons.helpCircle,
              label: "Yardım Merkezi",
              onTap: () {},
            ),
            MenuActionTile(
              iconColor: AppTheme.accentGold,
              icon: LucideIcons.info,
              label: "Hakkında",
              onTap: () {},
            ),
            //////////////////////////////  ADMIN PANELİNE SADECE BELİRLİ KULLANICILARIN GÖRÜNTÜLEYEBİLMESİ İÇİN ÖRNEK KOD
            MenuActionTile(
              icon: LucideIcons.shield,
              label: "Admin Panel",
              iconColor: AppTheme.danger,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(LucideIcons.logOut, color: Colors.white),
              label: const Text(
                "Çıkış Yap",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
