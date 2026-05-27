import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Mesajlar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sistem Elanları Banner'ı
            InkWell(
              onTap: () {
                // TODO: AnnouncementsScreen'e git
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryPurple.withOpacity(0.4), Colors.black26],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.zap, color: AppColors.primaryPurple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📢 Sistem Elanları & PK Duyuruları", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("Turnirləri izləmək və elan vermək üçün klikləyin.", style: TextStyle(color: AppColors.textGray, fontSize: 10)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.arrowUpRight, color: AppColors.textGray, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Mesaj Listesi
            Expanded(
              child: ListView.separated(
                itemCount: MockData.messagesList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final msg = MockData.messagesList[index];
                  return _buildMessageTile(context, msg);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, Map<String, dynamic> msg) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatData: msg)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderWhite),
        ),
        child: Row(
          children: [
            // Avatar ve Çevrimiçi Noktası
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryPink.withOpacity(0.5),
                  child: Text(msg['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(msg['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(msg['time'], style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg['msg'],
                    style: const TextStyle(color: AppColors.textGray, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (msg['soulMatch'] != null)
                        _buildBadge(LucideIcons.zap, "%${msg['soulMatch']} Uyum", AppColors.primaryPurple),
                      const SizedBox(width: 6),
                      if (msg['coupleLevel'] != null)
                        _buildBadge(LucideIcons.heart, "Lv.${msg['coupleLevel']}", AppColors.primaryPink),
                    ],
                  )
                ],
              ),
            ),
            if (msg['unread'] > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPurple]),
                  shape: BoxShape.circle,
                ),
                child: Text(msg['unread'].toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 2),
          Text(text, style: TextStyle(color: color, fontSize: 9)),
        ],
      ),
    );
  }
}