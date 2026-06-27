import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/accountScreen/profilGoster/user_profile_screen.dart';
// Kendi tema ve widget yollarını import et
// import '../../core/app_colors.dart';

class YarislarTab extends StatefulWidget {
  const YarislarTab({super.key});

  @override
  State<YarislarTab> createState() => _YarislarTabState();
}

class _YarislarTabState extends State<YarislarTab> {
  String _seciliKategori = 'yayinci'; // yayinci, cutluk, ajans
  bool _isLoading = true;
  List<dynamic> _liste = [];

  final String apiUrl = "https://codefellas.com.tr/apps/nivi/api/leaderboard.php";

  @override
  void initState() {
    super.initState();
    _verileriCek();
  }

Future<void> _verileriCek() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse("$apiUrl?type=$_seciliKategori"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['durum'] == 'basarili') {
          setState(() {
            _liste = data['veri'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          print("API Hatası: ${data['mesaj']}");
        }
      } else {
        setState(() => _isLoading = false);
        print("Sunucu Hatası: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Bağlantı Hatası: $e");
    }
  }

  void _adminIslemMenusuAc(Map<String, dynamic> item, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _seciliKategori == 'cutluk' 
                    ? "${item['isim1']} & ${item['isim2']}" 
                    : "${item['isim']}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text("${index + 1}. Sırada - Toplam: ${item['skor']} Puan/Coin", style: const TextStyle(color: Colors.grey)),
              const Divider(height: 30),
              
              // 🔥 1. ÇİFTLER İSE İKİ KİŞİ İÇİN AYRI PROFİL VE ÖDÜL BUTONLARI
              if (_seciliKategori == 'cutluk') ...[
                ListTile(
                  leading: const Icon(LucideIcons.user, color: Colors.blue),
                  title: Text("${item['isim1']} Profiline Git"),
                  onTap: () {
                    Navigator.pop(context); 
                    _profileGit(item['isim1']); 
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.user, color: Colors.pink),
                  title: Text("${item['isim2']} Profiline Git"),
                  onTap: () {
                    Navigator.pop(context); 
                    _profileGit(item['isim2']); 
                  },
                ),
                const Divider(), // Butonlar karışmasın diye araya çizgi çekiyoruz
                ListTile(
                  leading: const Icon(LucideIcons.coins, color: Colors.orange),
                  title: Text("${item['isim1']} Adlı Kullanıcıya Ödül Gönder"),
                  onTap: () {
                    Navigator.pop(context);
                    _manuelOdulGonderDialog(item['isim1']);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.coins, color: Colors.deepOrange),
                  title: Text("${item['isim2']} Adlı Kullanıcıya Ödül Gönder"),
                  onTap: () {
                    Navigator.pop(context);
                    _manuelOdulGonderDialog(item['isim2']);
                  },
                ),
              ] 
              // 🔥 2. YAYINCI VEYA AJANS İSE TEK BUTON
              else ...[
                ListTile(
                  leading: const Icon(LucideIcons.user, color: Colors.blue),
                  title: const Text("Kullanıcı Profiline Git"),
                  onTap: () {
                    Navigator.pop(context); 
                    _profileGit(item['isim']); 
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.coins, color: Colors.orange),
                  title: const Text("Manuel Ödül / Coin Gönder"),
                  onTap: () {
                    Navigator.pop(context);
                    _manuelOdulGonderDialog(item['isim']);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  // 🔥 PROFİL SAYFASINA YÖNLENDİRME
  void _profileGit(String? userName) {
    if (userName == null || userName.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        // Senin orjinal UserProfileScreen yapın
        builder: (_) => UserProfileScreen(hedefKullaniciAdi: userName), 
      ),
    );
  }

  // 🔥 2 COİN SEÇENEKLİ ÖDÜL GÖNDERME DİALOGU
  void _manuelOdulGonderDialog(String? hedefKullanici) {
    if (hedefKullanici == null || hedefKullanici.isEmpty) return;

    TextEditingController coinController = TextEditingController();
    String seciliCoinTipi = 'birinci_coin_bakiye'; 

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(LucideIcons.coins, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text("@$hedefKullanici'a Ödül", style: const TextStyle(fontSize: 16))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: seciliCoinTipi,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'birinci_coin_bakiye', child: Text("1. Coin (Harcama)")),
                        DropdownMenuItem(value: 'ikinci_coin_bakiye', child: Text("2. Coin (Kazanç)")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => seciliCoinTipi = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: coinController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Miktar girin (Örn: 5000)",
                    prefixIcon: const Icon(LucideIcons.banknote),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("İptal", style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (coinController.text.isEmpty) return;
                  
                  // 🔥 TODO: Burada veritabanına coini ekleyecek fonksiyonu çağıracaksın
                  print("$hedefKullanici adlı kişiye ${coinController.text} miktarında $seciliCoinTipi eklenecek.");
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${coinController.text} ödül $hedefKullanici'a başarıyla gönderildi!"),
                      backgroundColor: Colors.green,
                    )
                  );
                },
                child: const Text("Gönder", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kategori Seçici
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'yayinci', label: Text("Yayıncılar")),
              ButtonSegment(value: 'cutluk', label: Text("Çiftler")),
              ButtonSegment(value: 'ajans', label: Text("Ajanslar")),
            ],
            selected: {_seciliKategori},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _seciliKategori = newSelection.first;
              });
              _verileriCek();
            },
          ),
        ),
        
        // Liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _liste.isEmpty
                  ? const Center(child: Text("Henüz veri yok."))
                  : ListView.builder(
                      itemCount: _liste.length,
                      itemBuilder: (context, index) {
                        final item = _liste[index];
                        String baslik = _seciliKategori == 'cutluk' 
                            ? "${item['isim1']} & ${item['isim2']}" 
                            : item['isim'] ?? 'Bilinmiyor';
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: index == 0 ? Colors.amber : index == 1 ? Colors.grey.shade400 : index == 2 ? Colors.brown.shade300 : Colors.blueGrey.withOpacity(0.2),
                              child: Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                            title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Skor: ${item['skor']} Coin/Puan"),
                            trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
                            onTap: () => _adminIslemMenusuAc(item, index), // Tıklayınca Admin Menüsü açılır
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}