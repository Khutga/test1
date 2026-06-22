import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/admin_widgets.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class KullanicilarTab extends StatefulWidget {
  const KullanicilarTab({super.key});
  @override
  State<KullanicilarTab> createState() => _KullanicilarTabState();
}

class _KullanicilarTabState extends State<KullanicilarTab> {
  List<Map<String, dynamic>> _kullanicilar = [];
  bool _isLoading = true;
  final TextEditingController _aramaC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'hesaplar');
    if (res.basarili) _kullanicilar = res.veri;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filtrelenmis {
    if (_aramaC.text.isEmpty) return _kullanicilar;
    final q = _aramaC.text.toLowerCase();
    return _kullanicilar.where((u) {
      return (u['kullanici_adi'] ?? '').toString().toLowerCase().contains(q) ||
          (u['isim'] ?? '').toString().toLowerCase().contains(q) ||
          (u['eposta'] ?? '').toString().toLowerCase().contains(q) ||
          (u['id'] ?? '').toString().contains(q);
    }).toList();
  }

  void _kullaniciDetayDialog(Map<String, dynamic> user) {
    final coinC = TextEditingController(text: user['birinci_coin_bakiye']?.toString() ?? '0');
    final xpC = TextEditingController(text: user['xp_puani']?.toString() ?? '0');
    bool yasakli = user['yasakli_mi'].toString() == '1';
    bool onayli = user['onayli_hesap'].toString() == '1';

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
              Row(
                children: [
                  GlowAvatar(initial: (user['isim'] ?? '?')[0].toUpperCase(), radius: 24, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['isim'] ?? 'Bilinmiyor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textPrimary)),
                        Text("@${user['kullanici_adi']} • ID: ${user['id']}", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                        Text(user['eposta'] ?? '', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Divider(color: context.border),
              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Cinsiyet", style: TextStyle(color: context.textSecondary, fontSize: 12)), Text(user['cinsiyet'] ?? '-', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Doğum Tarihi", style: TextStyle(color: context.textSecondary, fontSize: 12)), Text(user['dogum_tarihi'] ?? '-', style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Kayıt Tarihi", style: TextStyle(color: context.textSecondary, fontSize: 12)), Text((user['olusturulma_tarihi'] ?? '').toString().split(' ').first, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: adminField("Coin Bakiye", coinC, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: adminField("XP Puanı", xpC, isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text("Yasaklı", style: TextStyle(fontSize: 13, color: AppTheme.danger, fontWeight: FontWeight.w600)),
                      value: yasakli, activeColor: AppTheme.danger,
                      onChanged: (v) => setModalState(() => yasakli = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero, dense: true,
                      title: Text("Onaylı ✓", style: TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                      value: onayli, activeColor: AppTheme.accent,
                      onChanged: (v) => setModalState(() => onayli = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PremiumButton(
                text: "Değişiklikleri Kaydet",
                icon: LucideIcons.save,
                onPressed: () async {
                  await SqlServis.guncelle(
                    tablo: 'hesaplar',
                    veriler: {
                      'birinci_coin_bakiye': double.tryParse(coinC.text) ?? 0,
                      'xp_puani': int.tryParse(xpC.text) ?? 0,
                      'yasakli_mi': yasakli ? 1 : 0,
                      'onayli_hesap': onayli ? 1 : 0,
                    },
                    sartlar: {'id': user['id']},
                  );
                  Navigator.pop(ctx);
                  _yukle();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı güncellendi."), backgroundColor: AppTheme.success));
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
    final liste = _filtrelenmis;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _aramaC,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: 14, color: context.textPrimary),
            decoration: InputDecoration(
              hintText: "İsim, e-posta veya ID ara...",
              hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
              prefixIcon: Icon(LucideIcons.search, color: context.textSecondary, size: 18),
              filled: true,
              fillColor: context.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("${liste.length} kullanıcı", style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _yukle,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: liste.length,
              itemBuilder: (_, i) {
                final u = liste[i];
                bool yasakli = u['yasakli_mi'].toString() == '1';
                bool onayli = u['onayli_hesap'].toString() == '1';
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: GlassContainer(
                    onTap: () => _kullaniciDetayDialog(u),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        GlowAvatar(initial: (u['isim'] ?? '?')[0].toUpperCase(), radius: 20, color: yasakli ? AppTheme.danger : AppTheme.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(child: Text(u['isim'] ?? '-', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary), overflow: TextOverflow.ellipsis)),
                                  if (onayli) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(LucideIcons.badgeCheck, size: 14, color: AppTheme.accent)),
                                  if (yasakli) Padding(padding: const EdgeInsets.only(left: 4), child: adminBadge("BAN", AppTheme.danger)),
                                ],
                              ),
                              Text("@${u['kullanici_adi']} • ${u['eposta']}", style: TextStyle(color: context.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${u['birinci_coin_bakiye']} 🪙", style: const TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text("ID: ${u['id']}", style: TextStyle(color: context.textSecondary, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Icon(LucideIcons.chevronRight, size: 16, color: context.textSecondary),
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