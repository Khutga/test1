import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final res = await SqlServis.cek(tablo: 'etkinlikler', sartlar: {'durum': 'aktif'});
    if (res.basarili) {
      setState(() {
        _events = res.veri;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _joinEvent(int eventId) {
    // Burada ileride 'etkinlik_katilimcilari' tablosuna insert yapılabilir.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Etkinliğe başarıyla katıldınız!"), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Etkinlikler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Aktif turnuvalara katılın ve ödülleri kapın.", style: TextStyle(color: context.textSecondary, fontSize: 11)),
                const SizedBox(height: 16),

                // Ana (Büyük) Turnuva Kartı (İlk etkinliği büyük gösterelim)
                if (_events.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_events.first['baslik'].toString().toUpperCase(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(_events.first['odul_metni'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                              child: Text("Son Katılım: ${(_events.first['bitis_tarihi'] ?? '').toString().split(' ').first}", style: const TextStyle(fontSize: 9, color: Colors.white)),
                            ),
                            ElevatedButton(
                              onPressed: () => _joinEvent(int.parse(_events.first['id'].toString())),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.accent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
                              child: const Text("Katıl", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),

                // Diğer Etkinlikler Listesi
                if (_events.length > 1)
                  ..._events.skip(1).map((event) => _buildEventCard(context, event)),
                  
                if (_events.isEmpty)
                  const Center(child: Text("Şu an aktif bir etkinlik bulunmuyor.", style: TextStyle(color: Colors.white54))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['baslik'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: context.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text("Ödül: ${event['odul_metni']}", style: const TextStyle(color: AppTheme.accentGold, fontSize: 9)),
                      Text(" • ", style: TextStyle(color: context.textSecondary, fontSize: 9)),
                      Text("${event['katilimci_sayisi']} Katılımcı", style: TextStyle(color: context.textSecondary, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _joinEvent(int.parse(event['id'].toString())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("Katıl", style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            )
          ],
        ),
      ),
    );
  }
}