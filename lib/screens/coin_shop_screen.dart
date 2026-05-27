import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

class CoinShopScreen extends StatefulWidget {
  const CoinShopScreen({super.key});

  @override
  State<CoinShopScreen> createState() => _CoinShopScreenState();
}

class _CoinShopScreenState extends State<CoinShopScreen> {
  int _userCoins = 54200; // Normalde bu State Management'tan (Riverpod vb.) gelir.

  void _showCheckoutSheet(BuildContext context, Map<String, dynamic> pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Ödeme Simülatörü", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${pack['amount']} Coin", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(pack['price'], style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Satın alma işlemi simülasyonu
                    Navigator.pop(ctx);
                    setState(() {
                      _userCoins += (pack['amount'] + pack['bonus']) as int;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Tebrikler! Coin yüklendi. Yeni bakiye: $_userCoins"), backgroundColor: Colors.green),
                    );
                  },
                  child: Text("Ödemeyi Tamamla (${pack['price']})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FiFi Coin Mağazası", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Güncel Bakiyeniz: $_userCoins Coin", style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: MockData.coinPackages.length,
        itemBuilder: (context, index) {
          final pack = MockData.coinPackages[index];
          return GestureDetector(
            onTap: () => _showCheckoutSheet(context, pack),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: pack['popular'] ? AppColors.primaryPink : AppColors.borderWhite),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pack['popular'])
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryPink, borderRadius: BorderRadius.circular(8)),
                      child: const Text("POPÜLER", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(pack['amount'].toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  if (pack['bonus'] > 0)
                    Text("+${pack['bonus']} Bonus", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(pack['price'], style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}