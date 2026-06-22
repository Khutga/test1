import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/app_colors.dart';
import '../../../services/sql_servis.dart';

class BasarimlarTab extends StatefulWidget {
  const BasarimlarTab({super.key});

  @override
  State<BasarimlarTab> createState() => _BasarimlarTabState();
}

class _BasarimlarTabState extends State<BasarimlarTab> {
  List<Map<String, dynamic>> basarimlar = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _veriCek();
  }

  Future<void> _veriCek() async {
    setState(() => isLoading = true);
    var res = await SqlServis.cek(tablo: Tablolar.basarimlar);
    if (res.basarili && mounted) {
      setState(() {
        basarimlar = res.veri;
        isLoading = false;
      });
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  
  void _basarimDuzenleDialog(BuildContext context, Map<String, dynamic> item) {
    TextEditingController baslikCtrl = TextEditingController(text: item['baslik']);
    TextEditingController aciklamaCtrl = TextEditingController(text: item['aciklama']);
    TextEditingController hedefCtrl = TextEditingController(text: item['hedef_deger'].toString());
    TextEditingController odulCtrl = TextEditingController(text: item['odul_coin'].toString());
    String seciliTip = item['basarim_tipi'] ?? 'gunluk_giris';
    List<String> tipler = ['gunluk_giris', 'haftalik_seri', 'hediye_gonder', 'yayin_izle', 'seviye_atla'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Başarım Düzenle", style: TextStyle(color: context.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: baslikCtrl, style: TextStyle(color: context.textPrimary), decoration: const InputDecoration(labelText: "Başlık")),
                const SizedBox(height: 12),
                TextField(controller: aciklamaCtrl, style: TextStyle(color: context.textPrimary), decoration: const InputDecoration(labelText: "Açıklama")),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: seciliTip,
                  dropdownColor: context.card,
                  style: TextStyle(color: context.textPrimary),
                  items: tipler.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => seciliTip = val!),
                  decoration: const InputDecoration(labelText: "Başarım Tipi"),
                ),
                const SizedBox(height: 12),
                TextField(controller: hedefCtrl, style: TextStyle(color: context.textPrimary), decoration: const InputDecoration(labelText: "Hedef Değer"), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: odulCtrl, style: TextStyle(color: context.textPrimary), decoration: const InputDecoration(labelText: "Ödül Coin"), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
           ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              onPressed: () async {
                if (seciliTip == 'gunluk_giris' || seciliTip == 'haftalik_seri') {
                  if (seciliTip != item['basarim_tipi']) {
                    var kontrol = await SqlServis.cek(tablo: Tablolar.basarimlar, sartlar: {'basarim_tipi': seciliTip});
                    if (kontrol.basarili && kontrol.veri.isNotEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$seciliTip tipinde zaten bir başarım var!")),
                      );
                      return;
                    }
                  }
                }

                await SqlServis.guncelle(
                  tablo: Tablolar.basarimlar,
                  veriler: {
                    "baslik": baslikCtrl.text,
                    "aciklama": aciklamaCtrl.text,
                    "basarim_tipi": seciliTip,
                    "hedef_deger": int.tryParse(hedefCtrl.text) ?? 1,
                    "odul_coin": int.tryParse(odulCtrl.text) ?? 0,
                  },
                  sartlar: {'id': item['id']}
                );
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _veriCek();
              },
              child: const Text("Güncelle", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _basarimEkleDialog(BuildContext context) {
    TextEditingController baslikCtrl = TextEditingController();
    TextEditingController aciklamaCtrl = TextEditingController();
    TextEditingController hedefCtrl = TextEditingController(text: "1");
    TextEditingController odulCtrl = TextEditingController(text: "100");
    String seciliTip = 'gunluk_giris';
    List<String> tipler = ['gunluk_giris', 'haftalik_seri', 'hediye_gonder', 'yayin_izle', 'seviye_atla'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Yeni Başarım Ekle", style: TextStyle(color: context.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baslikCtrl,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: "Başlık"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aciklamaCtrl,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: "Açıklama"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: seciliTip,
                  dropdownColor: context.card,
                  style: TextStyle(color: context.textPrimary),
                  items: tipler.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setDialogState(() => seciliTip = val!),
                  decoration: const InputDecoration(labelText: "Başarım Tipi"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hedefCtrl,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: "Hedef Değer (Örn: 7)"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: odulCtrl,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: "Ödül Coin"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
           ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (seciliTip == 'gunluk_giris' || seciliTip == 'haftalik_seri') {
                  var kontrol = await SqlServis.cek(tablo: Tablolar.basarimlar, sartlar: {'basarim_tipi': seciliTip});
                  if (kontrol.basarili && kontrol.veri.isNotEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$seciliTip tipinde zaten bir başarım var!")),
                    );
                    return;
                  }
                }

                await SqlServis.ekle(
                  tablo: Tablolar.basarimlar,
                  veriler: {
                    "baslik": baslikCtrl.text,
                    "aciklama": aciklamaCtrl.text,
                    "basarim_tipi": seciliTip,
                    "hedef_deger": int.tryParse(hedefCtrl.text) ?? 1,
                    "odul_coin": int.tryParse(odulCtrl.text) ?? 0,
                    "durum": "aktif"
                  },
                );
                
                if (!context.mounted) return;
                Navigator.pop(context);
                _veriCek();
              },
              child: const Text("Kaydet", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _basarimEkleDialog(context),
        backgroundColor: AppTheme.accent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : basarimlar.isEmpty
              ? Center(child: Text("Henüz başarım eklenmemiş.", style: TextStyle(color: context.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: basarimlar.length,
                  itemBuilder: (context, index) {
                    var item = basarimlar[index];
                    return Card(
                      color: context.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(LucideIcons.trophy, color: Colors.orange),
                        title: Text(item['baslik'] ?? '', style: TextStyle(color: context.textPrimary)),
                        subtitle: Text("${item['odul_coin']} Coin - ${item['basarim_tipi']}", style: TextStyle(color: context.textSecondary)),
                       trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit, color: AppTheme.accent),
                              onPressed: () => _basarimDuzenleDialog(context, item),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
                              onPressed: () async {
                                await SqlServis.sil(tablo: Tablolar.basarimlar, sartlar: {'id': item['id']});
                                _veriCek();
                              },
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