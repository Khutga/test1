import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../services/shared_stream_data.dart'; // 🔥 Ortak Havuz
import '../../widgets/custom_widgets.dart';
import '../liveScreen/audience_live_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allActiveStreams = [];
  List<Map<String, dynamic>> _filteredStreams = [];
  bool _isLoading = true;
  String _myUsername = "Misafir"; 

  @override
  void initState() {
    super.initState();
    _loadMyUserData();
    
    // Havuzu dinle!
    SharedStreamData.streamsNotifier.addListener(_onStreamsUpdated);
    _onStreamsUpdated(); // İlk açılış verisini bağla
  }

  @override
  void dispose() {
    SharedStreamData.streamsNotifier.removeListener(_onStreamsUpdated);
    super.dispose();
  }

  // Havuz her güncellendiğinde burası çalışır
  void _onStreamsUpdated() {
    if (!mounted) return;
    setState(() {
      // Veriyi havuzdan alıp karıştırıyoruz (Orijinal listeyi bozmamak için List.from kullandık)
      _allActiveStreams = List<Map<String, dynamic>>.from(SharedStreamData.streamsNotifier.value);
      _allActiveStreams.shuffle(); 
      _isLoading = false;
      
      // Eğer kullanıcı o sırada arama yapıyorsa, arama sonuçlarını da anında tazele
      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text);
      }
    });
  }

  Future<void> _loadMyUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    final res = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': userId},
    );

    if (res.basarili && res.veri.isNotEmpty && mounted) {
      setState(() {
        _myUsername = res.veri.first['kullanici_adi'] ?? "Misafir_$userId";
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredStreams = []);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredStreams = _allActiveStreams.where((s) {
        final nameMatch = (s['yayin_sahibi_isim'] ?? '').toString().toLowerCase().contains(lowerQuery);
        final tagMatch = (s['etiket'] ?? '').toString().toLowerCase().contains(lowerQuery);
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
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: "Yayıncı veya etiket ara...",
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
            prefixIcon: Icon(LucideIcons.search, color: context.textSecondary, size: 18),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(LucideIcons.x, color: context.textSecondary, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
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
          child: RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.accent,
            // 🔥 AŞAĞI ÇEKİNCE ORTAK HAVUZU GÜNCELLER, ANA SAYFA BİLE GÜNCELLENİR
            onRefresh: () async => await SharedStreamData.fetchStreams(),
            child: _isLoading && _allActiveStreams.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _searchController.text.isNotEmpty
                    ? _buildSearchResults()
                    : _buildExploreContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 12),
            child: Text("🔥 Trend Etiketler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildTagChip("Sohbet"),
                _buildTagChip("Oyun"),
                _buildTagChip("Müzik"),
                _buildTagChip("Eğlence"),
                _buildTagChip("Dans"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text("✨ Önerilen Yayınlar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
          ),

          _allActiveStreams.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Center(child: Text("Şu an önerilecek aktif yayın yok.", style: TextStyle(color: context.textSecondary))),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10,
                  ),
                  itemCount: _allActiveStreams.length,
                  itemBuilder: (context, index) {
                    final stream = _allActiveStreams[index];
                    return LiveStreamCard(
                      stream: stream,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudienceLivePage(
                            roomName: stream['oda_adi'],
                            username: _myUsername, 
                            hostName: stream['yayin_sahibi_isim'] ?? 'Bilinmiyor', 
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchController.text = label;
          _onSearchChanged(label);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
        ),
        child: Center(child: Text("#$label", style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13))),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredStreams.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          Icon(LucideIcons.search, size: 40, color: context.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 8),
          Center(child: Text("Sonuç bulunamadı.", style: TextStyle(color: context.textSecondary, fontSize: 13))),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(), 
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: _filteredStreams.length,
      itemBuilder: (context, index) {
        final stream = _filteredStreams[index];
        return LiveStreamCard(
          stream: stream,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AudienceLivePage(
                roomName: stream['oda_adi'],
                username: _myUsername, 
                hostName: stream['yayin_sahibi_isim'] ?? 'Bilinmiyor',
              ),
            ),
          ),
        );
      },
    );
  }
}