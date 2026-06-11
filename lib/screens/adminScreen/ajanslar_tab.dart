import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/app_colors.dart';
import '../../../services/sql_servis.dart';
import '../../../widgets/custom_widgets.dart';

class AjanslarTab extends StatefulWidget {
  const AjanslarTab({super.key});
  @override
  State<AjanslarTab> createState() => _AjanslarTabState();
}

class _AjanslarTabState extends State<AjanslarTab> {
  List<Map<String, dynamic>> _ajanslar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

 Future<void> _yukle() async {
    if (!mounted) return; // Sayfa kapandıysa işlemi iptal et
    setState(() => _isLoading = true);
    
    final res = await SqlServis.cek(tablo: 'ajanslar');
    
    if (res.basarili) {
      _ajanslar = res.veri;
    }
    
    if (mounted) { // YENİ EKLENEN KONTROL
      setState(() => _isLoading = false);
    }
  }
  Future<String> _sahipIsmiCek(dynamic sahipId) async {
    final res = await SqlServis.cek(tablo: 'hesaplar', sartlar: {'id': sahipId});
    if (res.basarili && res.veri.isNotEmpty) return res.veri.first['isim'] ?? 'Bilinmiyor';
    return 'ID: $sahipId';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_ajanslar.isEmpty) return Center(child: Text("Kayıtlı ajans yok.", style: TextStyle(color: context.textSecondary)));

    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ajanslar.length,
        itemBuilder: (_, i) {
          final a = _ajanslar[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AjansDetaySayfasi(ajans: a),
                ));
              },
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Text("🏢", style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['ajans_ismi'] ?? '-', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: context.textPrimary)),
                        FutureBuilder<String>(
                          future: _sahipIsmiCek(a['ajans_sahibi_id']),
                          builder: (_, snap) => Text(
                            "Sahip: ${snap.data ?? '...'} • Kuruluş: ${(a['olusturulma_tarihi'] ?? '').toString().split(' ').first}",
                            style: TextStyle(color: context.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: context.textSecondary),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AjansDetaySayfasi extends StatefulWidget {
  final Map<String, dynamic> ajans;
  const AjansDetaySayfasi({required this.ajans, super.key});
  @override
  State<AjansDetaySayfasi> createState() => _AjansDetaySayfasiState();
}

class _AjansDetaySayfasiState extends State<AjansDetaySayfasi> {
  List<Map<String, dynamic>> _uyeler = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

 Future<void> _yukle() async {
    if (!mounted) return; 
    setState(() => _isLoading = true);
    
    final res = await SqlServis.cek(
      tablo: 'ajans_uyeleri', 
      sartlar: {'ajans_sahibi_id': widget.ajans['ajans_sahibi_id']}
    );
    
    if (res.basarili) {
      _uyeler = res.veri;
    }
    
    if (mounted) { // YENİ EKLENEN KONTROL
      setState(() => _isLoading = false);
    }
  }

  void _uyeDurumDegistir(Map<String, dynamic> uye) {
    final durumlar = ['Aktif', 'Pasif', 'Beklemede'];
    String durum = uye['durum'] ?? 'Pasif';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GlowAvatar(initial: (uye['isim'] ?? '?')[0].toUpperCase(), radius: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uye['isim'] ?? '-', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textPrimary)),
                      Text("Kod: ${uye['id_kodu'] ?? '-'}", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Durum", style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: durumlar.map((d) {
                  bool selected = durum == d;
                  Color renk = d == 'Aktif' ? AppTheme.success : d == 'Beklemede' ? AppTheme.warning : AppTheme.danger;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setModalState(() => durum = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: selected ? renk : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? renk : context.border)),
                        child: Text(d, style: TextStyle(color: selected ? Colors.white : context.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              PremiumButton(
                text: "Kaydet", icon: LucideIcons.save,
                onPressed: () async {
                  await SqlServis.guncelle(tablo: 'ajans_uyeleri', veriler: {'durum': durum}, sartlar: {'id': uye['id']});
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ajans['ajans_ismi'] ?? 'Ajans', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
            Text("Üye Yönetimi", style: TextStyle(fontSize: 10, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _uyeler.isEmpty
                ? Center(child: Text("Bu ajansta henüz üye yok.", style: TextStyle(color: context.textSecondary)))
                : RefreshIndicator(
                    onRefresh: _yukle,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _uyeler.length,
                      itemBuilder: (_, i) {
                        final u = _uyeler[i];
                        String durum = u['durum'] ?? 'Pasif';
                        Color durumRenk = durum == 'Aktif' ? AppTheme.success : durum == 'Beklemede' ? AppTheme.warning : AppTheme.danger;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: GlassContainer(
                            onTap: () => _uyeDurumDegistir(u),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                GlowAvatar(initial: (u['isim'] ?? '?')[0].toUpperCase(), radius: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(u['isim'] ?? '-', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: context.textPrimary)),
                                      Text("Kod: ${u['id_kodu'] ?? '-'}", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: durumRenk.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(durum, style: TextStyle(fontSize: 11, color: durumRenk, fontWeight: FontWeight.w700)),
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
    );
  }
}