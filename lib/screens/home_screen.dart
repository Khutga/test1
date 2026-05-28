import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../core/mock_data.dart';
import '../widgets/custom_widgets.dart';
import 'live_view_screen.dart';

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
      body: MainBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── HEADER ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FiFi Live",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.accent,
                      ),
                    ),
                    Row(
                      children: [
                        GlassIconButton(icon: LucideIcons.search, onTap: () {}),
                        const SizedBox(width: 8),
                        GlassIconButton(icon: LucideIcons.bell, color: AppTheme.accentGold, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── TABS ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    GlassTabButton(label: 'Takip', isActive: _subTab == 'takip', onTap: () => setState(() => _subTab = 'takip')),
                    const SizedBox(width: 8),
                    GlassTabButton(label: 'Trend 🔥', isActive: _subTab == 'trend', onTap: () => setState(() => _subTab = 'trend')),
                    const SizedBox(width: 8),
                    GlassTabButton(label: 'Yeniler ✨', isActive: _subTab == 'yeni', onTap: () => setState(() => _subTab = 'yeni')),
                  ],
                ),
              ),

              // ─── STORY ROW ───
              SizedBox(
                height: 76,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: MockData.liveStreams.length,
                  itemBuilder: (context, index) {
                    final s = MockData.liveStreams[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.accent, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.accent.withOpacity(0.1),
                              child: Text(s['name'][0], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.accent)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(s['name'], style: TextStyle(fontSize: 9, color: context.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ─── GRID ───
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 90),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: MockData.liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = MockData.liveStreams[index];
                    return LiveStreamCard(
                      stream: stream,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveViewScreen(streamData: stream))),
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
}
