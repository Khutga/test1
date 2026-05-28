import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz coin!"), backgroundColor: Colors.red));
      return;
    }
    setState(() {
      _userCoins -= cost;
      _announcements.insert(0, {"id": DateTime.now().millisecondsSinceEpoch, "sender": "SİZ", "type": "pk", "text": _annController.text, "time": "Şimdi", "cost": cost});
      _annController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Duyuru yayınlandı!"), backgroundColor: AppTheme.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Duyurular", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary)),
            Text("Bakiye: $_userCoins Coin", style: TextStyle(fontSize: 9, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _announcements.length,
                  itemBuilder: (_, index) {
                    final item = _announcements[index];
                    final isSystem = item['type'] == 'system';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['sender'], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isSystem ? AppTheme.accent : AppTheme.accentGold)),
                                Text(item['time'], style: TextStyle(fontSize: 9, color: context.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(item['text'], style: TextStyle(fontSize: 12, color: context.textPrimary)),
                            if (item['cost'] != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text("Sponsorlu", style: TextStyle(fontSize: 8, color: AppTheme.accent, fontWeight: FontWeight.w700)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input
              Container(
                padding: const EdgeInsets.all(12),
                color: context.card,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.warning.withOpacity(0.15))),
                      child: Row(
                        children: [
                          Icon(LucideIcons.shieldAlert, color: AppTheme.warning, size: 14),
                          const SizedBox(width: 6),
                          Expanded(child: Text("15,000 Coin ile duyuru gönderebilirsiniz.", style: TextStyle(color: AppTheme.warning, fontSize: 9))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _annController,
                            style: TextStyle(fontSize: 12, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: "Duyuru yaz...",
                              hintStyle: TextStyle(color: context.textSecondary, fontSize: 12),
                              filled: true,
                              fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: _handlePublish,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                          child: const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
