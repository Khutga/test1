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
        title: Text("Mesajlar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // ─── DUYURU BANNER ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GlassContainer(
                  padding: const EdgeInsets.all(12),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(LucideIcons.zap, color: AppTheme.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Sistem Duyuruları & PK", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                            Text("Turnuvaları izlemek için tıklayın.", style: TextStyle(color: context.textSecondary, fontSize: 10)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, color: context.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),

              // ─── MESAJ LİSTESİ ───
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 90),
                  physics: const BouncingScrollPhysics(),
                  itemCount: MockData.messagesList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final msg = MockData.messagesList[index];
                    return GlassContainer(
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatData: msg))),
                      child: Row(
                        children: [
                          // Avatar + online dot
                          Stack(
                            children: [
                              GlowAvatar(initial: msg['name'][0], radius: 22),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.card, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),

                          // İçerik
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(msg['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary)),
                                    Text(msg['time'], style: TextStyle(color: context.textSecondary, fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  msg['msg'],
                                  style: TextStyle(
                                    color: msg['unread'] > 0 ? context.textPrimary : context.textSecondary,
                                    fontSize: 12,
                                    fontWeight: msg['unread'] > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    if (msg['soulMatch'] != null) GradientBadge(text: "%${msg['soulMatch']} Uyum", icon: LucideIcons.zap),
                                    if (msg['soulMatch'] != null) const SizedBox(width: 4),
                                    if (msg['coupleLevel'] != null) GradientBadge(text: "Lv.${msg['coupleLevel']}", icon: LucideIcons.heart, color: AppTheme.danger),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Okunmamış badge
                          if (msg['unread'] > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(msg['unread'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
