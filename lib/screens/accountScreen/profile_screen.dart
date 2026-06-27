import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/achivements_screen.dart';
import 'package:nivi/screens/leaderboard_screen.dart';
import 'package:nivi/services/level_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';
import '../coin_shop_screen.dart';
import 'edit_profile_screen.dart';
import '../gift_history_screen.dart';
import '../ajans/agency_screen.dart';
import 'settings_screen.dart';
import 'profilGoster/follow_list_screen.dart';

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

  late int userId;
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    userId = prefs.getInt('kullanici_id') ?? 1;

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

    // LEVEL SİSTEMİ HESAPLAMALARI
    int xp = int.tryParse(userData?['xp_puani']?.toString() ?? '0') ?? 0;
    int userLevel = LevelManager.getLevel(xp);
    double xpProgress = LevelManager.getProgress(xp);
    Color frameColor = LevelManager.getFrameColor(userLevel);

    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 🔥 1. VIP ÇERÇEVELİ PROFİL RESMİ
                Container(
                  padding: EdgeInsets.all(
                    frameColor == Colors.transparent ? 0 : 5,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: frameColor == Colors.transparent
                          ? Colors.transparent
                          : frameColor,
                      width: frameColor == Colors.transparent ? 0 : 3.5,
                    ),
                    boxShadow: frameColor != Colors.transparent
                        ? [
                            BoxShadow(
                              color: frameColor.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : [],
                  ),
                  child: GlowAvatar(
                    initial: isim[0].toUpperCase(),
                    radius: 44,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔥 2. İSİM VE LEVEL ROZETİ
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
                    // Level Rozeti
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: frameColor == Colors.transparent
                            ? AppTheme.accent
                            : frameColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (frameColor == Colors.transparent
                                        ? AppTheme.accent
                                        : frameColor)
                                    .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Lv. $userLevel",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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

                // 🔥 3. PROGRESS BAR (İLERLEME ÇUBUĞU)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Lv. $userLevel",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Lv. ${userLevel + 1}",
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 10,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            frameColor == Colors.transparent
                                ? AppTheme.accent
                                : frameColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$xp / ${LevelManager.getNextLevelXp(xp)} XP",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                UserBadgesRow(
                  userId: int.tryParse(userData?['id']?.toString() ?? '0') ?? 0,
                ),
                const SizedBox(height: 16),

                // TAKİPÇİ - TAKİP EDİLEN İSTATİSTİKLERİ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowListScreen(
                              initialTab: 'followers',
                              userId: int.parse(userId.toString()),
                            ),
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
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowListScreen(
                              initialTab: 'following',
                              userId: int.parse(userId.toString()),
                            ),
                          ),
                        );
                      },
                      child: _buildStatItem(
                        context,
                        _followingCount.toString(),
                        "Takip Edilen",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),
                // 1. COİN BAKİYESİ KARTLARI
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. KART: HARCAMA BAKİYESİ ---
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Harcama Bakiyesi", // (1. Coin)
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // FittedBox: Sayı büyürse taşmasını engeller, fontu küçültür
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$bakiye 🪙",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CoinShopScreen(),
                                    ),
                                  );
                                  _loadProfileData(); // Kendi fonksiyonunuza göre
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Yükle",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12), // İki kart arası boşluk
                    // --- 2. KART: ÇEKİLEBİLİR BAKİYE ---
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Çekilebilir Bakiye", // (2. Coin)
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "$bakiye2 🪙",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Kartların boylarının eşit olması için buraya da buton ekledik
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: OutlinedButton(
                                onPressed: () {
                                  // İleride para çekme ekranına yönlendirebilirsin
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: BorderSide(
                                    color: AppTheme.accentGold.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Çek",
                                  style: TextStyle(
                                    color: AppTheme.accentGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // MENÜ BUTONLARI
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
