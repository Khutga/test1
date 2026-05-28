import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';
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
      _messages.add({"id": DateTime.now().millisecondsSinceEpoch, "text": text, "sender": 'me', "time": 'Şimdi', "isGift": isGift});
      _controller.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  void _showGiftPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Hediye Gönder", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("🪙 $_userCoins", style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.0, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: _giftsList.length,
              itemBuilder: (_, index) {
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(gift['icon'], style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(gift['name'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.textPrimary)),
                        Text("${gift['cost']} Coin", style: TextStyle(fontSize: 9, color: AppTheme.accentGold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GlowAvatar(initial: widget.chatData['name'][0], radius: 16),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chatData['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                    const SizedBox(width: 3),
                    Text("Çevrimiçi", style: TextStyle(fontSize: 9, color: AppTheme.success)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.heart, color: AppTheme.danger, size: 18),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelationshipScreen(chatData: widget.chatData))),
          ),
        ],
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ─── MESAJLAR ───
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) {
                    final m = _messages[index];
                    final isMe = m['sender'] == 'me';
                    final isGift = m['isGift'] == true;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(maxWidth: screenWidth * 0.72),
                        decoration: BoxDecoration(
                          color: isGift
                              ? AppTheme.accentGold.withOpacity(0.15)
                              : isMe
                                  ? AppTheme.accent
                                  : (context.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
                          border: (!isMe && !isGift) ? Border.all(color: context.border) : null,
                          borderRadius: BorderRadius.circular(14).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : null,
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m['text'],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isGift ? FontWeight.w600 : FontWeight.normal,
                                color: isMe && !isGift ? Colors.white : context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m['time'],
                              style: TextStyle(
                                fontSize: 9,
                                color: isMe && !isGift ? Colors.white70 : context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ─── INPUT BAR ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: context.card,
                  border: Border(top: BorderSide(color: context.border.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showGiftPanel,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.gift, color: AppTheme.accentGold, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(fontSize: 13, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Mesaj yaz...",
                          hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.send, color: Colors.white, size: 16),
                      ),
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
