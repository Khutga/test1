import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Map<String, dynamic>> basarimlar = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> kullaniciBasarimlari = [];

  Future<void> _loadAchievements() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    var userRes = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': userId},
    );
    if (userRes.basarili && userRes.veri.isNotEmpty) {
      userData = userRes.veri.first;
    }

    var kbRes = await SqlServis.cek(
      tablo: Tablolar.kullaniciBasarimlari,
      sartlar: {'kullanici_id': userId},
    );
    if (kbRes.basarili) {
      kullaniciBasarimlari = kbRes.veri;
    }

    var res = await SqlServis.cek(
      tablo: Tablolar.basarimlar,
      sartlar: {'durum': 'aktif'},
    );

    if (mounted) {
      setState(() {
        if (res.basarili) basarimlar = res.veri;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Başarımlar", style: TextStyle(color: context.textPrimary)),
        backgroundColor: Colors.transparent,
      ),
      body: MainBackground(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              )
            : basarimlar.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.trophy,
                      size: 64,
                      color: context.textSecondary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz bir başarım bulunmuyor.",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: basarimlar.length,
                itemBuilder: (context, index) {
                  var b = basarimlar[index];
                  int basarimId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
                  int hedefDeger =
                      int.tryParse(b['hedef_deger']?.toString() ?? '1') ?? 1;
                  int mevcutIlerleme = 0;

                  if (b['basarim_tipi'] == 'gunluk_giris' ||
                      b['basarim_tipi'] == 'haftalik_seri') {
                    mevcutIlerleme =
                        int.tryParse(
                          userData?['giris_serisi']?.toString() ?? '0',
                        ) ??
                        0;
                  } else {
                    var kb = kullaniciBasarimlari
                        .where((element) => element['basarim_id'] == basarimId)
                        .toList();
                    if (kb.isNotEmpty) {
                      mevcutIlerleme =
                          int.tryParse(
                            kb.first['ilerleme']?.toString() ?? '0',
                          ) ??
                          0;
                    }
                  }

                  if (mevcutIlerleme > hedefDeger) mevcutIlerleme = hedefDeger;

                  bool oncedenAlindi = kullaniciBasarimlari.any(
                    (kb) =>
                        kb['basarim_id'] == basarimId &&
                        (kb['tamamlandi_mi'] == '1' ||
                            kb['tamamlandi_mi'] == 1 ||
                            kb['tamamlandi_mi'] == true),
                  );
                  double progress = (mevcutIlerleme / hedefDeger).clamp(
                    0.0,
                    1.0,
                  );
                  bool tamamlandi =
                      mevcutIlerleme >= hedefDeger && !oncedenAlindi;

                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                b['basarim_tipi'] == 'gunluk_giris' ||
                                        b['basarim_tipi'] == 'haftalik_seri'
                                    ? LucideIcons.calendar
                                    : LucideIcons.trophy,
                                color: AppTheme.accentGold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b['baslik'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b['aciklama'] ?? '',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.coins,
                                    color: AppTheme.accentGold,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "+${b['odul_coin']}",
                                    style: const TextStyle(
                                      color: AppTheme.accentGold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "İlerleme",
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        "$mevcutIlerleme / $hedefDeger",
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: context.card.withOpacity(
                                        0.5,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        tamamlandi
                                            ? Colors.green
                                            : AppTheme.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tamamlandi
                                    ? AppTheme.accentGold
                                    : context.card.withOpacity(0.1),
                                foregroundColor: tamamlandi
                                    ? Colors.white
                                    : context.textSecondary,
                                elevation: tamamlandi ? 4 : 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: tamamlandi
                                        ? Colors.transparent
                                        : context.textSecondary.withOpacity(
                                            0.3,
                                          ),
                                  ),
                                ),
                              ),
                             onPressed: tamamlandi ? () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final String uId = (prefs.getInt('kullanici_id') ?? 1).toString();

                                    var guncelDb = await SqlServis.cek(
                                      tablo: 'hesaplar', 
                                      sartlar: {'id': uId}
                                    );
                                    
                                    if (!guncelDb.basarili || guncelDb.veri.isEmpty) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Sunucudan bakiye okunamadı, işlem iptal edildi.")),
                                      );
                                      return;
                                    }

                                    String? bakiyeStr = guncelDb.veri.first['birinci_coin_bakiye']?.toString();
                                    double? mevcutParaDouble = bakiyeStr != null ? double.tryParse(bakiyeStr) : null;
                                    
                                    if (mevcutParaDouble == null) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Bakiye formatı hatalı, işlem durduruldu.")),
                                      );
                                      return;
                                    }

                                    int mevcutPara = mevcutParaDouble.toInt();
                                    int odul = int.tryParse(b['odul_coin']?.toString() ?? '0') ?? 0;
                                    int eklenecekPara = mevcutPara + odul;

                                    await SqlServis.guncelle(
                                      tablo: 'hesaplar',
                                      veriler: {'birinci_coin_bakiye': eklenecekPara.toString()},
                                      sartlar: {'id': uId},
                                    );

                                    var kbSorgu = kullaniciBasarimlari.where((kb) => kb['basarim_id'] == basarimId).toList();
                                    
                                    if (kbSorgu.isNotEmpty) {
                                      await SqlServis.guncelle(
                                        tablo: Tablolar.kullaniciBasarimlari,
                                        veriler: {'tamamlandi_mi': "1"},
                                        sartlar: {'id': kbSorgu.first['id'].toString()},
                                      );
                                    } else {
                                      await SqlServis.ekle(
                                        tablo: Tablolar.kullaniciBasarimlari,
                                        veriler: {
                                          'kullanici_id': uId,
                                          'basarim_id': basarimId.toString(),
                                          'ilerleme': mevcutIlerleme.toString(),
                                          'tamamlandi_mi': "1",
                                        },
                                      );
                                    }
                                    
                                    _loadAchievements();
                                  } : null,

                              child: Text(
                                oncedenAlindi
                                    ? "Alındı"
                                    : (tamamlandi ? "Al" : "Devam Et"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
