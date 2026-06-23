import 'dart:async'; // Timer için eklendi
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/achivements_screen.dart';
import 'package:nivi/screens/leaderboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';
import '../coin_shop_screen.dart';
import 'edit_profile_screen.dart';
import '../gift_history_screen.dart';
import '../ajans/agency_screen.dart';
import 'settings_screen.dart';
import 'follow_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _followerCount = 0;
  int _followingCount = 0;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _loadProfileData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final response = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': userId},
    );

    if (!mounted) return;
    if (response.basarili && response.veri.isNotEmpty) {
      setState(() => userData = response.veri.first);
    }

    final followerRes = await SqlServis.cek(
      tablo: 'takipciler',
      sartlar: {'takip_edilen_id': userId},
    );

    if (!mounted) return;
    if (followerRes.basarili) {
      setState(() => _followerCount = followerRes.veri.length);
    }

    final followingRes = await SqlServis.cek(
      tablo: 'takipciler',
      sartlar: {'takip_eden_id': userId},
    );

    if (!mounted) return;
    if (followingRes.basarili) {
      setState(() => _followingCount = followingRes.veri.length);
    }

    // İlk açılıştaki yükleme ekranını kaldır
    if (isLoading && mounted) {
      setState(() => isLoading = false);
    }
  }

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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    // Veritabanı değerleri
    String isim = userData?['kullanici_adi'] ?? "Misafir";
    String bakiye = userData?['birinci_coin_bakiye']?.toString() ?? "0";
    String bakiye2 = userData?['ikinci_coin_bakiye']?.toString() ?? "0";
    String bio = userData?['biyografi'] ?? "Merhaba, FiFi Live'dayım!";
    int xp = int.tryParse(userData?['xp_puani']?.toString() ?? '0') ?? 0;
    int seviye = (xp / 100).floor() + 1;

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GlowAvatar(
                  initial: isim[0].toUpperCase(),
                  radius: 44,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isim,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.edit2,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                        _loadProfileData();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                UserBadgesRow(
                  userId: int.tryParse(userData?['id']?.toString() ?? '0') ?? 0,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FollowListScreen(initialTab: 'followers'),
                          ),
                        );
                      },
                      child: _buildStatItem(
                        context,
                        _followerCount.toString(),
                        "Takipçi",
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.border,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const FollowListScreen(initialTab: 'following'),
                          ),
                        );
                      },
                      child: _buildStatItem(
                        context,
                        _followingCount.toString(),
                        "Takip Edilen",
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: context.border,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),

                    _buildStatItem(context, "Lv.$seviye", "Seviye"),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Birinci Coin Bakiye",
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$bakiye Coin",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CoinShopScreen(),
                            ),
                          );
                          _loadProfileData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Yükle",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "İkinci Coin Bakiye",
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$bakiye2 Coin",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CoinShopScreen(),
                            ),
                          );
                          _loadProfileData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          "Yükle",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                MenuActionTile(
                  icon: LucideIcons.gift,
                  label: "Hediye Geçmişi",
                  iconColor: AppTheme.danger,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GiftHistoryScreen(),
                    ),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.activity,
                  label: "Ajans Sistemi",
                  iconColor: AppTheme.success,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgencyMainScreen()),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.trophy,
                  label: "Başarımlar",
                  iconColor: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.medal,
                  label: "Liderlik Tablosu",
                  iconColor: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  ),
                ),
                MenuActionTile(
                  icon: LucideIcons.settings,
                  label: "Ayarlar",
                  iconColor: AppTheme.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
