import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ajans Paneli", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary)),
            Text("v2.2", style: TextStyle(fontSize: 9, color: context.textSecondary)),
          ],
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Tabs
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.border))),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _buildTabBtn("İstatistik", "dashboard"),
                    _buildTabBtn("Üye Yönetimi", "members"),
                    _buildTabBtn("Ödeme & Çekim", "payout"),
                  ]),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _activeTab == 'dashboard'
                      ? _buildDashboard(quotaInfo)
                      : _activeTab == 'members'
                          ? _buildMembersList()
                          : Center(child: Text("Yapım aşamasında", style: TextStyle(color: context.textSecondary))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, String id) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent : (context.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? Colors.white : context.textSecondary)),
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> quotaInfo) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Komisyon Seviyesi", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accentGold, borderRadius: BorderRadius.circular(8)),
                child: Text("LEVEL ${quotaInfo['level']}", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_simulatedAgencyCoins.toInt().toString(), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accentGold)),
              Text("%${quotaInfo['rate']} Pay", style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text("Kota Simülatörü", style: TextStyle(fontSize: 9, color: context.textSecondary)),
          Slider(
            value: _simulatedAgencyCoins, min: 100000, max: 40000000,
            activeColor: AppTheme.accent,
            inactiveColor: context.border,
            onChanged: (val) => setState(() => _simulatedAgencyCoins = val),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      children: MockData.agencyMembers.map((member) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: GlassContainer(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                GlowAvatar(initial: member['name'][0], radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: context.textPrimary)),
                      Text(member['idCode'], style: TextStyle(fontSize: 9, color: context.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (member['status'] == 'Aktif' ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    member['status'],
                    style: TextStyle(fontSize: 9, color: member['status'] == 'Aktif' ? AppTheme.success : AppTheme.danger, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
