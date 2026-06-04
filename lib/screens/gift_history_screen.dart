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
  List<Map<String, dynamic>> _gifts = [];
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
      setState(() {
        _gifts = res.veri;
        _isLoading = false;
      });
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
              // Tabs
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
                          setState(() => _activeTab = 'received');
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
                          setState(() => _activeTab = 'sent');
                          _loadGifts();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _gifts.isEmpty
                    ? const Center(
                        child: Text(
                          "Hediye kaydı yok",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _gifts.length,
                        itemBuilder: (_, index) {
                          final item = _gifts[index];
                          String gosterilecekIsim = _activeTab == 'received'
                              ? item['gonderen_isim']
                              : item['alan_isim'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
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
                                        "${item['hediye_adi']} ${item['hediye_emoji']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${_activeTab == 'received' ? 'Gönderen:' : 'Alıcı:'} $gosterilecekIsim",
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${item['coin_miktari']} Coin",
                                      style: const TextStyle(
                                        color: AppTheme.accentGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
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
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
