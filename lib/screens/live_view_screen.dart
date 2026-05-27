import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';

class LiveViewScreen extends StatefulWidget {
  final Map<String, dynamic> streamData;

  const LiveViewScreen({super.key, required this.streamData});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  String? _giftEffect;
  double _pkPercentage = 0.5; 

  void _handleSendGift(String giftType) {
    setState(() => _giftEffect = giftType);
    
    if (giftType == 'Dragon') {
      setState(() => _pkPercentage = (_pkPercentage + 0.15).clamp(0.0, 1.0));
    } else if (giftType == 'Yacht') {
      setState(() => _pkPercentage = (_pkPercentage + 0.08).clamp(0.0, 1.0));
    } else {
      setState(() => _pkPercentage = (_pkPercentage + 0.02).clamp(0.0, 1.0));
    }

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _giftEffect = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MainBackground(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.flame, color: AppColors.primaryPink, size: 64),
                  const SizedBox(height: 16),
                  Text("PK Yayını Tam Ekran Simulyasiyası\n(${widget.streamData['name']})", 
                    textAlign: TextAlign.center, 
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
        
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 14, backgroundColor: AppColors.primaryPink),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.streamData['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const Text("Lv.42 Yıldız", style: TextStyle(fontSize: 9, color: AppColors.primaryPink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  )
                ],
              ),
            ),
        
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Bizim: ${(_pkPercentage * 120).toInt()} XP", style: const TextStyle(fontSize: 10, color: Colors.blue)),
                        const Text("PK BATTLE", style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                        Text("Rəqib: ${((1 - _pkPercentage) * 120).toInt()} XP", style: const TextStyle(fontSize: 10, color: AppColors.primaryPink)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _pkPercentage,
                      backgroundColor: Colors.red,
                      color: Colors.blue,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                ),
              ),
            ),
        
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16, top: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGiftBtn("🐲", "Dragon", "25K Coin", Colors.red, () => _handleSendGift('Dragon')),
                        _buildGiftBtn("🛳️", "Yacht", "8.5K Coin", Colors.cyan, () => _handleSendGift('Yacht')),
                        _buildGiftBtn("❤️", "Ürək", "10 Coin", AppColors.primaryPink, () => _handleSendGift('Heart')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Söhbətə qoşulun...",
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black45,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.white10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.send, size: 16),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
        
            if (_giftEffect != null)
              Positioned.fill(
                child: Container(
                  color: _giftEffect == 'Dragon' ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.2),
                  child: Center(
                    child: Text(
                      _giftEffect == 'Dragon' ? "🐲" : _giftEffect == 'Yacht' ? "🛳️" : "❤️",
                      style: const TextStyle(fontSize: 120),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftBtn(String emoji, String title, String cost, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            Text(cost, style: const TextStyle(fontSize: 9, color: Colors.amber)),
          ],
        ),
      ),
    );
  }
}