import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _subTab = 'trend';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "FiFi Live",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: AppColors.primaryPink,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.search, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.zap, color: Colors.yellow), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Sub-Tab Navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildTabBtn('takip', 'Takip'),
                const SizedBox(width: 24),
                _buildTabBtn('trend', 'Trend'),
                const SizedBox(width: 24),
                _buildTabBtn('yeni', 'Yeni Başlayanlar'),
              ],
            ),
          ),
          const Divider(color: AppColors.borderWhite),
          
          // Live Streams Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: MockData.liveStreams.length,
              itemBuilder: (context, index) {
                final stream = MockData.liveStreams[index];
                return _buildStreamCard(stream);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String id, String label) {
    final isActive = _subTab == id;
    return GestureDetector(
      onTap: () => setState(() => _subTab = id),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textGray,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 16,
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(2),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[800], // Resim placeholder
      ),
      child: Stack(
        children: [
          // Canlı Etiketi
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("CANLI", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          // İsim ve Tagler
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stream['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: (stream['tags'] as List).map((tag) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 9)),
                  )).toList(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}