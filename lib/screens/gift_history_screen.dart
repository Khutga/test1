import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';

class GiftHistoryScreen extends StatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> {
  String _activeTab = 'received';

  @override
  Widget build(BuildContext context) {
    final activeList = _activeTab == 'received' ? MockData.receivedGifts : MockData.sentGifts;

    return Scaffold(
      appBar: AppBar(
        title: Text("Hediye Geçmişi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Tabs
              Container(
                decoration: BoxDecoration(color: context.card, border: Border(bottom: BorderSide(color: context.border))),
                child: Row(
                  children: [
                    Expanded(child: _buildTabBtn('received', "Alınan", AppTheme.success)),
                    Expanded(child: _buildTabBtn('sent', "Gönderilen", AppTheme.accent)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: activeList.length,
                  itemBuilder: (_, index) {
                    final item = activeList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['gift'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary)),
                                const SizedBox(height: 2),
                                Text("${_activeTab == 'received' ? 'Gönderen:' : 'Alıcı:'} ${item['name']}", style: TextStyle(color: context.textSecondary, fontSize: 14)),
                                Text(item['date'], style: TextStyle(color: context.textSecondary, fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(item['cost'], style: TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _buildTabBtn(String id, String label, Color activeColor) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isActive ? activeColor : context.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
