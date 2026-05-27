import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  final List<Map<String, dynamic>> _options = const [
    {"title": "Hesab Güvənliyi", "icon": LucideIcons.key, "color": Colors.blue, "desc": "Şifrə və doğrulama"},
    {"title": "Bildirişlər", "icon": LucideIcons.bell, "color": Colors.yellow, "desc": "Mesaj və canlı yayın"},
    {"title": "Gizlilik", "icon": LucideIcons.shield, "color": Colors.green, "desc": "Kimlər görə bilər"},
    {"title": "Dil Seçimi", "icon": LucideIcons.compass, "color": AppColors.primaryPurple, "desc": "Azərbaycanca"},
    {"title": "Yardım & Dəstək", "icon": LucideIcons.messageCircle, "color": AppColors.primaryPink, "desc": "Bizimlə əlaqə"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Ayarlar ve Gizlilik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final opt = _options[index];
                return ListTile(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${opt['title']} ayarları bölməsi tezliklə aktiv olacaq.")),
                    );
                  },
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                    child: Icon(opt['icon'], color: opt['color'], size: 20),
                  ),
                  title: Text(opt['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(opt['desc'], style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                  trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textGray, size: 20),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.logOut, color: Colors.red, size: 18),
                    label: const Text("Hesabdan Çıxış Et", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("FiFi Live v2.4.1 (Build 842)", style: TextStyle(color: AppColors.textGray, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}