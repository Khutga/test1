import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';

class RelationshipScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const RelationshipScreen({super.key, required this.chatData});

  @override
  State<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  int _couplePoints = 850;
  final int _targetPoints = 1000;

  void _handleSendLoveEnergy() {
    if (_couplePoints >= _targetPoints) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Yeni seviyeye ulaştınız!"), backgroundColor: AppTheme.success));
      setState(() => _couplePoints = 100);
    } else {
      setState(() => _couplePoints += 50);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("❤️ +50 XP"), backgroundColor: AppTheme.accent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Birliktelik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
        centerTitle: true,
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ─── COUPLE CARD ───
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlowAvatar(initial: widget.chatData['name'][0], radius: 24, color: AppTheme.danger),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(LucideIcons.heart, color: AppTheme.danger.withOpacity(0.7), size: 28),
                          ),
                          const GlowAvatar(initial: "A", radius: 24),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text("${widget.chatData['name']} ❤️ Alexander", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text("İlişki Seviyesi: 4", style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 18),

                      // Progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("İlişki Puanı", style: TextStyle(fontSize: 10, color: context.textSecondary)),
                          Text("$_couplePoints / $_targetPoints XP", style: TextStyle(fontSize: 10, color: context.textPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_couplePoints / _targetPoints).clamp(0.0, 1.0),
                          backgroundColor: context.border,
                          color: AppTheme.accent,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleSendLoveEnergy,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(LucideIcons.heart, color: AppTheme.danger, size: 16),
                          label: Text("Sevgi Enerjisi Gönder (+50 XP)", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── ROADMAP ───
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Yol Haritası", style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
                ...MockData.relationshipRoadmap.map((step) => _buildRoadmapRow(context, step)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoadmapRow(BuildContext context, Map<String, dynamic> step) {
    final bool unlocked = step['unlocked'];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked ? AppTheme.accent : context.textSecondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Text(step['lv'].toString(), style: TextStyle(color: unlocked ? Colors.white : context.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(step['label'], style: TextStyle(color: unlocked ? context.textPrimary : context.textSecondary, fontSize: 11, fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (unlocked ? AppTheme.success : context.textSecondary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(unlocked ? "Açık" : "Kilitli", style: TextStyle(color: unlocked ? AppTheme.success : context.textSecondary, fontSize: 8, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
