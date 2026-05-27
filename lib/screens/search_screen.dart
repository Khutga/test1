import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import 'live_view_screen.dart'; // Yayına gitmek için

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStreams = [];

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStreams = []);
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredStreams = MockData.liveStreams.where((s) {
        final nameMatch = s['name'].toString().toLowerCase().contains(lowerQuery);
        final tagMatch = (s['tags'] as List).any((t) => t.toString().toLowerCase().contains(lowerQuery));
        return nameMatch || tagMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "Yayıncı, ID və ya Tag axtar...",
            hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 14),
            prefixIcon: const Icon(LucideIcons.search, color: AppColors.textGray, size: 20),
            filled: true,
            fillColor: Colors.white10,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: _searchController.text.isNotEmpty ? _buildSearchResults() : _buildExploreContent(),
    );
  }

  Widget _buildExploreContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trend Konular
          Row(
            children: const [
              Icon(LucideIcons.trendingUp, color: AppColors.primaryPink, size: 18),
              SizedBox(width: 8),
              Text("Trend Mövzular", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.trendingTags.map((tag) {
              return ActionChip(
                backgroundColor: Colors.white10,
                side: BorderSide(color: AppColors.borderWhite),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.hash, color: AppColors.textGray, size: 14),
                    const SizedBox(width: 4),
                    Text(tag['tag'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(tag['count'], style: const TextStyle(color: AppColors.textGray, fontSize: 10)),
                  ],
                ),
                onPressed: () {
                  _searchController.text = tag['tag'];
                  _onSearchChanged(tag['tag']);
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Önerilen Yayıncılar
          Row(
            children: const [
              Icon(LucideIcons.star, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text("Tövsiyə Edilən Yayınçılar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...MockData.liveStreams.take(3).map((stream) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryPurple.withOpacity(0.5),
              ),
              title: Text(stream['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text((stream['tags'] as List).join(', '), style: const TextStyle(color: AppColors.textGray, fontSize: 10)),
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Təqib Et", style: TextStyle(color: AppColors.primaryPink, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.search, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text("Nəticə tapılmadı.", style: TextStyle(color: AppColors.textGray)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredStreams.length,
      itemBuilder: (context, index) {
        final stream = _filteredStreams[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewScreen(streamData: stream))),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stream['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        children: [
                          const Icon(LucideIcons.eye, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(stream['viewers'], style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}