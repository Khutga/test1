import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/admin_widgets.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class AyarlarTab extends StatefulWidget {
  const AyarlarTab({super.key});
  @override
  State<AyarlarTab> createState() => _AyarlarTabState();
}

class _AyarlarTabState extends State<AyarlarTab> {
  List<Map<String, dynamic>> _ayarlar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'sistem_ayarlari');
    if (res.basarili) _ayarlar = res.veri;
    setState(() => _isLoading = false);
  }
  Widget _ayarAlani(String etiket, String ayarAdi, String mevcutDeger) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: mevcutDeger,
        decoration: InputDecoration(labelText: etiket),
        onFieldSubmitted: (val) async {
          await SqlServis.guncelle(
            tablo: 'sistem_ayarlari',
            veriler: {'ayar_degeri': val},
            sartlar: {'ayar_adi': ayarAdi}
          );
          
          SqlServis.auraOnbellekTemizle(); 
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ayar güncellendi!")));
            setState(() {});
          }
        },
      ),
    );
  }
  void _duzenleDialog(Map<String, dynamic> ayar) {
    final degerC = TextEditingController(
      text: ayar['ayar_degeri']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ayar Düzenle",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ayar['ayar_adi'],
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            adminField("Yeni Değer", degerC),
            const SizedBox(height: 16),
            PremiumButton(
              text: "Kaydet",
              icon: LucideIcons.save,
              onPressed: () async {
                if (degerC.text.isEmpty) return;
                await SqlServis.guncelle(
                  tablo: 'sistem_ayarlari',
                  veriler: {'ayar_degeri': degerC.text.trim()},
                  sartlar: {'ayar_adi': ayar['ayar_adi']},
                );
                Navigator.pop(ctx);
                _yukle();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_ayarlar.isEmpty)
      return Center(
        child: Text(
          "Kayıtlı sistem ayarı yok.",
          style: TextStyle(color: context.textSecondary),
        ),
      );

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ayarlar.length,
        itemBuilder: (_, i) {
          final a = _ayarlar[i];
          String adi = a['ayar_adi'] ?? '';
          String degeri = a['ayar_degeri'] ?? '';

          String gosterilenAd = adi;
          if (adi == 'ajans_komisyon_orani') {
            gosterilenAd = "Ajans Kesinti Oranı (%)";
          } else if (adi == 'iliski_seviye_katsayisi') {
            gosterilenAd = "Seviye Atlama Sınırı (XP)";
          } else if (adi == 'mesaj_basina_xp') {
            gosterilenAd = "Mesaj Başına Kazanılan XP";
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.settings,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gosterilenAd,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          "Veritabanı Anahtarı: $adi",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      degeri,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(
                      LucideIcons.edit2,
                      size: 18,
                      color: context.textSecondary,
                    ),
                    onPressed: () => _duzenleDialog(a),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
