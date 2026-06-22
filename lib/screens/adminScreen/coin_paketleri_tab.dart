import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/admin_widgets.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class CoinPaketleriTab extends StatefulWidget {
  const CoinPaketleriTab({super.key});
  @override
  State<CoinPaketleriTab> createState() => _CoinPaketleriTabState();
}

class _CoinPaketleriTabState extends State<CoinPaketleriTab> {
  List<Map<String, dynamic>> _paketler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'coin_paketleri');
    if (res.basarili) {
      _paketler = res.veri;
      _paketler.sort((a, b) => (int.tryParse(a['sira'].toString()) ?? 0).compareTo(int.tryParse(b['sira'].toString()) ?? 0));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _sil(int id) async {
    await SqlServis.sil(tablo: 'coin_paketleri', sartlar: {'id': id});
    _yukle();
  }

  void _duzenleDialog({Map<String, dynamic>? mevcut}) {
    final coinC = TextEditingController(text: mevcut?['coin_miktari']?.toString() ?? '');
    final bonusC = TextEditingController(text: mevcut?['bonus_miktari']?.toString() ?? '0');
    final fiyatC = TextEditingController(text: mevcut?['fiyat_usd']?.toString() ?? '');
    final siraC = TextEditingController(text: mevcut?['sira']?.toString() ?? '0');
    bool populer = mevcut?['populer_mi'].toString() == '1';
    bool aktif = mevcut?['aktif_mi'].toString() != '0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mevcut == null ? "Yeni Paket Ekle" : "Paketi Düzenle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
              const SizedBox(height: 16),
              adminField("Coin Miktarı", coinC, isNumber: true),
              const SizedBox(height: 10),
              adminField("Bonus Miktarı", bonusC, isNumber: true),
              const SizedBox(height: 10),
              adminField("Fiyat (USD)", fiyatC, isNumber: true),
              const SizedBox(height: 10),
              adminField("Sıra", siraC, isNumber: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text("Popüler", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                      value: populer, activeColor: AppTheme.accent,
                      onChanged: (v) => setModalState(() => populer = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text("Aktif", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                      value: aktif, activeColor: AppTheme.success,
                      onChanged: (v) => setModalState(() => aktif = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PremiumButton(
                text: mevcut == null ? "Ekle" : "Kaydet",
                icon: mevcut == null ? LucideIcons.plus : LucideIcons.save,
                onPressed: () async {
                  final veriler = {
                    'coin_miktari': int.tryParse(coinC.text) ?? 0,
                    'bonus_miktari': int.tryParse(bonusC.text) ?? 0,
                    'fiyat_usd': double.tryParse(fiyatC.text) ?? 0,
                    'populer_mi': populer ? 1 : 0,
                    'aktif_mi': aktif ? 1 : 0,
                    'sira': int.tryParse(siraC.text) ?? 0,
                  };
                  if (mevcut == null) {
                    await SqlServis.ekle(tablo: 'coin_paketleri', veriler: veriler);
                  } else {
                    await SqlServis.guncelle(tablo: 'coin_paketleri', veriler: veriler, sartlar: {'id': mevcut['id']});
                  }
                  Navigator.pop(ctx);
                  _yukle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${_paketler.length} Paket", style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              ElevatedButton.icon(
                onPressed: () => _duzenleDialog(),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text("Yeni Paket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _yukle,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _paketler.length,
              itemBuilder: (_, i) {
                final p = _paketler[i];
                bool aktif = p['aktif_mi'].toString() != '0';
                bool populer = p['populer_mi'].toString() == '1';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text("🪙", style: TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text("${p['coin_miktari']} Coin", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.textPrimary)),
                                  if (int.tryParse(p['bonus_miktari'].toString()) != null && int.parse(p['bonus_miktari'].toString()) > 0)
                                    Text(" +${p['bonus_miktari']}", style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text("\$${p['fiyat_usd']}", style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w700, fontSize: 13)),
                                  const SizedBox(width: 8),
                                  if (populer) adminBadge("POPÜLER", AppTheme.accent),
                                  if (!aktif) adminBadge("GİZLİ", AppTheme.danger),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: Icon(LucideIcons.edit2, size: 18, color: context.textSecondary), onPressed: () => _duzenleDialog(mevcut: p)),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.danger), onPressed: () => silOnayDialog(context, () => _sil(int.parse(p['id'].toString())))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}