import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/adminScreen/coin_paketleri_tab.dart';
import 'package:nivi/screens/adminScreen/hediyeler_tab.dart';
import 'package:nivi/screens/adminScreen/kullanicilar_tab.dart';
import 'package:nivi/screens/adminScreen/ajanslar_tab.dart';
import 'package:nivi/screens/adminScreen/iliskiler_tab.dart';
import 'package:nivi/screens/adminScreen/ayarlar_tab.dart';
import '../../core/app_colors.dart';
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
    _tabController = TabController(length: 6, vsync: this);
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
            Tab(text: "❤️ İlişkiler"),
            Tab(text: "⚙️ Ayarlar"),
          ],
        ),
      ),
      body: MainBackground(
        child: TabBarView(
          controller: _tabController,
          children: const [
            CoinPaketleriTab(),
            HediyelerTab(),
            KullanicilarTab(),
            AjanslarTab(),
            IliskilerTab(),
            AyarlarTab(),
          ],
        ),
      ),
    );
  }
}