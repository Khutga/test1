import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final TextEditingController _annController = TextEditingController();
  int _userCoins = 54200;
  List<Map<String, dynamic>> _announcements = List.from(MockData.announcements);

  void _handlePublish() {
    if (_annController.text.trim().isEmpty) return;
    const int cost = 15000;

    if (_userCoins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yeterli coin yok! Lazım olan: 15,000 Coin"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _userCoins -= cost;
      _announcements.insert(0, {
        "id": DateTime.now().millisecondsSinceEpoch,
        "sender": "SİZ (Ajans Sahibi)",
        "type": "pk",
        "text": _annController.text,
        "time": "Şimdi",
        "cost": cost
      });
      _annController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🎉 Duyurunuz başarıyla yayınlandı! -15,000 Coin"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sistem Duyuruları (📢)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Bakiyeniz: $_userCoins Coin", style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
          ],
        ),
      ),
      body: MainBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final item = _announcements[index];
                  final isSystem = item['type'] == 'system';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSystem ? Colors.blue.withOpacity(0.1) : AppColors.primaryPurple.withOpacity(0.1),
                      border: Border.all(color: isSystem ? Colors.blue.withOpacity(0.3) : AppColors.primaryPurple.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['sender'],
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSystem ? Colors.blue : AppColors.primaryPurple),
                            ),
                            Text(item['time'], style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item['text'], style: const TextStyle(fontSize: 14, color: Colors.white)),
                        if (item['cost'] != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                              child: const Text("Sponsorlu Duyuru", style: TextStyle(fontSize: 9, color: AppColors.primaryPurple)),
                            ),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBackground,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text("Ajans sahipleri ve VIP kullanıcılar 15,000 Coin karşılığında sisteme turnuva, PK yarışı veya özel duyuru gönderebilir!", style: TextStyle(color: Colors.amber, fontSize: 10)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _annController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: "Herkese duyuru gönder...",
                            hintStyle: const TextStyle(color: AppColors.textGray),
                            filled: true,
                            fillColor: Colors.white10,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _handlePublish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text("Göndər", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}