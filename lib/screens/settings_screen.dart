import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Map<String, dynamic>> _options = const [
    {"title": "Hesap Güvenliği", "icon": LucideIcons.key, "color": Colors.blueAccent},
    {"title": "Bildirimler", "icon": LucideIcons.bell, "color": Colors.amber},
    {"title": "Gizlilik", "icon": LucideIcons.shield, "color": Colors.greenAccent},
    {"title": "Dil Seçimi", "icon": LucideIcons.compass, "color": AppColors.primaryPurple},
    {"title": "Yardım & Destek", "icon": LucideIcons.messageCircle, "color": AppColors.primaryPink},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Ayarlar ve Gizlilik", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      ),
      body: MainBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  return MenuActionTile(
                    icon: opt['icon'],
                    label: opt['title'],
                    iconColor: opt['color'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${opt['title']} yakında aktif olacak.")));
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PremiumButton(
                    text: "Hesaptan Çıkış Yap",
                    icon: LucideIcons.logOut,
                    onPressed: () {}, 
                  ),
                  const SizedBox(height: 16),
                  const Text("FiFi Live v2.4.1 (Build 842)", style: TextStyle(color: AppColors.textGray, fontSize: 11)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}