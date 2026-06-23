import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';
import '../services/sql_servis.dart';
import '../widgets/custom_widgets.dart';

class GiftHistoryScreen extends StatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> {
  String _activeTab = 'received';
  String _timeFilter = 'all'; // 'all', 'today', 'week', 'month'

  List<Map<String, dynamic>> _allGifts = []; // Veritabanından gelen ham liste
  List<Map<String, dynamic>> _gifts =
      []; // Ekranda gösterilen filtrelenmiş liste
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    // Alınan ya da gönderilen sekmesine göre şart belirle
    Map<String, dynamic> sart = _activeTab == 'received'
        ? {'alan_id': userId}
        : {'gonderen_id': userId};

    final res = await SqlServis.cek(tablo: 'hediye_gecmisi', sartlar: sart);

    if (res.basarili) {
      _allGifts = List<Map<String, dynamic>>.from(res.veri);
      _applyFilters(); // Filtreleme ve sıralama işlemini uygula
    } else {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 YENİ: Zaman filtrelemesini ve sıralamayı yapan fonksiyon
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allGifts);
    DateTime now = DateTime.now();

    if (_timeFilter != 'all') {
      filtered = filtered.where((item) {
        if (item['tarih'] == null) return false;
        try {
          DateTime date = DateTime.parse(item['tarih'].toString());
          if (_timeFilter == 'today') {
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          } else if (_timeFilter == 'week') {
            return now.difference(date).inDays <= 7;
          } else if (_timeFilter == 'month') {
            return date.year == now.year && date.month == now.month;
          }
        } catch (e) {
          return false;
        }
        return true;
      }).toList();
    }

    // 🔥 YENİ: Tarihe göre Yeniden Eskiye doğru sırala (En son hediye en üstte)
    filtered.sort((a, b) {
      String dateA = a['tarih']?.toString() ?? '';
      String dateB = b['tarih']?.toString() ?? '';
      return dateB.compareTo(dateA); // B'yi A'dan çıkararak Descending yaparız
    });

    setState(() {
      _gifts = filtered;
      _isLoading = false;
    });
  }

  // Tarih formatlayıcı (Örn: 29.05.2026 16:35)
  // Tarih formatlayıcı
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Tarih Yok';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hediye Geçmişi",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Üst Sekmeler (Alınan / Gönderilen)
              Container(
                decoration: BoxDecoration(
                  color: context.card,
                  border: Border(bottom: BorderSide(color: context.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabBtn(
                        'received',
                        "Alınan",
                        AppTheme.success,
                        () {
                          setState(() {
                            _activeTab = 'received';
                            _timeFilter =
                                'all'; // Sekme değişince filtreyi sıfırla
                          });
                          _loadGifts();
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildTabBtn(
                        'sent',
                        "Gönderilen",
                        AppTheme.accent,
                        () {
                          setState(() {
                            _activeTab = 'sent';
                            _timeFilter =
                                'all'; // Sekme değişince filtreyi sıfırla
                          });
                          _loadGifts();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 YENİ: Zaman Filtresi Butonları (Bugün, Bu Hafta, Bu Ay)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tümü'),
                      _buildFilterChip('today', 'Bugün'),
                      _buildFilterChip('week', 'Bu Hafta'),
                      _buildFilterChip('month', 'Bu Ay'),
                    ],
                  ),
                ),
              ),

              // Hediye Listesi
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      )
                    : _gifts.isEmpty
                    ? const Center(
                        child: Text(
                          "Bu zaman aralığında hediye kaydı bulunamadı.",
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        itemCount: _gifts.length,
                        itemBuilder: (_, index) {
                          final item = _gifts[index];
                          bool isGizli = item['gizli_mi'].toString() == '1';

                          String gosterilecekIsim;
                          if (_activeTab == 'received') {
                            gosterilecekIsim = isGizli
                                ? "Gizli Hayran"
                                : (item['gonderen_isim'] ?? 'Bilinmiyor');
                          } else {
                            gosterilecekIsim = isGizli
                                ? "${item['alan_isim'] ?? 'Bilinmiyor'} (Gizli)"
                                : (item['alan_isim'] ?? 'Bilinmiyor');
                          }

                          String formattedDate = _formatDate(
                            item['tarih']?.toString(),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item['hediye_adi']} ${item['hediye_emoji'] ?? '🎁'}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${_activeTab == 'received' ? 'Gönderen:' : 'Alıcı:'} $gosterilecekIsim",
                                        style: TextStyle(
                                          color: isGizli
                                              ? Colors.purpleAccent
                                              : context.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 13,
                                            color: context.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              color: context
                                                  .textSecondary, // Beyaz yerine dinamik tema rengi yapıldı
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(
                                        0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.accentGold.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "${item['coin_miktari']} Coin",
                                      style: const TextStyle(
                                        color: AppTheme.accentGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(
    String id,
    String label,
    Color activeColor,
    VoidCallback onTap,
  ) {
    final isActive = _activeTab == id;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : context.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isActive = _timeFilter == id;
    return GestureDetector(
      onTap: () {
        setState(() => _timeFilter = id);
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent
              : (context.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.accentLight : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : context.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
