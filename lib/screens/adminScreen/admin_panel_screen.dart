import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.shield, color: AppTheme.danger, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Admin Panel", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
                Text("Sistem Yönetimi", style: TextStyle(fontSize: 10, color: context.textSecondary)),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.accent,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: AppTheme.accent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "💰 Coin Paketleri"),
            Tab(text: "🎁 Hediyeler"),
            Tab(text: "👥 Kullanıcılar"),
            Tab(text: "🏢 Ajanslar"),
          ],
        ),
      ),
      body: MainBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            _CoinPaketleriTab(),
            _HediyelerTab(),
            _KullanicilarTab(),
            _AjanslarTab(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 1. TAB — COİN PAKETLERİ YÖNETİMİ
// ============================================================
class _CoinPaketleriTab extends StatefulWidget {
  const _CoinPaketleriTab();
  @override
  State<_CoinPaketleriTab> createState() => _CoinPaketleriTabState();
}

class _CoinPaketleriTabState extends State<_CoinPaketleriTab> {
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
              _adminField("Coin Miktarı", coinC, isNumber: true),
              const SizedBox(height: 10),
              _adminField("Bonus Miktarı", bonusC, isNumber: true),
              const SizedBox(height: 10),
              _adminField("Fiyat (USD)", fiyatC, isNumber: true),
              const SizedBox(height: 10),
              _adminField("Sıra", siraC, isNumber: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text("Popüler", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                      value: populer,
                      activeColor: AppTheme.accent,
                      onChanged: (v) => setModalState(() => populer = v),
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text("Aktif", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                      value: aktif,
                      activeColor: AppTheme.success,
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
                                  if (populer) _adminBadge("POPÜLER", AppTheme.accent),
                                  if (!aktif) _adminBadge("GİZLİ", AppTheme.danger),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: Icon(LucideIcons.edit2, size: 18, color: context.textSecondary), onPressed: () => _duzenleDialog(mevcut: p)),
                        IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.danger), onPressed: () => _silOnayDialog(context, () => _sil(int.parse(p['id'].toString())))),
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

// ============================================================
// 2. TAB — HEDİYELER YÖNETİMİ
// ============================================================
class _HediyelerTab extends StatefulWidget {
  const _HediyelerTab();
  @override
  State<_HediyelerTab> createState() => _HediyelerTabState();
}

class _HediyelerTabState extends State<_HediyelerTab> {
  List<Map<String, dynamic>> _hediyeler = [];
  bool _isLoading = true;
  String _filtre = 'hepsi'; // hepsi, sohbet, yayin

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
                  SizedBox(width: 80, child: _adminField("Emoji", emojiC)),
                  const SizedBox(width: 10),
                  Expanded(child: _adminField("Hediye Adı", adiC)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _adminField("Fiyat (Coin)", fiyatC, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _adminField("Sıra", siraC, isNumber: true)),
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
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text("Aktif", style: TextStyle(fontSize: 13, color: context.textPrimary)),
                value: aktif,
                activeColor: AppTheme.success,
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
                                        _adminBadge(kat == 'hepsi' ? "HEPSİ" : kat == 'sohbet' ? "SOHBET" : "YAYIN",
                                            kat == 'sohbet' ? AppTheme.accent : kat == 'yayin' ? AppTheme.danger : AppTheme.success),
                                        if (!aktif) ...[const SizedBox(width: 4), _adminBadge("GİZLİ", AppTheme.danger)],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: Icon(LucideIcons.edit2, size: 18, color: context.textSecondary), onPressed: () => _duzenleDialog(mevcut: h)),
                              IconButton(icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.danger), onPressed: () => _silOnayDialog(context, () => _sil(int.parse(h['id'].toString())))),
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

// ============================================================
// 3. TAB — KULLANICILAR YÖNETİMİ
// ============================================================
class _KullanicilarTab extends StatefulWidget {
  const _KullanicilarTab();
  @override
  State<_KullanicilarTab> createState() => _KullanicilarTabState();
}

class _KullanicilarTabState extends State<_KullanicilarTab> {
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
              // Header
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

              // Bilgi Satırları
              _infoRow("Cinsiyet", user['cinsiyet'] ?? '-'),
              _infoRow("Doğum Tarihi", user['dogum_tarihi'] ?? '-'),
              _infoRow("Kayıt Tarihi", (user['olusturulma_tarihi'] ?? '').toString().split(' ').first),
              const SizedBox(height: 12),

              // Düzenlenebilir Alanlar
              Row(
                children: [
                  Expanded(child: _adminField("Coin Bakiye", coinC, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _adminField("XP Puanı", xpC, isNumber: true)),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final liste = _filtrelenmis;
    return Column(
      children: [
        // Arama
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
                                  if (yasakli) Padding(padding: const EdgeInsets.only(left: 4), child: _adminBadge("BAN", AppTheme.danger)),
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

// ============================================================
// 4. TAB — AJANSLAR YÖNETİMİ
// ============================================================
class _AjanslarTab extends StatefulWidget {
  const _AjanslarTab();
  @override
  State<_AjanslarTab> createState() => _AjanslarTabState();
}

class _AjanslarTabState extends State<_AjanslarTab> {
  List<Map<String, dynamic>> _ajansUyeleri = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _isLoading = true);
    final res = await SqlServis.cek(tablo: 'ajans_uyeleri');
    if (res.basarili) _ajansUyeleri = res.veri;
    setState(() => _isLoading = false);
  }

  void _uyeDetayDialog(Map<String, dynamic> uye) {
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
              Text("Üye Detayı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
              const SizedBox(height: 12),
              _infoRowStatic(context, "İsim", uye['isim'] ?? '-'),
              _infoRowStatic(context, "ID Kodu", uye['id_kodu'] ?? '-'),
              _infoRowStatic(context, "Ajans Sahibi ID", uye['ajans_sahibi_id']?.toString() ?? '-'),
              const SizedBox(height: 12),
              Text("Durum", style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: durumlar.map((d) {
                  bool selected = durum == d;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setModalState(() => durum = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppTheme.accent : context.border),
                        ),
                        child: Text(d, style: TextStyle(color: selected ? Colors.white : context.textSecondary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              PremiumButton(
                text: "Kaydet",
                icon: LucideIcons.save,
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_ajansUyeleri.isEmpty) {
      return Center(child: Text("Kayıtlı ajans üyesi yok.", style: TextStyle(color: context.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _yukle,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ajansUyeleri.length,
        itemBuilder: (_, i) {
          final u = _ajansUyeleri[i];
          String durum = u['durum'] ?? 'Pasif';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GlassContainer(
              onTap: () => _uyeDetayDialog(u),
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
                        Text("Kod: ${u['id_kodu'] ?? '-'} • Sahip ID: ${u['ajans_sahibi_id']}", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (durum == 'Aktif' ? AppTheme.success : durum == 'Beklemede' ? AppTheme.warning : AppTheme.danger).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(durum, style: TextStyle(
                      fontSize: 11,
                      color: durum == 'Aktif' ? AppTheme.success : durum == 'Beklemede' ? AppTheme.warning : AppTheme.danger,
                      fontWeight: FontWeight.w700,
                    )),
                  ),
                  const SizedBox(width: 6),
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

// ============================================================
// ORTAK YARDIMCI FONKSİYONLAR
// ============================================================

Widget _adminField(String label, TextEditingController controller, {bool isNumber = false}) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    ),
  );
}

Widget _adminBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
  );
}

Widget _infoRowStatic(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

void _silOnayDialog(BuildContext context, VoidCallback onSil) {
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: context.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Silmek istediğine emin misin?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
      content: Text("Bu işlem geri alınamaz.", style: TextStyle(color: context.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text("İptal", style: TextStyle(color: context.textSecondary))),
        ElevatedButton(
          onPressed: () { Navigator.pop(c); onSil(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text("Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}