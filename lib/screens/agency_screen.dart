import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';

class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});

  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  String _activeTab = 'dashboard';
  double _simulatedAgencyCoins = 12000000;

  Map<String, dynamic> _getCommissionRate(double coins) {
    if (coins >= 30000000) return {"level": 4, "rate": 74, "nextQuota": null};
    if (coins >= 20000000) return {"level": 3, "rate": 68, "nextQuota": 30000000.0};
    if (coins >= 10000000) return {"level": 2, "rate": 63, "nextQuota": 20000000.0};
    if (coins >= 3000000) return {"level": 1, "rate": 59, "nextQuota": 10000000.0};
    return {"level": 0, "rate": 50, "nextQuota": 3000000.0};
  }

  @override
  Widget build(BuildContext context) {
    final quotaInfo = _getCommissionRate(_simulatedAgencyCoins);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajans Yönetim Paneli", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("FiFi Live Ajans Sistemi v2.2", style: TextStyle(fontSize: 10, color: AppColors.textGray)),
          ],
        ),
      ),
      body: MainBackground(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white10,
                border: Border(bottom: BorderSide(color: AppColors.borderWhite)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildTabBtn("İstatistik", "dashboard"),
                    _buildTabBtn("Üye Yönetimi", "members"),
                    _buildTabBtn("Ödeme & Çekim", "payout"),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _activeTab == 'dashboard' 
                    ? _buildDashboard(quotaInfo) 
                    : _activeTab == 'members' 
                        ? _buildMembersList() 
                        : const Center(child: Text("Bu bölüm yapım aşamasında")),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, String id) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]) : null,
          color: isActive ? null : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : AppColors.textGray,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> quotaInfo) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryPurple.withOpacity(0.6), Colors.black],
            ),
            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ajans Komissiya Seviyəniz", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)),
                    child: Text("LEVEL ${quotaInfo['level']}", style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_simulatedAgencyCoins.toInt().toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.amber)),
                  Text("%${quotaInfo['rate']} Pay", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Kota Simulyatoru", style: TextStyle(fontSize: 10, color: AppColors.textGray)),
              Slider(
                value: _simulatedAgencyCoins,
                min: 100000,
                max: 40000000,
                activeColor: AppColors.primaryPink,
                inactiveColor: Colors.grey[800],
                onChanged: (val) => setState(() => _simulatedAgencyCoins = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: MockData.agencyMembers.map((member) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderWhite),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryPink.withOpacity(0.2),
                child: Text(member['name'][0], style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(member['idCode'], style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: member['status'] == 'Aktif' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(member['status'], style: TextStyle(fontSize: 10, color: member['status'] == 'Aktif' ? Colors.green : Colors.red)),
              )
            ],
          ),
        );
      }).toList(),
    );
  }



}