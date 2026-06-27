import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:http/http.dart' as http;
import 'package:nivi/screens/accountScreen/profilGoster/user_profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../widgets/custom_widgets.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../services/katalog_servis.dart';

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

class PremiumLiveStreamPage extends StatefulWidget {
  final String username; // O anki kullanıcının adı (İzleyici veya Host)
  final String hostName; // Yayının gerçek sahibinin adı
  final String roomName;
  final bool isHost;

  const PremiumLiveStreamPage({
    super.key,
    required this.username,
    required this.hostName,
    required this.roomName,
    this.isHost = true,
  });

  @override
  State<PremiumLiveStreamPage> createState() => _PremiumLiveStreamPageState();
}

class _PremiumLiveStreamPageState extends State<PremiumLiveStreamPage>
    with TickerProviderStateMixin {
  // --- LİVEKİT & VİDEO DEĞİŞKENLERİ ---
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack> _remoteVideoTracks = {};
  bool _isLoading = true;
  int _viewerCount = 0;

  // --- CHAT & HEDİYE DEĞİŞKENLERİ ---
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  String? _giftEffect;
  final Random _random = Random();

  // --- PK (BATTLE) DEĞİŞKENLERİ ---
  bool _isPkActive = false;
  String _pkOpponentName = "";
  int _pkTimeLeft = 120; // 2 Dakika
  int _hostScore = 0;
  int _opponentScore = 0;
  Timer? _pkTimer;

  // Hediye kime gidecek? (Varsayılan olarak yayının sahibine)
  String _selectedGiftTarget = "";

  final String apiServerUrl = 'https://yayin.sunucucodefellas.shop/get_token';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';

  @override
  void initState() {
    super.initState();
    _selectedGiftTarget = widget.hostName;
    _connectToLiveKit();
    _chatMessages.add(
      ChatMessage(
        sender: "Sistem",
        text: "${widget.roomName} yayınına bağlanılıyor...",
        isSystem: true,
      ),
    );
  }

  // ==========================================
  // 1. LIVEKIT BAĞLANTISI VE DİNLEYİCİLER
  // ==========================================
  Future<void> _connectToLiveKit() async {
    try {
      await [Permission.camera, Permission.microphone].request();

      final response = await http.post(
        Uri.parse(apiServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room': widget.roomName,
          'username': widget.username,
        }),
      );

      if (response.statusCode != 200) throw Exception('Token alınamadı');
      final token = jsonDecode(response.body)['token'];

      _room = Room();
      _listener = _room?.createListener();

      // Odadaki kişi sayısı değiştiğinde izleyici sayısını güncelle
      _listener?.on<ParticipantConnectedEvent>((e) => _updateViewerCount());

      _listener?.on<ParticipantDisconnectedEvent>((e) {
        _updateViewerCount();
        // Null kontrolü eklendi (e.participant boş değilse sil)
        if (e.participant != null) {
          setState(() => _remoteVideoTracks.remove(e.participant.identity));
        }
      });

      // Biri kamerasını açtığında (PK veya Co-Host)
      _listener?.on<TrackSubscribedEvent>((event) {
        if (!mounted) return;
        // Null kontrolü eklendi
        if (event.track is VideoTrack && event.participant != null) {
          setState(
            () => _remoteVideoTracks[event.participant.identity] =
                event.track as VideoTrack,
          );
        }
      });

      _listener?.on<TrackUnsubscribedEvent>((event) {
        if (!mounted) return;
        // Null kontrolü eklendi
        if (event.track is VideoTrack && event.participant != null) {
          setState(() => _remoteVideoTracks.remove(event.participant.identity));
        }
      });

      // --- GERÇEK ZAMANLI VERİ DİNLEME (CHAT, HEDİYE, PK VE YAYIN KAPANMA) ---
      _listener?.on<DataReceivedEvent>((event) {
        if (!mounted) return;
        final decoded = utf8.decode(event.data);
        final msgData = jsonDecode(decoded);
        final type = msgData['type'];

        if (type == 'chat') {
          _addChatMessage(msgData['sender'] ?? "Anonim", msgData['text']);
        } else if (type == 'gift') {
          final icon = msgData['icon'];
          final receiver = msgData['receiver'];
          final points = msgData['points'] ?? 10;

          _triggerFloatingAnimation(icon);
          _addChatMessage(
            "Sistem",
            "${msgData['sender']}, $receiver'a $icon gönderdi!",
            isSystem: true,
          );

          // PK Puanlarını Güncelle
          if (_isPkActive) {
            setState(() {
              if (receiver == widget.hostName)
                _hostScore += (points as int);
              else if (receiver == _pkOpponentName)
                _opponentScore += (points as int);
            });
          }
        } else if (type == 'pk_start') {
          // Yayıncı PK başlattı, herkeste anında bar açılsın!
          setState(() {
            _isPkActive = true;
            _pkOpponentName = msgData['opponent'];
            _hostScore = 0;
            _opponentScore = 0;
            _pkTimeLeft = 120;
          });
        } else if (type == 'pk_tick') {
          // Yayıncının telefonu saniye saniye zamanı herkese eşitliyor
          setState(() => _pkTimeLeft = msgData['time']);
        } else if (type == 'pk_end') {
          // PK Bitti
          setState(() => _isPkActive = false);
          _addChatMessage("Sistem", "PK Savaşı Sona Erdi!", isSystem: true);
        } else if (type == 'room_closed') {
          // YAYINCI ÇIKTI! İzleyicileri anında sayfadan atıyoruz.
          if (!widget.isHost) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Yayıncı yayını bitirdi.")),
            );
          }
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );

      // Sadece host kamerasını direkt açar
      if (widget.isHost) {
        await _room?.localParticipant?.setCameraEnabled(true);
        await _room?.localParticipant?.setMicrophoneEnabled(true);
        final publications = _room?.localParticipant?.videoTrackPublications;
        if (publications != null && publications.isNotEmpty) {
          if (mounted)
            setState(
              () => _localVideoTrack = publications.first.track as VideoTrack?,
            );
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _updateViewerCount();
        _addChatMessage("Sistem", "Bağlantı başarılı!", isSystem: true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _addChatMessage("Sistem", "Bağlantı Hatası!", isSystem: true);
      });
    }
  }

  void _updateViewerCount() {
    // LiveKit'te participants listesi host hariç diğerlerini verir
    setState(() => _viewerCount = _room?.remoteParticipants.length ?? 0);
  }

  // ==========================================
  // 2. PK (BATTLE) SİSTEMİ MANTIKLARI
  // ==========================================

  // Sadece host çağırabilir
  void _startPk(String opponentName) async {
    if (!widget.isHost) return;

    // SQL'e kaydet
    await SqlServis.ekle(
      tablo: 'aktif_pk',
      veriler: {
        'oda_adi': widget.roomName,
        'host_ismi': widget.hostName,
        'rakip_ismi': opponentName,
      },
    );

    // Herkese PK'nın başladığını bildir
    final payload = jsonEncode({'type': 'pk_start', 'opponent': opponentName});
    await _room?.localParticipant?.publishData(
      utf8.encode(payload),
      reliable: true,
    );

    setState(() {
      _isPkActive = true;
      _pkOpponentName = opponentName;
      _pkTimeLeft = 120;
      _hostScore = 0;
      _opponentScore = 0;
    });

    // Sunucu (Host) sayacı başlatır ve herkese senkronize eder
    _pkTimer?.cancel();
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pkTimeLeft > 0) {
        setState(() => _pkTimeLeft--);
        // Zamanı odadaki herkese gönder (tam senkron)
        _room?.localParticipant?.publishData(
          utf8.encode(jsonEncode({'type': 'pk_tick', 'time': _pkTimeLeft})),
        );
      } else {
        _endPk();
      }
    });
  }

  void _endPk() async {
    _pkTimer?.cancel();
    setState(() => _isPkActive = false);

    // Herkese PK bitti sinyali gönder
    _room?.localParticipant?.publishData(
      utf8.encode(jsonEncode({'type': 'pk_end'})),
    );

    // SQL'den sil
    if (widget.isHost) {
      await SqlServis.sil(
        tablo: 'aktif_pk',
        sartlar: {'oda_adi': widget.roomName},
      );
    }
  }

  // ==========================================
  // 3. ÇIKIŞ VE SİLME İŞLEMLERİ (ÖLÜMCÜL DETAY)
  // ==========================================
  Future<bool> _onWillPop() async {
    if (widget.isHost) {
      // Host çıkıyorsa herkese yayının bittiğini haber ver
      final payload = jsonEncode({'type': 'room_closed'});
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );

      // Python API'sine gidip veritabanından siliyoruz
      await http.post(
        Uri.parse('https://yayin.sunucucodefellas.shop/end_stream'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'room': widget.roomName}),
      );

      // Eğer aktif PK varsa onu da temizle
      if (_isPkActive)
        await SqlServis.sil(
          tablo: 'aktif_pk',
          sartlar: {'oda_adi': widget.roomName},
        );
    }
    return true; // Sayfadan çıkışa izin ver
  }

  // ==========================================
  // 4. MESAJ VE HEDİYE FONKSİYONLARI
  // ==========================================
  void _addChatMessage(String sender, String text, {bool isSystem = false}) {
    if (!mounted) return;
    setState(() {
      _chatMessages.insert(
        0,
        ChatMessage(sender: sender, text: text, isSystem: isSystem),
      );
      if (_chatMessages.length > 50) _chatMessages.removeLast();
    });
  }

  void _sendMessage() async {
    if (_chatController.text.isNotEmpty && _room?.localParticipant != null) {
      final text = _chatController.text;
      final payload = jsonEncode({
        'type': 'chat',
        'text': text,
        'sender': widget.username,
      });

      try {
        await _room?.localParticipant?.publishData(
          utf8.encode(payload),
          reliable: true,
        );
        _addChatMessage(widget.username, text);
      } catch (e) {
        _addChatMessage("Sistem", "Mesaj gönderilemedi!", isSystem: true);
      }
      _chatController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _handleSendGift(String giftType, String emoji, int points) async {
    _triggerFloatingAnimation(emoji);

    if (_room?.localParticipant != null) {
      final payload = jsonEncode({
        'type': 'gift',
        'sender': widget.username,
        'receiver': _selectedGiftTarget, // Hediye seçili kişiye gider
        'icon': emoji,
        'points': points,
        'kaynak': 'live'
      });

      try {
        await _room?.localParticipant?.publishData(
          utf8.encode(payload),
          reliable: true,
        );
        _addChatMessage(
          "Sistem",
          "Sen $_selectedGiftTarget'a $emoji gönderdin!",
          isSystem: true,
        );

        if (_isPkActive) {
          setState(() {
            if (_selectedGiftTarget == widget.hostName)
              _hostScore += points;
            else if (_selectedGiftTarget == _pkOpponentName)
              _opponentScore += points;
          });
        }
      } catch (e) {
        debugPrint("Hediye hatası: $e");
      }
    }
  }

  void _triggerFloatingAnimation(String emoji) {
    if (!mounted) return;
    final giftId = _giftIdCounter++;
    setState(
      () => _floatingGifts.add(
        FloatingGift(
          id: giftId,
          left: 30 + _random.nextDouble() * 100,
          emoji: emoji,
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        setState(() => _floatingGifts.removeWhere((g) => g.id == giftId));
    });
  }

  // ==========================================
  // 5. EKRAN ÇİZİMLERİ VE VİDEO YERLEŞİMİ
  // ==========================================
  Widget _buildDynamicVideoLayout() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );

    // Ekrandaki tüm kameraları ve kime ait olduklarını eşleştiriyoruz
    List<Map<String, dynamic>> allTracks = [];

    if (widget.isHost && _localVideoTrack != null) {
      allTracks.add({'name': widget.hostName, 'track': _localVideoTrack!});
    } else if (!widget.isHost && _localVideoTrack != null) {
      // Eğer izleyici PK'ya katılmışsa kendi kamerasını da görür
      allTracks.add({'name': widget.username, 'track': _localVideoTrack!});
    }

    _remoteVideoTracks.forEach((identity, track) {
      allTracks.add({'name': identity, 'track': track});
    });

    if (allTracks.isEmpty)
      return const Center(
        child: Text(
          "Yayıncı bekleniyor...",
          style: TextStyle(color: Colors.white),
        ),
      );

    // Kameranın üzerine köşeye isim yazan widget
    Widget buildTrackWithName(Map<String, dynamic> data) {
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
          // Sol alt köşeye kullanıcı adını yaz
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                data['name'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (allTracks.length == 1) return buildTrackWithName(allTracks[0]);
    if (allTracks.length == 2) {
      return Column(
        children: [
          Expanded(child: buildTrackWithName(allTracks[0])),
          Container(height: 2, color: Colors.black),
          Expanded(child: buildTrackWithName(allTracks[1])),
        ],
      );
    }
    // Çoklu grid
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: allTracks.length,
      itemBuilder: (context, index) => buildTrackWithName(allTracks[index]),
    );
  }

  @override
  void dispose() {
    _pkTimer?.cancel();
    _listener?.dispose();
    _room?.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // PK Yüzdesi Hesaplama
    int totalScore = _hostScore + _opponentScore;
    double pkPercentage = totalScore == 0 ? 0.5 : (_hostScore / totalScore);

    return WillPopScope(
      onWillPop: _onWillPop, // Çıkarken yayını kökten kapatır
      child: Scaffold(
        backgroundColor: Colors.black,
        body: MainBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              IgnorePointer(child: _buildDynamicVideoLayout()),

              // --- ÜST BAR (Yayıncı Adı ve İzleyici Sayısı) ---
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.accent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.hostName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        // İzleyici Sayısı
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.eye,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_viewerCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            bool canPop = await _onWillPop();
                            if (canPop && mounted) Navigator.pop(context);
                          },
                          icon: const Icon(LucideIcons.x, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- PK BATTLE BARI (Sadece _isPkActive true ise görünür) ---
              if (_isPkActive)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${widget.hostName}: $_hostScore",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.accentLight,
                              ),
                            ),
                            Text(
                              "PK BATTLE (0${_pkTimeLeft ~/ 60}:${(_pkTimeLeft % 60).toString().padLeft(2, '0')})",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "$_pkOpponentName: $_opponentScore",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: pkPercentage,
                          backgroundColor: AppTheme.danger,
                          color: AppTheme.accent,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- HEDİYE SEÇİCİ (PK Varsa Kime Gidecek?) ---
              if (_isPkActive)
                Positioned(
                  bottom: 220,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Hedef",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        ChoiceChip(
                          label: Text(
                            widget.hostName,
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: _selectedGiftTarget == widget.hostName,
                          onSelected: (val) => setState(
                            () => _selectedGiftTarget = widget.hostName,
                          ),
                        ),
                        ChoiceChip(
                          label: Text(
                            _pkOpponentName,
                            style: const TextStyle(fontSize: 10),
                          ),
                          selected: _selectedGiftTarget == _pkOpponentName,
                          onSelected: (val) => setState(
                            () => _selectedGiftTarget = _pkOpponentName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Uçuşan Hediyeler
              ..._floatingGifts
                  .map(
                    (gift) => Positioned(
                      bottom: 150,
                      left: gift.left,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(gift.id),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(
                              sin(value * pi * 4) * 20,
                              -value * 200,
                            ),
                            child: Opacity(
                              opacity: 1.0 - (value * value),
                              child: Text(
                                gift.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),

              // Chat Alanı
              Positioned(
                bottom: 120,
                left: 16,
                width: 250,
                height: 200,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black],
                    stops: [0.0, 0.2, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _chatMessages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _chatMessages[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              // Host, sohbetteki birine tıklayarak PK başlatabilir
                              if (widget.isHost &&
                                  !msg.isSystem &&
                                  msg.sender != widget.hostName &&
                                  !_isPkActive) {
                                showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text("PK Başlat"),
                                    content: Text(
                                      "${msg.sender} ile PK Battle başlatılsın mı?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c),
                                        child: const Text("İptal"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(c);
                                          _startPk(msg.sender); // PK Başlat!
                                        },
                                        child: const Text("Başlat"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: msg.isSystem
                                    ? AppTheme.accent.withOpacity(0.2)
                                    : Colors.black45,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    if (!msg.isSystem)
                                      TextSpan(
                                        text: "${msg.sender}: ",
                                        style: const TextStyle(
                                          color: AppTheme.accentLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    TextSpan(
                                      text: msg.text,
                                      style: TextStyle(
                                        color: msg.isSystem
                                            ? AppTheme.accent
                                            : Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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

              // --- ALT BAR ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                    left: 16,
                    right: 16,
                    top: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: KatalogServis.yayinHediyeleri.value
                                .take(3)
                                .map(
                                  (g) => _buildGiftBtn(
                                    g['emoji'],
                                    g['name'],
                                    "${g['price']}",
                                    AppTheme.danger,
                                    () => _handleSendGift(
                                      g['name'],
                                      g['emoji'],
                                      g['price'],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: widget.isHost
                                    ? "İzleyicilerine yaz..."
                                    : "Sohbete Katılın...",
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.black45,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.send,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGiftBtn(
    String emoji,
    String title,
    String cost,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              cost,
              style: const TextStyle(fontSize: 9, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}
