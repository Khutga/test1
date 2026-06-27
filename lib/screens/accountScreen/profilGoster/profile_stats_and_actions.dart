import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/accountScreen/profilGoster/follow_list_screen.dart';
import '../../../core/app_colors.dart'; // Yollarını kendi projene göre düzelt

class ProfileStatsAndActions extends StatelessWidget {
  final int targetUserId; // 🔥 Artık kimin profilinde olduğumuzu biliyoruz
  final int followerCount;
  final int followingCount;
  final bool isFollowing;
  final bool kendiProfili;
  final VoidCallback onToggleFollow;
  final VoidCallback onSendMessage;
  final VoidCallback onSendAnonymous;

  const ProfileStatsAndActions({
    super.key,
    required this.targetUserId,
    required this.followerCount,
    required this.followingCount,
    required this.isFollowing,
    required this.kendiProfili,
    required this.onToggleFollow,
    required this.onSendMessage,
    required this.onSendAnonymous,
  });

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: context.textSecondary),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // İSTATİSTİKLER (Takipçi, Takip Edilen)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowListScreen(
                    initialTab: 'followers',
                    userId: targetUserId, // 🔥 Tıklanan kişinin ID'si gidiyor
                  ),
                ),
              ),
              child: _buildStatItem(context, followerCount.toString(), "Takipçi"),
            ),
            Container(
              width: 1,
              height: 28,
              color: context.border,
              margin: const EdgeInsets.symmetric(horizontal: 40),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FollowListScreen(
                    initialTab: 'following',
                    userId: targetUserId, // 🔥 Tıklanan kişinin ID'si gidiyor
                  ),
                ),
              ),
              child: _buildStatItem(context, followingCount.toString(), "Takip Edilen"),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // AKSİYON BUTONLARI (Kendi profili değilse göster)
        if (!kendiProfili)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggleFollow,
                  icon: Icon(
                    isFollowing ? LucideIcons.userCheck : LucideIcons.userPlus,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    isFollowing ? "Takipte" : "Takip Et",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isFollowing ? Colors.grey[700] : AppTheme.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSendMessage,
                  icon: const Icon(
                    LucideIcons.messageCircle,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "Mesaj At",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSendAnonymous,
                  icon: const Icon(
                    LucideIcons.searchAlert,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "Anonim",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.accentLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}