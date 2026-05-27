import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text("Özel Etkinlikler", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: MainBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bonus Coin qazanmaq və profilinizi önə çıxarmaq üçün aktiv turnirlərə Katılun.",
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryPink, AppColors.primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primaryPurple),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryPurple.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SEZONLUK AJANS TURNUVASI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text("Həftəlik ən çox coin qazanan ajanslara tam \$10,000 mükafat fondu!", style: TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                          child: const Text("Gece 00:00'da Sıfırlanır", style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Turnirə Katıldunuz!"), backgroundColor: Colors.green));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Katıl", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildEventCard("Ən Aktiv Sevgili Challenge", "Premium Cütlük Badge-i", "1.2K Cütlük"),
              _buildEventCard("Həftəlik Top Coin Kralı", "+75,000 Star Bonus", "4.8K Yayıncı"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(String title, String reward, String participants) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderWhite),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("Mükafat: $reward", style: const TextStyle(color: Colors.amber, fontSize: 10)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text("•", style: TextStyle(color: AppColors.textGray))),
                    Text(participants, style: const TextStyle(color: AppColors.textGray, fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          const Icon(LucideIcons.moreVertical, color: AppColors.textGray, size: 16),
        ],
      ),
    );
  }
}