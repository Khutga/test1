import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Etkinlikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Aktif turnuvalara katılın.", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                const SizedBox(height: 16),

                // Ana turnuva kartı
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SEZONLUK TURNUVA", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      const Text("Haftalık en çok coin kazananlara \$10,000 ödül!", style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                            child: const Text("00:00'da Sıfırlanır", style: TextStyle(fontSize: 9, color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Katıldınız!"), backgroundColor: Colors.green)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.accent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                            child: const Text("Katıl", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildEventCard(context, "En Aktif Çift Challenge", "Premium Çift Badge", "1.2K Çift"),
                _buildEventCard(context, "Haftalık Top Coin Kralı", "+75,000 Bonus", "4.8K Yayıncı"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, String title, String reward, String participants) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text("Ödül: $reward", style: TextStyle(color: AppTheme.accentGold, fontSize: 9)),
                      Text(" • ", style: TextStyle(color: context.textSecondary, fontSize: 9)),
                      Text(participants, style: TextStyle(color: context.textSecondary, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: context.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
