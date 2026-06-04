import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';

class RelationshipScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  const RelationshipScreen({super.key, required this.chatData});

  @override
  State<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  int _kendiId = 1;
  int _karsiId = 0;

  int _couplePoints = 0;
  int _currentLevel = 1;
  final int _pointsPerLevel = 1000; // Her 1000 puanda 1 seviye atlar

  bool _isLoading = true;
  String _kendiIsmim = "Sen";
  int _userCoins = 0; // 🔥 YENİ: Kullanıcının coin bakiyesini tutacak değişken

  @override
  void initState() {
    super.initState();
    _karsiId = widget.chatData['id']; // Chat ekranından gelen kişinin ID'si
    _loadRelationshipData();
  }

  Future<void> _loadRelationshipData() async {
    final prefs = await SharedPreferences.getInstance();
    _kendiId = prefs.getInt('kullanici_id') ?? 1;

    // Kendi ismimizi ve BAKİYEMİZİ çekelim
    final userRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': _kendiId},
    );
    if (userRes.basarili && userRes.veri.isNotEmpty) {
      _kendiIsmim = userRes.veri.first['isim'] ?? 'Sen';
      // 🔥 YENİ: Bakiyeyi çekip double.tryParse ile güvenli şekilde int'e çeviriyoruz
      _userCoins =
          (double.tryParse(
                    userRes.veri.first['birinci_coin_bakiye'].toString(),
                  ) ??
                  0.0)
              .toInt();
    }

    // Veritabanında bu iki kişi arasındaki ilişki kaydını ara
    int kucukId = _kendiId < _karsiId ? _kendiId : _karsiId;
    int buyukId = _kendiId > _karsiId ? _kendiId : _karsiId;

    final relRes = await SqlServis.cek(
      tablo: 'sohbet_iliskileri',
      sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
    );

    if (relRes.basarili && relRes.veri.isNotEmpty) {
      setState(() {
        _couplePoints =
            int.tryParse(relRes.veri.first['iliski_puani'].toString()) ?? 0;
        _currentLevel =
            int.tryParse(relRes.veri.first['seviye'].toString()) ?? 1;
        _isLoading = false;
      });
    } else {
      // Eğer daha önce hiç kayıt yoksa, sıfırdan oluştur
      await SqlServis.ekle(
        tablo: 'sohbet_iliskileri',
        veriler: {
          'kullanici1_id': kucukId,
          'kullanici2_id': buyukId,
          'iliski_puani': 0,
          'seviye': 1,
        },
      );
      setState(() {
        _couplePoints = 0;
        _currentLevel = 1;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSendLoveEnergy() async {
    // 🔥 YENİ: Bakiye Kontrolü (50 Coin gerekli)
    if (_userCoins < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Yetersiz Bakiye! Sevgi enerjisi göndermek için 50 Coin gereklidir.",
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() {
      _userCoins -= 50; // Bakiyeden düş
      _couplePoints += 50; // XP ekle
    });

    // Seviye atlama kontrolü
    int yeniSeviye = (_couplePoints / _pointsPerLevel).floor() + 1;
    bool seviyeAtladi = yeniSeviye > _currentLevel;

    if (seviyeAtladi) {
      _currentLevel = yeniSeviye;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Seviye $yeniSeviye'ye ulaştınız! Yeni özellikler açıldı.",
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❤️ 50 Coin Harcandı (+50 XP)"),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    }

    // 🔥 Veritabanını güncelle: Hem yeni ilişki puanı hem de kullanıcının azalan bakiyesi
    int kucukId = _kendiId < _karsiId ? _kendiId : _karsiId;
    int buyukId = _kendiId > _karsiId ? _kendiId : _karsiId;

    // 1. XP ve Seviyeyi güncelle
    await SqlServis.guncelle(
      tablo: 'sohbet_iliskileri',
      veriler: {'iliski_puani': _couplePoints, 'seviye': _currentLevel},
      sartlar: {'kullanici1_id': kucukId, 'kullanici2_id': buyukId},
    );

    // 2. Kullanıcının coin bakiyesini güncelle
    await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {'birinci_coin_bakiye': _userCoins},
      sartlar: {'id': _kendiId},
    );
  }

  @override
  Widget build(BuildContext context) {
    int targetPoints = _currentLevel * _pointsPerLevel;
    int currentProgress =
        _couplePoints - ((_currentLevel - 1) * _pointsPerLevel);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Birliktelik",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ─── COUPLE CARD ───
                      GlassContainer(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GlowAvatar(
                                  initial: widget.chatData['name'][0]
                                      .toUpperCase(),
                                  radius: 24,
                                  color: AppTheme.danger,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    LucideIcons.heart,
                                    color: AppTheme.danger.withOpacity(0.7),
                                    size: 28,
                                  ),
                                ),
                                GlowAvatar(
                                  initial: _kendiIsmim[0].toUpperCase(),
                                  radius: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "${widget.chatData['name']} ❤️ $_kendiIsmim",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "İlişki Seviyesi: $_currentLevel",
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Progress Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "İlişki Puanı",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textSecondary,
                                  ),
                                ),
                                Text(
                                  "$_couplePoints / $targetPoints XP",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (currentProgress / _pointsPerLevel)
                                    .clamp(0.0, 1.0),
                                backgroundColor: context.border,
                                color: AppTheme.accent,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Send button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _handleSendLoveEnergy,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide(
                                    color: AppTheme.accent.withOpacity(0.3),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  LucideIcons.heart,
                                  color: AppTheme.danger,
                                  size: 16,
                                ),
                                // 🔥 YENİ: Buton yazısı güncellendi
                                label: Text(
                                  "Sevgi Enerjisi Gönder (50 Coin = +50 XP)",
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── ROADMAP (DİNAMİK KİLİT AÇILIMI) ───
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Yol Haritası",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRoadmapRow(
    BuildContext context,
    Map<String, dynamic> step,
    int currentLevel,
  ) {
    // Kilit durumunu veritabanından gelen mevcut seviyeye göre belirliyoruz
    final int stepLevel = step['lv'];
    final bool unlocked = currentLevel >= stepLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.accent
                    : context.textSecondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                stepLevel.toString(),
                style: TextStyle(
                  color: unlocked ? Colors.white : context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step['label'],
                style: TextStyle(
                  color: unlocked ? context.textPrimary : context.textSecondary,
                  fontSize: 11,
                  fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (unlocked ? AppTheme.success : context.textSecondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                unlocked ? "Açık" : "Kilitli",
                style: TextStyle(
                  color: unlocked ? AppTheme.success : context.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
