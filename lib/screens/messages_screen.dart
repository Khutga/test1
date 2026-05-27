import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';
import 'chat_screen.dart';
import 'announcements_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Mesajlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      ),
      body: MainBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                gradientColors: [AppColors.primaryPurple.withOpacity(0.2), Colors.black26],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primaryPurple.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(LucideIcons.zap, color: AppColors.primaryPurple, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sistem Duyuruları & PK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text("Turnuvaları izlemek için tıklayın.", style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: Colors.white54, size: 20),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 100),
                physics: const BouncingScrollPhysics(),
                itemCount: MockData.messagesList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = MockData.messagesList[index];
                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(chatData: msg))),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            GlowAvatar(initial: msg['name'][0], radius: 26, color: AppColors.primaryPink),
                            Positioned(
                              bottom: 2, right: 2,
                              child: Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(msg['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                  Text(msg['time'], style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                msg['msg'],
                                style: TextStyle(color: msg['unread'] > 0 ? Colors.white : Colors.white54, fontSize: 13, fontWeight: msg['unread'] > 0 ? FontWeight.bold : FontWeight.normal),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (msg['soulMatch'] != null) GradientBadge(text: "%${msg['soulMatch']} Uyum", icon: LucideIcons.zap, color: AppColors.primaryPurple),
                                  const SizedBox(width: 8),
                                  if (msg['coupleLevel'] != null) GradientBadge(text: "Lv.${msg['coupleLevel']}", icon: LucideIcons.heart, color: AppColors.primaryPink),
                                ],
                              )
                            ],
                          ),
                        ),
                        if (msg['unread'] > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPurple]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.primaryPink.withOpacity(0.4), blurRadius: 8)],
                            ),
                            child: Text(msg['unread'].toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}