import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tebrikler! Yeni İlişki Seviyesine Ulaştınız!"), backgroundColor: Colors.green),
      );
      setState(() => _couplePoints = 100);
    } else {
      setState(() => _couplePoints += 50);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❤️ +50 Sevgi Enerjisi Gönderildi!"), backgroundColor: AppColors.primaryPink),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Birliktelik Alanı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: MainBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: AppColors.primaryPink.withOpacity(0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryPink.withOpacity(0.1), blurRadius: 30, spreadRadius: -5),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAvatar(widget.chatData['name'][0], AppColors.primaryPink),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(LucideIcons.heart, color: Colors.redAccent.withOpacity(0.8), size: 36),
                            ),
                            _buildAvatar("A", AppColors.primaryPurple), 
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text("${widget.chatData['name']} ❤️ Alexander", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Text("İlişki Seviyesi: 4", style: TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("İlişki Puanı", style: TextStyle(fontSize: 12, color: Colors.white70)),
                            Text("$_couplePoints / $_targetPoints XP", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_couplePoints / _targetPoints).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPurple]),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: AppColors.primaryPink.withOpacity(0.5), blurRadius: 6)],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleSendLoveEnergy,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: AppColors.primaryPink.withOpacity(0.5))),
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith((states) => AppColors.primaryPink.withOpacity(0.2)),
                            ),
                            icon: const Icon(LucideIcons.heart, color: Colors.pinkAccent, size: 18),
                            label: const Text("Sevgi Enerjisi Gönder (+50 XP)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("İlişki Yol Haritası & Avantajlar", style: TextStyle(color: AppColors.textGray, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ...MockData.relationshipRoadmap.map((step) => _buildRoadmapRow(step)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initial, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Center(
        child: Text(initial, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRoadmapRow(Map<String, dynamic> step) {
    final bool unlocked = step['unlocked'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: unlocked ? AppColors.primaryPink.withOpacity(0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: unlocked ? const LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPurple]) : null,
              color: unlocked ? null : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Text(step['lv'].toString(), style: TextStyle(color: unlocked ? Colors.white : Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(step['label'], style: TextStyle(color: unlocked ? Colors.white : Colors.white54, fontSize: 13, fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: unlocked ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(unlocked ? "Açık" : "Kilitli", style: TextStyle(color: unlocked ? Colors.greenAccent : Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}