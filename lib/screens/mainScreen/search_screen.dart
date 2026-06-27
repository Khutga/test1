import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../services/shared_stream_data.dart';
import '../../widgets/custom_widgets.dart';
import '../accountScreen/profilGoster/user_profile_screen.dart';
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

  List<Map<String, dynamic>> _userSearchResults = [];
  bool _isSearchingUsers = false;

  // 🔥 Önerilen Kullanıcılar için değişkenlerimiz
  List<Map<String, dynamic>> _suggestedUsers = [];
  bool _isSuggestedLoading = true;
  String _myGender = "Belirtilmemiş"; // Kendi cinsiyetimizi tutacağız

  bool _isLoading = true;
  String _myUsername = "Misafir";

  int _currentUsersPage = 0;
  bool _hasMoreUsers = false;
  bool _isMoreUsersLoading = false;
  String _lastSearchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadMyUserData();

    SharedStreamData.streamsNotifier.addListener(_onStreamsUpdated);
    _onStreamsUpdated();
  }

  @override
  void dispose() {
    SharedStreamData.streamsNotifier.removeListener(_onStreamsUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onStreamsUpdated() {
    if (!mounted) return;
    setState(() {
      _allActiveStreams = List<Map<String, dynamic>>.from(
        SharedStreamData.streamsNotifier.value,
      );
      _allActiveStreams.shuffle();
      _isLoading = false;

      if (_searchController.text.isNotEmpty) {
        _onSearchChanged(_searchController.text);
      }
    });
  }

  Future<void> _loadMyUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final int userId = prefs.getInt('kullanici_id') ?? 1;

    try {
      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: {'id': userId},
      );

      if (res.basarili && res.veri.isNotEmpty && mounted) {
        setState(() {
          _myUsername = res.veri.first['kullanici_adi'] ?? "Misafir_$userId";
          _myGender = res.veri.first['cinsiyet'] ?? "Belirtilmemiş";
        });
      }
    } catch (e) {
      debugPrint("Kendi verimi çekerken hata: $e");
    } finally {
      // 🔥 ÇÖZÜM: Hata olsa da, veri boş gelse de mutlaka yüklemeyi başlat!
      if (mounted) {
        _loadSuggestedUsers();
      }
    }
  }

  // 🔥 GÜNCELLENEN FONKSİYON: Önerilen (Zıt Cinsiyet ve Yeni) Kullanıcıları Çeker
  Future<void> _loadSuggestedUsers() async {
    final ajansRes = await SqlServis.cek(
      tablo: 'ajans_uyeleri',
      sartlar: {'onay_durumu': 'onaylandı'},
    );
    Set<int> ajansliKullaniciIdleri = {};
    if (ajansRes.basarili) {
      ajansliKullaniciIdleri = ajansRes.veri
          .map((u) => int.parse(u['kullanici_id'].toString()))
          .toSet();
    }
    if (!mounted) return;
    setState(() => _isSuggestedLoading = true);

    // Kendi cinsiyetimize göre hedef cinsiyeti belirliyoruz
    String hedefCinsiyet = "";
    if (_myGender.toLowerCase() == "kadın") {
      hedefCinsiyet = "Erkek";
    } else if (_myGender.toLowerCase() == "erkek") {
      hedefCinsiyet = "Kadın";
    }

    Map<String, dynamic> querySartlar = {};
    if (hedefCinsiyet.isNotEmpty) {
      querySartlar['cinsiyet'] = hedefCinsiyet;
    }

    try {
      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: querySartlar, // Eğer cinsiyet bulunamazsa herkesi çeker
      );

      if (res.basarili && res.veri.isNotEmpty && mounted) {
        List<Map<String, dynamic>> users = List<Map<String, dynamic>>.from(
          res.veri,
        );

        // 🔥 KENDİMİZİ LİSTEDEN ÇIKARTIYORUZ
        users.removeWhere((u) => u['kullanici_adi'] == _myUsername);

        // En yeniler en başta olsun (ID değerine göre büyükten küçüğe sıralıyoruz)
        users.sort((a, b) {
          int idA = int.tryParse(a['id'].toString()) ?? 0;
          int idB = int.tryParse(b['id'].toString()) ?? 0;
          return idB.compareTo(idA); // Büyük ID (Yeni kayıt) üstte
        });

        setState(() {
          // Performans için sadece ilk 15 kişiyi vitrinde gösteriyoruz
          _suggestedUsers = users.take(15).toList();
          _isSuggestedLoading = false;
        });
      } else {
        if (mounted) setState(() => _isSuggestedLoading = false);
      }
    } catch (e) {
      debugPrint("Önerilenleri çekerken hata: $e");
      if (mounted) setState(() => _isSuggestedLoading = false);
    }
  }

  // 🔥 YENİ FONKSİYON: Önerilen (Zıt Cinsiyet ve Yeni) Kullanıcıları Çeker

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredStreams = [];
        _userSearchResults = [];
        _isSearchingUsers = false;
        _currentUsersPage = 0;
        _hasMoreUsers = false;
        _lastSearchQuery = "";
      });
      return;
    }

    final lowerQuery = query.toLowerCase();

    setState(() {
      _lastSearchQuery = query;
      _currentUsersPage = 0;
      _filteredStreams = _allActiveStreams.where((s) {
        final nameMatch = (s['yayin_sahibi_isim'] ?? '')
            .toString()
            .toLowerCase()
            .contains(lowerQuery);
        final tagMatch = (s['etiket'] ?? '').toString().toLowerCase().contains(
          lowerQuery,
        );
        return nameMatch || tagMatch;
      }).toList();
      _isSearchingUsers = true;
    });

    try {
      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        islem: 'arama_cek',
        sartlar: {'kullanici_adi': query, 'sayfa': _currentUsersPage},
      );

      if (mounted && _lastSearchQuery == query) {
        setState(() {
          _isSearchingUsers = false;
          if (res.basarili && res.veri != null) {
            _userSearchResults = List<Map<String, dynamic>>.from(res.veri);
            _hasMoreUsers = res.veri.length == 20;
          } else {
            _userSearchResults = [];
            _hasMoreUsers = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingUsers = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isMoreUsersLoading || !_hasMoreUsers) return;

    setState(() => _isMoreUsersLoading = true);
    int nextPage = _currentUsersPage + 1;

    try {
      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        islem: 'arama_cek',
        sartlar: {'kullanici_adi': _lastSearchQuery, 'sayfa': nextPage},
      );

      if (mounted) {
        setState(() {
          _isMoreUsersLoading = false;
          if (res.basarili && res.veri != null) {
            _currentUsersPage = nextPage;
            _userSearchResults.addAll(
              List<Map<String, dynamic>>.from(res.veri),
            );
            _hasMoreUsers = res.veri.length == 20;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isMoreUsersLoading = false);
    }
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
            hintText: "Yayıncı, etiket veya kullanıcı ara...",
            hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
            prefixIcon: Icon(
              LucideIcons.search,
              color: context.textSecondary,
              size: 18,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: context.textSecondary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: context.isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.08),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppTheme.accent,
            backgroundColor: AppTheme.accent,
            onRefresh: () async {
              await SharedStreamData.fetchStreams();
              _loadSuggestedUsers(); // Yenilemede önerilenleri de tazele
            },
            child: _isLoading && _allActiveStreams.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  )
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
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 12,
            ),
            child: Text(
              "🔥 Trend Etiketler",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
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

          const SizedBox(height: 24),

          // 🔥 YENİ EKLENEN BÖLÜM: ÖNERİLEN KULLANICILAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "💫 Önerilen Kullanıcılar",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ),
          if (_isSuggestedLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else if (_suggestedUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Şu an önerilecek kullanıcı bulunamadı.",
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal, // Yatay kaydırma
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _suggestedUsers.length,
                itemBuilder: (context, index) {
                  final user = _suggestedUsers[index];
                  final String targetUsername =
                      user['kullanici_adi'] ?? 'Bilinmiyor';
                  final String isim = user['isim'] ?? targetUsername;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          hedefKullaniciAdi: targetUsername,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GlowAvatar(
                            initial: isim[0].toUpperCase(),
                            radius: 30,
                            color: AppTheme.accent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            targetUsername,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 20),

          // ÖNERİLEN YAYINLAR BÖLÜMÜ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "✨ Önerilen Yayınlar",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          ),
          _allActiveStreams.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Center(
                    child: Text(
                      "Şu an önerilecek aktif yayın yok.",
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
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
                            hostName:
                                stream['yayin_sahibi_isim'] ?? 'Bilinmiyor',
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
        child: Center(
          child: Text(
            "#$label",
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredStreams.isEmpty &&
        _userSearchResults.isEmpty &&
        !_isSearchingUsers) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 150),
          Icon(
            LucideIcons.search,
            size: 40,
            color: context.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Sonuç bulunamadı.",
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_isSearchingUsers || _userSearchResults.isNotEmpty) ...[
          Text(
            "Kullanıcılar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_isSearchingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _userSearchResults.length,
              separatorBuilder: (_, __) =>
                  Divider(color: context.border.withOpacity(0.5)),
              itemBuilder: (context, index) {
                final user = _userSearchResults[index];
                final targetUsername = user['kullanici_adi'] ?? 'Bilinmiyor';

                // 🔥 Ripple hatasını düzelttiğimiz Material wrapper burada duruyor
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.accent.withOpacity(0.2),
                      child: Icon(
                        LucideIcons.user,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      targetUsername,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      color: context.textSecondary,
                      size: 18,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            hedefKullaniciAdi: targetUsername,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (_hasMoreUsers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _isMoreUsersLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _loadMoreUsers,
                        icon: const Icon(
                          LucideIcons.arrowDown,
                          size: 16,
                          color: AppTheme.accent,
                        ),
                        label: const Text(
                          "Daha Fazla Kullanıcı Göster",
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
          ],
          const SizedBox(height: 24),
        ],

        if (_filteredStreams.isNotEmpty) ...[
          Text(
            "Canlı Yayınlar",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
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
          ),
        ],
      ],
    );
  }
}
