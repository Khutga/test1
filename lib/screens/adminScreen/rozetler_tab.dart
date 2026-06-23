import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/app_colors.dart';
import '../../../services/sql_servis.dart';

class RozetlerTab extends StatefulWidget {
  const RozetlerTab({super.key});

  @override
  State<RozetlerTab> createState() => _RozetlerTabState();
}

class _RozetlerTabState extends State<RozetlerTab> {
  List<Map<String, dynamic>> rozetler = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _veriCek();
  }

  Future<void> _veriCek() async {
    setState(() => isLoading = true);
    var res = await SqlServis.cek(tablo: Tablolar.rozetler);
    if (res.basarili && mounted) {
      setState(() {
        rozetler = res.veri;
        isLoading = false;
      });
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _rozetDialog(BuildContext context, {Map<String, dynamic>? item}) {
    TextEditingController baslikCtrl = TextEditingController(text: item?['baslik']);
    TextEditingController aciklamaCtrl = TextEditingController(text: item?['aciklama']);
    TextEditingController renkCtrl = TextEditingController(text: item?['renk_hex'] ?? '#FFD700');
    
    bool otomatikMi = (item?['otomatik_verilecek_mi']?.toString() ?? '0') == '1';
    TextEditingController gunCtrl = TextEditingController(text: item?['gereken_gun_sayisi']?.toString() ?? '0');
    TextEditingController odulCtrl = TextEditingController(text: item?['odul_coin']?.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(item == null ? "Yeni Rozet Ekle" : "Rozet Düzenle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: baslikCtrl,
                  decoration: const InputDecoration(labelText: "Başlık"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aciklamaCtrl,
                  decoration: const InputDecoration(labelText: "Açıklama"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: renkCtrl,
                  decoration: const InputDecoration(labelText: "Renk Hex (Örn: #FFD700)"),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text("Kayıt Süresine Göre Otomatik Ver", style: TextStyle(fontSize: 14)),
                  value: otomatikMi,
                  activeColor: AppTheme.accent,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => otomatikMi = val),
                ),
                if (otomatikMi) ...[
                  TextField(
                    controller: gunCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Kaçıncı Günde Verilsin?"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: odulCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Verilecek Ödül Coin"),
                  ),
                ]
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
                Map<String, dynamic> v = {
                  "baslik": baslikCtrl.text,
                  "aciklama": aciklamaCtrl.text,
                  "renk_hex": renkCtrl.text,
                  "otomatik_verilecek_mi": otomatikMi ? "1" : "0",
                  "gereken_gun_sayisi": int.tryParse(gunCtrl.text) ?? 0,
                  "odul_coin": int.tryParse(odulCtrl.text) ?? 0,
                };
                
                if (item == null) {
                  await SqlServis.ekle(tablo: Tablolar.rozetler, veriler: v);
                } else {
                  await SqlServis.guncelle(tablo: Tablolar.rozetler, veriler: v, sartlar: {'id': item['id']});
                }
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
        onPressed: () => _rozetDialog(context),
        backgroundColor: AppTheme.accent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : rozetler.isEmpty
              ? const Center(child: Text("Henüz rozet eklenmemiş.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rozetler.length,
                  itemBuilder: (context, index) {
                    var item = rozetler[index];
                    Color rColor = Colors.amber;
                    try {
                      rColor = Color(int.parse(item['renk_hex'].toString().replaceAll('#', '0xff')));
                    } catch (_) {}

                    bool oto = (item['otomatik_verilecek_mi']?.toString() ?? '0') == '1';
                    String altYazi = item['aciklama'] ?? '';
                    if (oto) {
                      altYazi += "\nOtomatik: ${item['gereken_gun_sayisi']}. Gün - Ödül: ${item['odul_coin']} Coin";
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(LucideIcons.award, color: rColor, size: 32),
                        title: Text(item['baslik'] ?? ''),
                        subtitle: Text(altYazi),
                        isThreeLine: oto,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.edit, color: AppTheme.accent),
                              onPressed: () => _rozetDialog(context, item: item),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: AppTheme.danger),
                              onPressed: () async {
                                await SqlServis.sil(tablo: Tablolar.rozetler, sartlar: {'id': item['id'].toString()});
                                await SqlServis.sil(tablo: Tablolar.kullaniciRozetleri, sartlar: {'rozet_id': item['id'].toString()});
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