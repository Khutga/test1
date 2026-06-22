import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/admin_widgets.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class HediyelerTab extends StatefulWidget {
  const HediyelerTab({super.key});
  @override
  State<HediyelerTab> createState() => _HediyelerTabState();
}

class _HediyelerTabState extends State<HediyelerTab> {
  List<Map<String, dynamic>> _hediyeler = [];
  bool _isLoading = true;
  String _filtre = 'hepsi'; 

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'hediyeler');
    if (res.basarili) {
      _hediyeler = res.veri;
      _hediyeler.sort((a, b) => (int.tryParse(a['sira'].toString()) ?? 0).compareTo(int.tryParse(b['sira'].toString()) ?? 0));
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtrelenmis {
    if (_filtre == 'hepsi') return _hediyeler;
    return _hediyeler.where((h) => h['kategori'] == _filtre || h['kategori'] == 'hepsi').toList();
  }

  Future<void> _sil(int id) async {
    await SqlServis.sil(tablo: 'hediyeler', sartlar: {'id': id});
    _yukle();
  }

  void _duzenleDialog({Map<String, dynamic>? mevcut}) {
    final adiC = TextEditingController(text: mevcut?['hediye_adi'] ?? '');
    final emojiC = TextEditingController(text: mevcut?['emoji'] ?? '');
    final fiyatC = TextEditingController(text: mevcut?['fiyat_coin']?.toString() ?? '');
    final siraC = TextEditingController(text: mevcut?['sira']?.toString() ?? '0');
    String kategori = mevcut?['kategori'] ?? 'hepsi';
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
              Text(mevcut == null ? "Yeni Hediye Ekle" : "Hediyeyi Düzenle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(width: 80, child: adminField("Emoji", emojiC)),
                  const SizedBox(width: 10),
                  Expanded(child: adminField("Hediye Adı", adiC)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: adminField("Fiyat (Coin)", fiyatC, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: adminField("Sıra", siraC, isNumber: true)),
                ],
              ),
              const SizedBox(height: 12),
              Text("Kategori", style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _kategoriChip("Hepsi", "hepsi", kategori, (v) => setModalState(() => kategori = v)),
                  const SizedBox(width: 6),
                  _kategoriChip("Sohbet", "sohbet", kategori, (v) => setModalState(() => kategori = v)),
                  const SizedBox(width: 6),
                  _kategoriChip("Yayın", "yayin", kategori, (v) => setModalState(() => kategori = v)),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero, dense: true,
                title: Text("Aktif", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                value: aktif, activeColor: AppTheme.success,
                onChanged: (v) => setModalState(() => aktif = v),
              ),
              const SizedBox(height: 12),
              PremiumButton(
                text: mevcut == null ? "Ekle" : "Kaydet",
                icon: mevcut == null ? LucideIcons.plus : LucideIcons.save,
                onPressed: () async {
                  if (adiC.text.isEmpty || emojiC.text.isEmpty || fiyatC.text.isEmpty) return;
                  final veriler = {
                    'hediye_adi': adiC.text.trim(),
                    'emoji': emojiC.text.trim(),
                    'fiyat_coin': int.tryParse(fiyatC.text) ?? 0,
                    'kategori': kategori,
                    'aktif_mi': aktif ? 1 : 0,
                    'sira': int.tryParse(siraC.text) ?? 0,
                  };
                  if (mevcut == null) {
                    await SqlServis.ekle(tablo: 'hediyeler', veriler: veriler);
                  } else {
                    await SqlServis.guncelle(tablo: 'hediyeler', veriler: veriler, sartlar: {'id': mevcut['id']});
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

  Widget _kategoriChip(String label, String value, String current, Function(String) onTap) {
    bool selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.accent : context.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : context.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final liste = _filtrelenmis;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GlassTabButton(label: "Tümü", isActive: _filtre == 'hepsi', onTap: () => setState(() => _filtre = 'hepsi')),
              const SizedBox(width: 6),
              GlassTabButton(label: "Sohbet", isActive: _filtre == 'sohbet', onTap: () => setState(() => _filtre = 'sohbet')),
              const SizedBox(width: 6),
              GlassTabButton(label: "Yayın", isActive: _filtre == 'yayin', onTap: () => setState(() => _filtre = 'yayin')),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _duzenleDialog(),
                icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                label: const Text("Ekle", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _yukle,
            child: liste.isEmpty
                ? ListView(children: [const SizedBox(height: 100), Center(child: Text("Bu kategoride hediye yok.", style: TextStyle(color: context.textSecondary)))])
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: liste.length,
                    itemBuilder: (_, i) {
                      final h = liste[i];
                      bool aktif = h['aktif_mi'].toString() != '0';
                      String kat = h['kategori'] ?? 'hepsi';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Text(h['emoji'] ?? '🎁', style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h['hediye_adi'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text("${h['fiyat_coin']} Coin", style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 6),
                                        adminBadge(kat == 'hepsi' ? "HEPSİ" : kat == 'sohbet' ? "SOHBET" : "YAYIN",
                                            kat == 'sohbet' ? AppTheme.accent : kat == 'yayin' ? AppTheme.danger : AppTheme.success),
                                        if (!aktif) ...[const SizedBox(width: 4), adminBadge("GİZLİ", AppTheme.danger)],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: Icon(LucideIcons.edit2, size: 18, color: context.textSecondary), onPressed: () => _duzenleDialog(mevcut: h)),
                              IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.danger), onPressed: () => silOnayDialog(context, () => _sil(int.parse(h['id'].toString())))),
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