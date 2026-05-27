import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
            Text("Ajans İdarəetmə Paneli", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("FiFi Live Ajans Sistemi v2.2", style: TextStyle(fontSize: 10, color: AppColors.textGray)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Yatay Sekmeler
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
                  _buildTabBtn("Üzv İdarəetmə", "members"),
                  _buildTabBtn("Ödəniş & Çəkim", "payout"),
                  // Diğer sekmeleri de buraya ekleyebilirsin
                ],
              ),
            ),
          ),
          
          // İçerik Alanı
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
        // İstatistik Kartı
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
              // Slider Simülatörü
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

  Widget _buildRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ajansa Katılmaq İstəyənlər", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ...MockData.joinRequests.map((req) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderWhite),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("ID: ${req['idCode']} • Level ${req['level']}", style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                      ],
                    ),
                    Text(req['requestDate'], style: const TextStyle(fontSize: 10, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.borderWhite, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Həftəlik hədəf: ${req['expectedHours']} saat", style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {}, // Reddet logic
                          child: const Text("Rədd Et", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {}, // Kabul logic
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12), minimumSize: const Size(0, 32)),
                          icon: const Icon(LucideIcons.userCheck, color: Colors.black, size: 14),
                          label: const Text("Təsdiqlə", style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }

  Widget _buildAssistants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Asistan İdarəetmə Sistemi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Yeni Asistan Təyin Et", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textGray)),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: "Asistan Adı / ID",
                  hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 12),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(LucideIcons.plus, color: Colors.white, size: 16),
                  label: const Text("Təyin Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...MockData.assistants.map((ass) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ass['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(ass['role'], style: const TextStyle(fontSize: 10, color: AppColors.primaryPurple, fontWeight: FontWeight.bold)),
                    Text("ID: ${ass['idCode']} • ${ass['joinDate']}", style: const TextStyle(fontSize: 9, color: AppColors.textGray)),
                  ],
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                  style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                )
              ],
            ),
          );
        }).toList()
      ],
    );
  }

  Widget _buildInvite() {
    const String inviteCode = "AG-938X221-FIFI";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text("🎫", style: TextStyle(fontSize: 36)),
        ),
        const SizedBox(height: 16),
        const Text("Xüsusi Üzv Dəvət Kodu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "Yeni yayınçıları bu kodla ajansınıza qeydiyyatdan keçirin, gəlirlərindən faiz qazanın!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textGray),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderWhite),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(inviteCode, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPink, letterSpacing: 2)),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kod Kopyalandı!")));
                },
                icon: const Icon(LucideIcons.copy, color: AppColors.primaryPink, size: 18),
                style: IconButton.styleFrom(backgroundColor: AppColors.primaryPink.withOpacity(0.1)),
              )
            ],
          ),
        ),
      ],
    );
  }
}