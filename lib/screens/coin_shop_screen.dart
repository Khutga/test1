import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart';
import '../services/sql_servis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/katalog_servis.dart';

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
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: KatalogServis.coinPaketleri.value.length,
            itemBuilder: (context, index) {
              final dbPack = KatalogServis.coinPaketleri.value[index];
              final pack = {
                'amount': int.tryParse(dbPack['coin_miktari'].toString()) ?? 0,
                'bonus': int.tryParse(dbPack['bonus_miktari'].toString()) ?? 0,
                'price': "\$${dbPack['fiyat_usd']}",
                'popular': dbPack['populer_mi'].toString() == '1',
              };
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
