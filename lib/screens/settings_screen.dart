import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/theme_provider.dart';
import '../widgets/custom_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ayarlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── GÖRÜNÜM ───
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Text("Görünüm", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textSecondary)),
                    ),

                    // Dark mode toggle
                    MenuActionTile(
                      icon: themeProvider.isDark ? LucideIcons.moon : LucideIcons.sun,
                      label: "Karanlık Mod",
                      iconColor: themeProvider.isDark ? Colors.indigo : AppTheme.accentGold,
                      trailing: Switch.adaptive(
                        value: themeProvider.isDark,
                        activeColor: AppTheme.accent,
                        onChanged: (_) {
                          themeProvider.toggle();
                          setState(() {});
                        },
                      ),
                      onTap: () {
                        themeProvider.toggle();
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text("Hesap", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textSecondary)),
                    ),

                    MenuActionTile(
                      icon: LucideIcons.key, label: "Hesap Güvenliği", iconColor: AppTheme.accent,
                      onTap: () => _showSoon(context, "Hesap Güvenliği"),
                    ),
                    MenuActionTile(
                      icon: LucideIcons.bell, label: "Bildirimler", iconColor: AppTheme.accentGold,
                      onTap: () => _showSoon(context, "Bildirimler"),
                    ),
                    MenuActionTile(
                      icon: LucideIcons.shield, label: "Gizlilik", iconColor: AppTheme.success,
                      onTap: () => _showSoon(context, "Gizlilik"),
                    ),
                    MenuActionTile(
                      icon: LucideIcons.globe, label: "Dil Seçimi", iconColor: Colors.indigo,
                      onTap: () => _showSoon(context, "Dil Seçimi"),
                    ),
                    MenuActionTile(
                      icon: LucideIcons.messageCircle, label: "Yardım & Destek", iconColor: AppTheme.danger,
                      onTap: () => _showSoon(context, "Yardım & Destek"),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    PremiumButton(text: "Çıkış Yap", icon: LucideIcons.logOut, onPressed: () {}),
                    const SizedBox(height: 10),
                    Text("FiFi Live v2.4.1 (Build 842)", style: TextStyle(color: context.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$title yakında aktif olacak."), behavior: SnackBarBehavior.floating),
    );
  }
}
