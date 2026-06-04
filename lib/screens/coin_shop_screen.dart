import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';
import '../services/sql_servis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinShopScreen extends StatefulWidget {
  const CoinShopScreen({super.key});

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  int _userCoins = 0;
  int _userId = 1;
  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;
    final res = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': _userId},
    );
    if (res.basarili && res.veri.isNotEmpty) {
      setState(
        () => _userCoins =
            (double.tryParse(
                      res.veri.first['birinci_coin_bakiye'].toString(),
                    ) ??
                    0)
                .toInt(),
      );
    }
  }

  void _showCheckoutSheet(BuildContext context, Map<String, dynamic> pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ödeme Simülatörü",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${pack['amount']} Coin",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    pack['price'],
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          PremiumButton(
              text: "Ödemeyi Tamamla (${pack['price']})",
              onPressed: () async {
                Navigator.pop(ctx);
                int yeniBakiye = _userCoins + ((pack['amount'] + pack['bonus']) as int);
                
                var res = await SqlServis.guncelle(
                  tablo: 'hesaplar', 
                  veriler: {'birinci_coin_bakiye': yeniBakiye}, 
                  sartlar: {'id': _userId}
                );
                
                if (res.basarili) {
                  setState(() => _userCoins = yeniBakiye);
                  if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Coin yüklendi: $_userCoins"), backgroundColor: AppTheme.success));
                }
              },
            ),
          ],
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
            Text(
              "Coin Mağazası",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            Text(
              "Bakiye: $_userCoins Coin",
              style: TextStyle(fontSize: 9, color: context.textSecondary),
            ),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: MockData.coinPackages.length,
            itemBuilder: (_, index) {
              final pack = MockData.coinPackages[index];
              return GestureDetector(
                onTap: () => _showCheckoutSheet(context, pack),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.card,
                    border: Border.all(
                      color: pack['popular'] ? AppTheme.accent : context.border,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pack['popular'])
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "POPÜLER",
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("🪙", style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            pack['amount'].toString(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (pack['bonus'] > 0)
                        Text(
                          "+${pack['bonus']} Bonus",
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        pack['price'],
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
