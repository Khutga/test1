import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/admin_widgets.dart';
import '../../../core/app_colors.dart';
import '../../../services/sql_servis.dart';
import '../../../widgets/custom_widgets.dart';

class IliskilerTab extends StatefulWidget {
  const IliskilerTab({super.key});
  @override
  State<IliskilerTab> createState() => _IliskilerTabState();
}

class _IliskilerTabState extends State<IliskilerTab> {
  List<Map<String, dynamic>> _iliskiler = [];
  bool _isLoading = true;
  final Map<int, String> _isimCache = {};

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'sohbet_iliskileri');
    if (res.basarili) {
      _iliskiler = res.veri;
      _iliskiler.sort((a, b) {
        int pa = int.tryParse(a['iliski_puani'].toString()) ?? 0;
        int pb = int.tryParse(b['iliski_puani'].toString()) ?? 0;
        return pb.compareTo(pa);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<String> _isimCek(int id) async {
    if (_isimCache.containsKey(id)) return _isimCache[id]!;
    final res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': id});
    String isim = (res.basarili && res.veri.isNotEmpty) ? (res.veri.first['isim'] ?? 'ID:$id') : 'ID:$id';
    _isimCache[id] = isim;
    return isim;
  }

  void _detayDialog(Map<String, dynamic> rel) {
    final puanC = TextEditingController(text: rel['iliski_puani']?.toString() ?? '0');
    final seviyeC = TextEditingController(text: rel['seviye']?.toString() ?? '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("İlişki Düzenle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
            const SizedBox(height: 4),
            Text("Kullanıcı 1: #${rel['kullanici1_id']}  —  Kullanıcı 2: #${rel['kullanici2_id']}", style: TextStyle(color: context.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: adminField("İlişki Puanı", puanC, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: adminField("Seviye", seviyeC, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    text: "Kaydet",
                    icon: LucideIcons.save,
                    onPressed: () async {
                      await SqlServis.guncelle(
                        tablo: 'sohbet_iliskileri',
                        veriler: {'iliski_puani': int.tryParse(puanC.text) ?? 0, 'seviye': int.tryParse(seviyeC.text) ?? 1},
                        sartlar: {'id': rel['id']},
                      );
                      Navigator.pop(ctx);
                      _yukle();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
                  onPressed: () {
                    Navigator.pop(ctx);
                    silOnayDialog(context, () async {
                      await SqlServis.sil(tablo: 'sohbet_iliskileri', sartlar: {'id': rel['id']});
                      _yukle();
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_iliskiler.isEmpty) return Center(child: Text("Kayıtlı ilişki yok.", style: TextStyle(color: context.textSecondary)));

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _iliskiler.length,
        itemBuilder: (_, i) {
          final r = _iliskiler[i];
          int id1 = int.tryParse(r['kullanici1_id'].toString()) ?? 0;
          int id2 = int.tryParse(r['kullanici2_id'].toString()) ?? 0;
          int puan = int.tryParse(r['iliski_puani'].toString()) ?? 0;
          int seviye = int.tryParse(r['seviye'].toString()) ?? 1;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              onTap: () => _detayDialog(r),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  FutureBuilder<String>(future: _isimCek(id1), builder: (_, s1) => GlowAvatar(initial: (s1.data ?? '?')[0].toUpperCase(), radius: 18, color: AppTheme.accent)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(LucideIcons.heart, color: AppTheme.danger, size: 14)),
                  FutureBuilder<String>(future: _isimCek(id2), builder: (_, s2) => GlowAvatar(initial: (s2.data ?? '?')[0].toUpperCase(), radius: 18, color: AppTheme.danger)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<List<String>>(
                          future: Future.wait([_isimCek(id1), _isimCek(id2)]),
                          builder: (_, snap) => Text(snap.hasData ? "${snap.data![0]} ❤️ ${snap.data![1]}" : "Yükleniyor...", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary), overflow: TextOverflow.ellipsis),
                        ),
                        Text("${r['son_etkilesim'] ?? ''}", style: TextStyle(color: context.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      adminBadge("Lv.$seviye", AppTheme.accent),
                      const SizedBox(height: 2),
                      Text("$puan XP", style: const TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: context.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}