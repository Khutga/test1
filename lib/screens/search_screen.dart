import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';
import 'live_view_screen.dart';

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
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(fontSize: 13, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: "Yayıncı, ID veya etiket ara...",
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
            prefixIcon: Icon(LucideIcons.search, color: context.textSecondary, size: 18),
            filled: true,
            fillColor: context.isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: _searchController.text.isNotEmpty ? _buildSearchResults() : _buildExploreContent(),
        ),
      ),
    );
  }

  Widget _buildExploreContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.trendingUp, color: AppTheme.accent, size: 15),
              const SizedBox(width: 6),
              Text("Trend Konular", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MockData.trendingTags.map((tag) {
              return ActionChip(
                backgroundColor: context.card,
                side: BorderSide(color: context.border),
                visualDensity: VisualDensity.compact,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.hash, color: context.textSecondary, size: 12),
                    const SizedBox(width: 3),
                    Text(tag['tag'], style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(tag['count'], style: TextStyle(color: context.textSecondary, fontSize: 9)),
                  ],
                ),
                onPressed: () {
                  _searchController.text = tag['tag'];
                  _onSearchChanged(tag['tag']);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(LucideIcons.star, color: AppTheme.accentGold, size: 15),
              const SizedBox(width: 6),
              Text("Önerilen Yayıncılar", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
          ...MockData.liveStreams.take(3).map((stream) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: GlowAvatar(initial: stream['name'][0], radius: 18),
              title: Text(stream['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: context.textPrimary)),
              subtitle: Text((stream['tags'] as List).join(', '), style: TextStyle(color: context.textSecondary, fontSize: 10)),
              trailing: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.accent.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Takip Et", style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 40, color: context.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text("Sonuç bulunamadı.", style: TextStyle(color: context.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: _filteredStreams.length,
      itemBuilder: (context, index) {
        final stream = _filteredStreams[index];
        return LiveStreamCard(
          stream: stream,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewScreen(streamData: stream))),
        );
      },
    );
  }
}
