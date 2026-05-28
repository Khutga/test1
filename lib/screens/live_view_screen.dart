import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';

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
    setState(() {
      _pkPercentage = (_pkPercentage + (giftType == 'Dragon' ? 0.15 : giftType == 'Yacht' ? 0.08 : 0.02)).clamp(0.0, 1.0);
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _giftEffect = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Placeholder
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.flame, color: Colors.white24, size: 48),
                const SizedBox(height: 12),
                Text("PK Simülasyonu\n(${widget.streamData['name']})", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12, right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 12, backgroundColor: Colors.white24),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.streamData['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          const Text("Lv.42", style: TextStyle(fontSize: 8, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ),

          // PK Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Biz: ${(_pkPercentage * 120).toInt()} XP", style: const TextStyle(fontSize: 9, color: Colors.blue)),
                      const Text("PK", style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.w800)),
                      Text("Rakip: ${((1 - _pkPercentage) * 120).toInt()} XP", style: const TextStyle(fontSize: 9, color: Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: _pkPercentage, backgroundColor: Colors.red, color: Colors.blue, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, left: 12, right: 12, top: 16),
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black, Colors.transparent])),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGiftBtn("🐲", "Dragon", "25K", Colors.red, () => _handleSendGift('Dragon')),
                      _buildGiftBtn("🛳️", "Yacht", "8.5K", Colors.cyan, () => _handleSendGift('Yacht')),
                      _buildGiftBtn("❤️", "Kalp", "10", Colors.pink, () => _handleSendGift('Heart')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Sohbete katıl...",
                            hintStyle: const TextStyle(fontSize: 11, color: Colors.white54),
                            filled: true, fillColor: Colors.black45,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.send, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Gift effect overlay
          if (_giftEffect != null)
            Positioned.fill(
              child: Container(
                color: _giftEffect == 'Dragon' ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.15),
                child: Center(
                  child: Text(
                    _giftEffect == 'Dragon' ? "🐲" : _giftEffect == 'Yacht' ? "🛳️" : "❤️",
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGiftBtn(String emoji, String title, String cost, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(10)),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
            Text(cost, style: const TextStyle(fontSize: 8, color: Colors.amber)),
          ],
        ),
      ),
    );
  }
}
