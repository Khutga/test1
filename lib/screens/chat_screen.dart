import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';
import 'relationship_screen.dart'; 

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const ChatScreen({super.key, required this.chatData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  double _heartX = 20.0;
  double _heartY = 100.0;
  
  int _userCoins = 54200; 

  final List<Map<String, dynamic>> _messages = [
    {"id": 1, "text": "Merhaba, yayınıma geldiğin için teşekkürler!", "sender": 'them', "time": '14:20', "isGift": false}
  ];

  final List<Map<String, dynamic>> _giftsList = [
    {"icon": "🌹", "name": "Gül", "cost": 10},
    {"icon": "🐻", "name": "Ayıcık", "cost": 50},
    {"icon": "💍", "name": "Yüzük", "cost": 500},
    {"icon": "👑", "name": "Taç", "cost": 1000},
    {"icon": "🛳️", "name": "Yacht", "cost": 8500},
  ];

  void _sendMessage({String? textOverride, bool isGift = false}) {
    final text = textOverride ?? _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "text": text,
        "sender": 'me',
        "time": 'Şimdi',
        "isGift": isGift,
      });
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _showGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withOpacity(0.8),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Hediye Gönder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text("🪙 $_userCoins", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: _giftsList.length,
                  itemBuilder: (context, index) {
                    final gift = _giftsList[index];
                    return InkWell(
                      onTap: () {
                        if (_userCoins >= gift['cost']) {
                          setState(() => _userCoins -= gift['cost'] as int);
                          Navigator.pop(ctx);
                          _sendMessage(textOverride: "Sana bir ${gift['name']} ${gift['icon']} gönderdi!", isGift: true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz Coin!")));
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(gift['icon'], style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(gift['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text("${gift['cost']} Coin", style: const TextStyle(fontSize: 10, color: Colors.amber)),
                          ],
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background.withOpacity(0.9),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryPink.withOpacity(0.5),
              child: Text(widget.chatData['name'][0], style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chatData['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4)])),
                    const SizedBox(width: 4),
                    const Text("Çevrimiçi", style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
      body: MainBackground(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMe = m['sender'] == 'me';
                      final isGift = m['isGift'] == true;
        
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: screenSize.width * 0.75),
                          decoration: BoxDecoration(
                            gradient: isGift 
                                ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                                : isMe ? const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]) : null,
                            color: isMe || isGift ? null : Colors.white.withOpacity(0.05),
                            border: isMe || isGift ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: isMe ? const Radius.circular(4) : null,
                              bottomLeft: !isMe ? const Radius.circular(4) : null,
                            ),
                            boxShadow: isGift ? [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)] : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m['text'], style: TextStyle(fontSize: 14, fontWeight: isGift ? FontWeight.bold : FontWeight.normal, color: isGift ? Colors.black87 : Colors.white)),
                              const SizedBox(height: 4),
                              Text(m['time'], style: TextStyle(fontSize: 9, color: isGift ? Colors.black54 : (isMe ? Colors.white70 : AppColors.textGray))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.8),
                        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: _showGiftPanel,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.amber.withOpacity(0.3))),
                              child: const Icon(LucideIcons.gift, color: Colors.amber, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Mesaj yaz...",
                                hintStyle: const TextStyle(color: AppColors.textGray),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () => _sendMessage(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPurple]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryPink.withOpacity(0.4), blurRadius: 8)]),
                              child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
        
            Positioned(
              left: _heartX,
              top: _heartY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _heartX = (_heartX + details.delta.dx).clamp(0.0, screenSize.width - 60.0);
                    _heartY = (_heartY + details.delta.dy).clamp(0.0, screenSize.height - 180.0);
                  });
                },
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => RelationshipScreen(chatData: widget.chatData)));
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Colors.redAccent, AppColors.primaryPink]),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.heart, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}