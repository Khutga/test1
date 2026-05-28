import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/live.dart';
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "FiFi Live",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: AppColors.primaryPink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        GlassIconButton(icon: LucideIcons.search, onTap: () {}),
                        const SizedBox(width: 12),
                        GlassIconButton(
                          icon: LucideIcons.zap,
                          color: Colors.amber,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GlassTabButton(
                      label: 'Takip',
                      isActive: _subTab == 'takip',
                      onTap: () => setState(() => _subTab = 'takip'),
                    ),
                    const SizedBox(width: 16),
                    GlassTabButton(
                      label: 'Trend🔥',
                      isActive: _subTab == 'trend',
                      onTap: () => setState(() => _subTab = 'trend'),
                    ),
                    const SizedBox(width: 16),
                    GlassTabButton(
                      label: 'Yeniler✨',
                      isActive: _subTab == 'yeni',
                      onTap: () => setState(() => _subTab = 'yeni'),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: MockData.liveStreams.length,
                  itemBuilder: (context, index) {
                    final s = MockData.liveStreams[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primaryPink,
                                  AppColors.primaryPurple,
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.cardBackground,
                              child: Text(
                                s['name'][0],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['name'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20).copyWith(bottom: 100),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: MockData.liveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = MockData.liveStreams[index];
                    return LiveStreamCard(
                      stream: stream,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveViewScreen(streamData: stream),
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
}
