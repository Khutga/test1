import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/widgets/custom_widgets.dart';
import '/core/app_colors.dart';
import '/services/sql_servis.dart';
import '../../services/katalog_servis.dart';

// --- YARDIMCI SINIFLAR ---
class ChatMessage {
  final String sender;
  final String text;
  final bool isSystem;
  ChatMessage({
    required this.sender,
    required this.text,
    this.isSystem = false,
  });
}

class FloatingGift {
  final int id;
  final double left;
  final String emoji;
  FloatingGift({required this.id, required this.left, required this.emoji});
}

// --- ANA SAYFA ---
class AudienceLivePage extends StatefulWidget {
  final String username;
  final String hostName;
  final String roomName;

  const AudienceLivePage({
    super.key,
    required this.username,
    required this.hostName,
    required this.roomName,
  });

  @override
  State<AudienceLivePage> createState() => _AudienceLivePageState();
}

class _AudienceLivePageState extends State<AudienceLivePage> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  bool _isLoading = true;
  int _viewerCount = 0;
  String _activeRoomName = "";
  String _activeHostName = "";

  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  final Random _random = Random();

  // --- ARAYÜZ GİZLEME VE HEDİYE PANELİ ---
  bool _isUiVisible = true;
  bool _showGiftPanel = false;
  int _coinBalance = 0; // birinci_coin_bakiye

  // --- PK BATTLE DEĞİŞKENLERİ ---
  bool _isPkActive = false;
  String _pkOpponentName = "";
  int _pkTimeLeft = 120;
  int _hostScore = 0;
  int _opponentScore = 0;
  String _selectedGiftTarget = "";

  final String apiServerUrl = 'https://yayin.sunucucodefellas.shop';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';
  final String phpApiUrl = 'http://codefellas.com.tr/apps/nivi/api/api.php';
  final String phpApiKey = 'GizliAnahtar_Codefellas_2026!';

  // HEDİYE LİSTESİ
  List<Map<String, dynamic>> get _giftCatalog =>
      KatalogServis.yayinHediyeleri.value;
  Timer?
  _roomCheckTimer; // Odanın veritabanında olup olmadığını kontrol eden bekçi

  @override
  void initState() {
    super.initState();
    _activeRoomName = widget.roomName;
    _activeHostName = widget.hostName;
    _selectedGiftTarget = _activeHostName;

    _fetchCoinBalance();
    _connectToLiveKit(_activeRoomName);

    _startRoomCheckTimer(); // 🔥 BEKÇİYİ BURADA BAŞLATIYORUZ!
  }

  // ==========================================
  // SQL BAKİYE İŞLEMLERİ (YENİ MİMARİ)
  // ==========================================
  Future<void> _fetchCoinBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // 🔥 DÜZELTME: Artık gerçek kullanıcı ID'sini hafızadan alıyoruz
      final int? kayitliId = prefs.getInt('kullanici_id');

      if (kayitliId == null) return;

      final res = await SqlServis.cek(
        tablo: 'hesaplar',
        sartlar: {'id': kayitliId},
      );

      if (res.basarili && res.veri.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          print("Çekilen Bakiye: ${res.veri[0]['birinci_coin_bakiye']}");
          _coinBalance =
              (double.tryParse(res.veri[0]['birinci_coin_bakiye'].toString()) ??
                      0.0)
                  .toInt();
        });
      }
    } catch (e) {
      debugPrint("Bakiye Çekme Hatası: $e");
    }
  } // ==========================================

  // HAYALET ODA KONTROLÜ (GÜVENLİK)
  // ==========================================
  void _startRoomCheckTimer() {
    _roomCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Eğer zaten çıkıyorsak veya yükleniyorsa işlem yapma
      if (!mounted || _isLoading || _activeRoomName.isEmpty) return;

      try {
        final res = await SqlServis.cek(
          tablo: 'aktif_yayinlar',
          sartlar: {'oda_adi': _activeRoomName},
        );

        if (!mounted) return;

        // İstek başarılı oldu fakat oda bulunamadıysa (Yayın silinmiş demektir!)
        if (res.basarili && res.veri.isEmpty) {
          _roomCheckTimer?.cancel(); // Bekçiyi durdur

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Yayın sona erdi."),
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Odayı kapat ve sayfadan at!
          _room?.disconnect();
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint("Oda kontrol hatası: $e");
      }
    });
  }

  Future<void> _updateCoinBalance(int yeniBakiye) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int? kayitliId = prefs.getInt('kullanici_id');
      if (kayitliId == null) return;

      await http.post(
        Uri.parse(phpApiUrl),
        body: {
          'api_key': phpApiKey,
          'islem': 'guncelle',
          'tablo': 'hesaplar',
          'veriler': jsonEncode({'birinci_coin_bakiye': yeniBakiye}),
          'sartlar': jsonEncode({'id': kayitliId}),
          'geri_dondur': '',
        },
      );
    } catch (e) {
      debugPrint("Bakiye Güncelleme Hatası: $e");
    }
  }

  // ==========================================
  // LIVEKIT BAĞLANTISI
  // ==========================================
  Future<void> _connectToLiveKit(String targetRoom) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$apiServerUrl/get_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room': targetRoom,
          'username': widget.username,
          'is_host': false,
        }),
      );

      final responseData = jsonDecode(response.body);
      final token = responseData['token'];
      _activeRoomName = responseData['actual_room'] ?? targetRoom;

      _room = Room();
      _listener = _room?.createListener();

      _listener?.on<ParticipantConnectedEvent>((e) => _updateViewerCount());
      _listener?.on<ParticipantDisconnectedEvent>((e) {
        _updateViewerCount();
        if (e.participant != null)
          setState(() => _remoteVideoTracks.remove(e.participant!.identity));
      });

      _listener?.on<TrackSubscribedEvent>((event) {
        if (!mounted) return;
        if (event.track is VideoTrack && event.participant != null) {
          setState(
            () => _remoteVideoTracks[event.participant!.identity] =
                event.track as VideoTrack,
          );
        }
      });

      _listener?.on<TrackUnsubscribedEvent>((event) {
        if (!mounted) return;
        if (event.track is VideoTrack && event.participant != null) {
          setState(
            () => _remoteVideoTracks.remove(event.participant!.identity),
          );
        }
      });

      _listener?.on<DataReceivedEvent>((event) {
        if (!mounted) return;
        final decoded = utf8.decode(event.data);
        final msgData = jsonDecode(decoded);
        final type = msgData['type'];

        if (type == 'chat') {
          _addChatMessage(msgData['sender'], msgData['text']);
        } else if (type == 'gift') {
          final points = msgData['points'];
          final receiver = msgData['receiver'];

          if (msgData['icon'] != null)
            _triggerFloatingAnimation(msgData['icon']);
          _addChatMessage(
            "Sistem",
            "${msgData['sender']}, $receiver'a ${msgData['icon']} attı!",
            isSystem: true,
          );

          if (_isPkActive) {
            setState(() {
              if (receiver == _activeHostName)
                _hostScore += (points as int);
              else if (receiver == _pkOpponentName)
                _opponentScore += (points as int);
            });
          }
        } else if (type == 'pk_invite' &&
            msgData['target'] == widget.username) {
          _showPkInviteDialog(msgData['sender'], msgData['targetRoom']);
        } else if (type == 'pk_start') {
          setState(() {
            _isPkActive = true;
            _pkOpponentName = msgData['opponent'];
            _hostScore = 0;
            _opponentScore = 0;
          });
        } else if (type == 'pk_tick') {
          setState(() => _pkTimeLeft = msgData['time']);
        } else if (type == 'pk_end') {
          setState(() => _isPkActive = false);
          _addChatMessage("Sistem", "PK Sona Erdi!", isSystem: true);
        } else if (type == 'room_merging') {
          _addChatMessage(
            "Sistem",
            "Yayıncı ortak yayına katılıyor, yönlendiriliyorsunuz...",
            isSystem: true,
          );
          _room?.disconnect();
          _connectToLiveKit(msgData['target_room']);
        } else if (type == 'room_closed') {
          Navigator.pop(context);
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );
      if (mounted)
        setState(() {
          _isLoading = false;
          _updateViewerCount();
        });
    } catch (e) {
      _addChatMessage("Sistem", "Bağlantı Hatası", isSystem: true);
    }
  }

  void _updateViewerCount() =>
      setState(() => _viewerCount = _room?.remoteParticipants.length ?? 0);

  // ==========================================
  // PK KABUL ETME
  // ==========================================
  void _showPkInviteDialog(String host, String hostRoom) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text("⚔️ ", style: TextStyle(fontSize: 20)),
            Text(
              "Meydan Okuma!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "$host seni PK'ya davet ediyor. Kabul edersen onun yayınına bağlanacaksın!",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              final payload = jsonEncode({
                'type': 'pk_reject',
                'sender': widget.username,
              });
              _room?.localParticipant?.publishData(
                utf8.encode(payload),
                reliable: true,
              );
            },
            child: const Text(
              "Reddet",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(c);
              await http.post(
                Uri.parse('$apiServerUrl/forward_room'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'source_room': _activeRoomName,
                  'target_room': hostRoom,
                  'action': 'merge',
                }),
              );
              final mergePayload = jsonEncode({
                'type': 'room_merging',
                'target_room': hostRoom,
              });
              await _room?.localParticipant?.publishData(
                utf8.encode(mergePayload),
                reliable: true,
              );

              await _room?.disconnect();
              await [Permission.camera, Permission.microphone].request();
              await _connectToLiveKit(hostRoom);

              await _room?.localParticipant?.setCameraEnabled(true);
              await _room?.localParticipant?.setMicrophoneEnabled(true);
              final pubs = _room?.localParticipant?.videoTrackPublications;
              if (pubs != null && pubs.isNotEmpty) {
                setState(
                  () => _localVideoTrack = pubs.first.track as VideoTrack?,
                );
              }

              final acceptPayload = jsonEncode({
                'type': 'pk_accept',
                'sender': widget.username,
                'target': host,
              });
              _room?.localParticipant?.publishData(
                utf8.encode(acceptPayload),
                reliable: true,
              );
            },
            child: const Text(
              "Kabul Et",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CHAT VE HEDİYE SİSTEMİ (COIN KONTROLLÜ)
  // ==========================================
  void _addChatMessage(String sender, String text, {bool isSystem = false}) {
    if (mounted)
      setState(
        () => _chatMessages.insert(
          0,
          ChatMessage(sender: sender, text: text, isSystem: isSystem),
        ),
      );
  }

  void _sendMessage() async {
    if (_chatController.text.isNotEmpty && _room?.localParticipant != null) {
      final text = _chatController.text;
      final payload = jsonEncode({
        'type': 'chat',
        'text': text,
        'sender': widget.username,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addChatMessage(widget.username, text);
      _chatController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _handleSendGift(String emoji, int points) async {
    // BAKİYE KONTROLÜ
    if (_coinBalance < points) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Yetersiz Bakiye!"),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // 🔥 Bakiyeden anında düş ve SQL'i arka planda güncelle
    setState(() => _coinBalance -= points);
    _updateCoinBalance(_coinBalance);

    // Hediyeyi Gönder
    if (_room?.localParticipant != null) {
      final payload = jsonEncode({
        'type': 'gift',
        'sender': widget.username,
        'receiver': _selectedGiftTarget,
        'icon': emoji,
        'points': points,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _triggerFloatingAnimation(emoji);
      _addChatMessage(
        "Sistem",
        "Sen $_selectedGiftTarget'a $emoji attın!",
        isSystem: true,
      );
    }
  }

  void _triggerFloatingAnimation(String emoji) {
    if (!mounted) return;
    final giftId = _giftIdCounter++;
    final double screenWidth = MediaQuery.of(context).size.width;
    final randomLeft =
        (screenWidth * 0.2) + _random.nextDouble() * (screenWidth * 0.6);
    setState(
      () => _floatingGifts.add(
        FloatingGift(id: giftId, left: randomLeft, emoji: emoji),
      ),
    );
  }

  void _removeGift(int id) {
    if (!mounted) return;
    setState(() => _floatingGifts.removeWhere((g) => g.id == id));
  }

  // ==========================================
  // EKRAN TASARIMI VE KAYDIRMA (SWIPE)
  // ==========================================
  Widget _buildVideoLayout() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );

    List<Map<String, dynamic>> allTracks = [];
    if (_localVideoTrack != null)
      allTracks.add({'name': widget.username, 'track': _localVideoTrack!});
    _remoteVideoTracks.forEach(
      (id, track) => allTracks.add({'name': id, 'track': track}),
    );

    Widget buildTrack(Map<String, dynamic> data) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: VideoTrackRenderer(
              data['track'] as VideoTrack,
              fit: VideoViewFit.cover,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: AnimatedOpacity(
              opacity: _isUiVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    color: Colors.black.withOpacity(0.4),
                    child: Text(
                      data['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (allTracks.length == 1) return buildTrack(allTracks[0]);
    if (allTracks.length == 2)
      return Column(
        children: [
          Expanded(child: buildTrack(allTracks[0])),
          Container(height: 2, color: AppTheme.accent),
          Expanded(child: buildTrack(allTracks[1])),
        ],
      );
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: allTracks.length,
      itemBuilder: (context, index) => buildTrack(allTracks[index]),
    );
  }

  @override
  void dispose() {
    _roomCheckTimer?.cancel(); // 🔥 BEKÇİYİ DURDUR!
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double pkPercentage = (_hostScore + _opponentScore) == 0
        ? 0.5
        : (_hostScore / (_hostScore + _opponentScore));

    // DİKKAT: _fetchCoinBalance(); BURADAN SİLİNDİ!

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // EKRANI SAĞA/SOLA KAYDIRINCA ARAYÜZÜ GİZLE/GÖSTER
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Sağa kaydırma (Gizle)
            setState(() {
              _isUiVisible = false;
              _showGiftPanel = false;
              FocusScope.of(context).unfocus();
            });
          } else if (details.primaryVelocity! < 0) {
            // Sola kaydırma (Göster)
            setState(() => _isUiVisible = true);
          }
        },
        // Ekranda boş bir yere tıklanırsa paneli kapat
        onTap: () {
          if (_showGiftPanel) setState(() => _showGiftPanel = false);
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arka Plan Videoları
            _buildVideoLayout(),

            // ─── UÇUŞAN HEDİYELER (Her zaman görünür) ───
            ..._floatingGifts
                .map(
                  (gift) => AnimatedFloatingGift(
                    key: ValueKey(gift.id),
                    gift: gift,
                    onComplete: () => _removeGift(gift.id),
                  ),
                )
                .toList(),

            // ==========================================
            // GİZLENEBİLEN ARAYÜZ ELEMANLARI (SOHBET, BARLAR)
            // ==========================================
            AnimatedOpacity(
              opacity: _isUiVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isUiVisible,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ─── ÜST BAR ───
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                color: Colors.black.withOpacity(0.3),
                                child: Row(
                                  children: [
                                    const GlowAvatar(initial: "H", radius: 14),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _activeHostName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          "Yayıncı",
                                          style: TextStyle(
                                            color: AppTheme.accentGold,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    color: Colors.black.withOpacity(0.3),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.eye,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "$_viewerCount",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GlassIconButton(
                                icon: LucideIcons.x,
                                color: Colors.white,
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ─── PK BARI ───
                    if (_isPkActive)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 70,
                        left: 16,
                        right: 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$_activeHostName\n$_hostScore",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppTheme.accentLight,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            "🔥 BATTLE 🔥",
                                            style: TextStyle(
                                              color: AppTheme.accentGold,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "0${_pkTimeLeft ~/ 60}:${(_pkTimeLeft % 60).toString().padLeft(2, '0')}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "$_pkOpponentName\n$_opponentScore",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppTheme.danger,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: pkPercentage,
                                      minHeight: 12,
                                      backgroundColor: AppTheme.danger
                                          .withOpacity(0.8),
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ─── ŞIK CHAT LİSTESİ ───
                    Positioned(
                      bottom: 80,
                      left: 16,
                      width: 260,
                      height: 250,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                          ],
                          stops: [0.0, 0.15, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.dstIn,
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.zero,
                          itemCount: _chatMessages.length,
                          itemBuilder: (ctx, i) {
                            final msg = _chatMessages[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      color: msg.isSystem
                                          ? AppTheme.accent.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.3),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            if (!msg.isSystem)
                                              TextSpan(
                                                text: "${msg.sender}: ",
                                                style: const TextStyle(
                                                  color: AppTheme.accentLight,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            TextSpan(
                                              text: msg.text,
                                              style: TextStyle(
                                                color: msg.isSystem
                                                    ? AppTheme.accent
                                                    : Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ─── ALT BAR (CHAT INPUT + HEDİYE BUTONU) ───
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 12,
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: TextField(
                                    controller: _chatController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    onSubmitted: (_) => _sendMessage(),
                                    decoration: InputDecoration(
                                      hintText: "Sohbete Katılın...",
                                      hintStyle: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white54,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withOpacity(0.4),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 0,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.send,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 🔥 YENİ: HEDİYE PANELİNİ AÇMA BUTONU
                            GestureDetector(
                              onTap: () {
                                setState(
                                  () => _showGiftPanel = !_showGiftPanel,
                                );
                                // Panel açıldığında güncel bakiyeyi tekrar kontrol et
                                if (_showGiftPanel) {
                                  _fetchCoinBalance();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pinkAccent,
                                      Colors.orangeAccent,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  "🎁",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // YENİ NESİL ŞIK HEDİYE PANELİ (Aşağıdan Çıkar)
            // ==========================================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              bottom: _showGiftPanel ? 0 : -400,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 320,
                    padding: EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Başlık ve Bakiye
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Hediyeler",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.coins,
                                    color: AppTheme.accentGold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$_coinBalance",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // PK Varsa Hedef Seçici
                        if (_isPkActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              children: [
                                const Text(
                                  "Hedef: ",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(
                                    _activeHostName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected:
                                      _selectedGiftTarget == _activeHostName,
                                  onSelected: (v) => setState(
                                    () => _selectedGiftTarget = _activeHostName,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(
                                    _pkOpponentName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected:
                                      _selectedGiftTarget == _pkOpponentName,
                                  onSelected: (v) => setState(
                                    () => _selectedGiftTarget = _pkOpponentName,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Hediye Izgarası
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: _giftCatalog.length,
                            itemBuilder: (context, index) {
                              final gift = _giftCatalog[index];
                              final bool canAfford =
                                  _coinBalance >= gift['price'];
                              return GestureDetector(
                                onTap: () {
                                  if (canAfford)
                                    _handleSendGift(
                                      gift['emoji'],
                                      gift['price'],
                                    );
                                  else
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Yetersiz Bakiye!"),
                                        backgroundColor: AppTheme.danger,
                                      ),
                                    );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: canAfford
                                          ? Colors.white24
                                          : Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        gift['emoji'],
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        gift['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.coins,
                                            color: AppTheme.accentGold,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            "${gift['price']}",
                                            style: TextStyle(
                                              color: canAfford
                                                  ? AppTheme.accentGold
                                                  : Colors.redAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// KENDİ KENDİNİ YÖNETEN BAĞIMSIZ HEDİYE MOTORU
// ==========================================
class AnimatedFloatingGift extends StatefulWidget {
  final FloatingGift gift;
  final VoidCallback onComplete;

  const AnimatedFloatingGift({
    super.key,
    required this.gift,
    required this.onComplete,
  });

  @override
  State<AnimatedFloatingGift> createState() => _AnimatedFloatingGiftState();
}

class _AnimatedFloatingGiftState extends State<AnimatedFloatingGift>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        final bottomPos = 250.0 + (value * 300);
        final leftPos = widget.gift.left + (sin(value * pi * 4) * 30);
        final opacity = 1.0 - (value * value);

        return Positioned(
          bottom: bottomPos,
          left: leftPos,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(
              widget.gift.emoji,
              style: const TextStyle(fontSize: 40),
            ),
          ),
        );
      },
    );
  }
}
