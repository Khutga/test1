import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

class RelationshipScreen extends StatefulWidget {
  const RelationshipScreen({super.key});

  @override
  State<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  int _couplePoints = 850;
  final int _targetPoints = 1000;

  void _handleSendLoveEnergy() {
    if (_couplePoints >= _targetPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Təbriklər! Yeni Birliktelik Levelinə Çatdınız!"), backgroundColor: Colors.green),
      );
      setState(() => _couplePoints = 100);
    } else {
      setState(() => _couplePoints += 50);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❤️ +50 Sevgi Enerjisi Göndərildi!"), backgroundColor: AppColors.primaryPink),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Birliktelik Alanı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Çift Bilgisi ve Progress Bar
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPink.withOpacity(0.3), AppColors.primaryPurple.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(AppColors.primaryPink),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(LucideIcons.heart, color: AppColors.primaryPink, size: 32),
                      ),
                      _buildAvatar(AppColors.primaryPurple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Melis ❤️ Alexander", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Birliktelik Leveli: 4", style: TextStyle(color: AppColors.primaryPurple, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("İlişki Puanı", style: TextStyle(fontSize: 10, color: AppColors.textGray)),
                      Text("$_couplePoints / $_targetPoints XP", style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _couplePoints / _targetPoints,
                    backgroundColor: Colors.black54,
                    color: AppColors.primaryPink,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleSendLoveEnergy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      icon: const Icon(LucideIcons.heart, color: Colors.white, size: 16),
                      label: const Text("Sevgi Enerjisi Göndər (+50 XP)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Yol Haritası (Roadmap)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Sevgililik Yol Haritası & Avantajlar", style: TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ...MockData.relationshipRoadmap.map((step) => _buildRoadmapRow(step)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }

  Widget _buildRoadmapRow(Map<String, dynamic> step) {
    final bool unlocked = step['unlocked'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? AppColors.primaryPink : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Text(step['lv'].toString(), style: TextStyle(color: unlocked ? Colors.white : Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(step['label'], style: TextStyle(color: unlocked ? Colors.white : AppColors.textGray, fontSize: 12)),
          ),
          Text(unlocked ? "Açık" : "Kilitli", style: TextStyle(color: unlocked ? Colors.green : AppColors.textGray, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}