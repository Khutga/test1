import 'package:flutter/material.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

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
        backgroundColor: AppColors.cardBackground,
        title: const Text("Hediye Geçmişi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: MainBackground(
        child: Column(
          children: [
            Container(
              color: AppColors.cardBackground,
              child: Row(
                children: [
                  Expanded(child: _buildTabBtn('received', "Alınan Hediyeler", AppColors.primaryPink)),
                  Expanded(child: _buildTabBtn('sent', "Gönderilen Hediyeler", AppColors.primaryPurple)),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: activeList.length,
                itemBuilder: (context, index) {
                  final item = activeList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderWhite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['gift'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("${_activeTab == 'received' ? 'Gönderen:' : 'Alıcı:'} ${item['name']}", style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(item['date'], style: const TextStyle(color: AppColors.textGray, fontSize: 10)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            border: Border.all(color: Colors.amber.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(item['cost'], style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String id, String label, Color activeColor) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AppColors.textGray,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}