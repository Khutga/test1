import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Kendi projenin import yollarına göre buraları düzenleyebilirsin
import '../widgets/custom_widgets.dart';
import '../core/app_colors.dart';

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
  final String username;
  final String roomName;
  final bool isHost;

  const PremiumLiveStreamPage({
    super.key,
    required this.username,
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

  // --- CHAT & HEDİYE DEĞİŞKENLERİ ---
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  int _currentEffectId = 0;
  final Random _random = Random();

  // --- YENİ TASARIM DEĞİŞKENLERİ (PK & EFEKTLER) ---
  String? _giftEffect;
  double _pkPercentage = 0.5;

  Timer? _streamTimer;
  int _streamDurationInSeconds = 0;

  // Kendi API ve LiveKit sunucu bilgilerin
  final String apiServerUrl = 'https://yayin.sunucucodefellas.shop/get_token';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';

  @override
  void initState() {
    super.initState();
    _connectToLiveKit();
    _startTimer();
    _chatMessages.add(
      ChatMessage(
        sender: "Sistem",
        text: "${widget.roomName} yayına bağlanılıyor...",
        isSystem: true,
      ),
    );
  }

  void _startTimer() {
    _streamTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _streamDurationInSeconds++);
      }
    });
  }

  // LiveKit Bağlantısı
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

      _listener?.on<TrackSubscribedEvent>((event) {
        if (!mounted) return;
        if (event.track is VideoTrack) {
          setState(
            () => _remoteVideoTracks[event.participant.identity] =
                event.track as VideoTrack,
          );
        }
      });

      _listener?.on<TrackUnsubscribedEvent>((event) {
        if (!mounted) return;
        if (event.track is VideoTrack) {
          setState(() => _remoteVideoTracks.remove(event.participant.identity));
        }
      });

      _listener?.on<ParticipantDisconnectedEvent>((event) {
        if (!mounted) return;
        setState(() => _remoteVideoTracks.remove(event.participant.identity));
      });

      // GERÇEK ZAMANLI VERİ DİNLEME (Chat ve Hediyeler)
      _listener?.on<DataReceivedEvent>((event) {
        if (!mounted) return;
        final decoded = utf8.decode(event.data);
        final msgData = jsonDecode(decoded);

        if (msgData['type'] == 'chat') {
          _addChatMessage(msgData['sender'] ?? "Anonim", msgData['text']);
        } else if (msgData['type'] == 'gift') {
          final icon = msgData['icon'] ?? '❤️';
          final giftType = msgData['giftType'] ?? 'Heart';

          _triggerFloatingAnimation(icon);
          _applyGiftEffect(giftType);

          _addChatMessage(
            "Sistem",
            "${msgData['sender']} $icon gönderdi!",
            isSystem: true,
          );
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );

      if (widget.isHost) {
        await _room?.localParticipant?.setCameraEnabled(true);
        await _room?.localParticipant?.setMicrophoneEnabled(true);
        final publications = _room?.localParticipant?.videoTrackPublications;
        if (publications != null && publications.isNotEmpty) {
          if (mounted) {
            setState(
              () => _localVideoTrack = publications.first.track as VideoTrack?,
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
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

  void _handleSendGift(String giftType, String emoji) async {
    _triggerFloatingAnimation(emoji);
    _applyGiftEffect(giftType);

    if (_room?.localParticipant != null) {
      final payload = jsonEncode({
        'type': 'gift',
        'sender': widget.username,
        'icon': emoji,
        'giftType': giftType,
      });

      try {
        await _room?.localParticipant?.publishData(
          utf8.encode(payload),
          reliable: true,
        );
        _addChatMessage("Sistem", "Bir $emoji gönderdin!", isSystem: true);
      } catch (e) {
        debugPrint("Hediye gönderim hatası: $e");
      }
    }
  }

  void _applyGiftEffect(String giftType) {
    if (!mounted) return;

    _currentEffectId++; 
    final int thisEffectId = _currentEffectId; 

    setState(() => _giftEffect = giftType);
    
    if (giftType == 'Dragon') {
      setState(() => _pkPercentage = (_pkPercentage + 0.15).clamp(0.0, 1.0));
    } else if (giftType == 'Yacht') {
      setState(() => _pkPercentage = (_pkPercentage + 0.08).clamp(0.0, 1.0));
    } else {
      setState(() => _pkPercentage = (_pkPercentage + 0.02).clamp(0.0, 1.0));
    }

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && _currentEffectId == thisEffectId) {
        setState(() => _giftEffect = null);
      }
    });
  }

  void _triggerFloatingAnimation(String emoji) {
    if (!mounted) return;
    final giftId = _giftIdCounter++;
    setState(() {
      _floatingGifts.add(
        FloatingGift(
          id: giftId,
          left: 30 + _random.nextDouble() * 100,
          emoji: emoji,
        ),
      );
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _floatingGifts.removeWhere((g) => g.id == giftId));
      }
    });
  }

  Widget _buildDynamicVideoLayout() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent), // Güncellendi
      );
    }

    List<VideoTrack> allTracks = [];
    if (widget.isHost && _localVideoTrack != null)
      allTracks.add(_localVideoTrack!);
    allTracks.addAll(_remoteVideoTracks.values);

    if (allTracks.isEmpty) {
      return const Center(
        child: Text(
          "Yayıncı bekleniyor...",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Widget buildTrack(VideoTrack track) {
      return Container(
        key: ValueKey(track.sid),
        color: Colors.black,
        child: VideoTrackRenderer(track, fit: VideoViewFit.cover),
      );
    }

    if (allTracks.length == 1)
      return buildTrack(allTracks[0]);
    else if (allTracks.length == 2) {
      return Column(
        children: [
          Expanded(child: buildTrack(allTracks[0])),
          Container(height: 2, color: Colors.black),
          Expanded(child: buildTrack(allTracks[1])),
        ],
      );
    } else if (allTracks.length == 3) {
      return Column(
        children: [
          Expanded(flex: 2, child: buildTrack(allTracks[0])),
          Container(height: 2, color: Colors.black),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildTrack(allTracks[1])),
                Container(width: 2, color: Colors.black),
                Expanded(child: buildTrack(allTracks[2])),
              ],
            ),
          ),
        ],
      );
    } else {
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
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _listener?.dispose();
    _room?.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MainBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. DİNAMİK VİDEO YERLEŞİMİ (Arka Plan)
            IgnorePointer(child: _buildDynamicVideoLayout()),

            // 2. EĞER TAM EKRAN HEDİYE EFEKTİ VARSA
            if (_giftEffect != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: _giftEffect == 'Dragon'
                        ? AppTheme.danger.withOpacity(0.3) // Güncellendi
                        : AppTheme.accent.withOpacity(0.2), // Güncellendi
                    child: Center(
                      child: Text(
                        _giftEffect == 'Dragon'
                            ? "🐲"
                            : _giftEffect == 'Yacht'
                            ? "🛳️"
                            : "❤️",
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                  ),
                ),
              ),

            // 3. ÜST BAR
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.accent, // Güncellendi
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.username,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "Lv.42 Yıldız",
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.accentGold, // Güncellendi
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            // 4. PK İLERLEME ÇUBUĞU
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Bizim: ${(_pkPercentage * 120).toInt()} XP",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentLight, // Güncellendi
                          ),
                        ),
                        const Text(
                          "PK BATTLE",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.danger, // Güncellendi
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Rakip: ${((1 - _pkPercentage) * 120).toInt()} XP",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accent, // Güncellendi
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: _pkPercentage,
                      backgroundColor: AppTheme.danger, // Güncellendi
                      color: AppTheme.accent, // Güncellendi
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),

            // 5. UÇUŞAN HEDİYELER (LiveKit Altyapısı)
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

            // 6. CHAT ALANI
            Positioned(
              bottom: 140,
              left: 16,
              width: 250,
              height: 200,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black],
                    stops: [0.0, 0.2, 1.0],
                  ).createShader(bounds);
                },
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isSystem
                                ? AppTheme.accent.withOpacity(0.2) // Güncellendi
                                : Colors.black45,
                            borderRadius: BorderRadius.circular(16),
                            border: msg.isSystem
                                ? Border.all(
                                    color: AppTheme.accent.withOpacity(0.5), // Güncellendi
                                  )
                                : null,
                          ),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                if (!msg.isSystem)
                                  const TextSpan(
                                    text: "Sen: ",
                                    style: TextStyle(
                                      color: AppTheme.accentLight, // Güncellendi
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                TextSpan(
                                  text: msg.text,
                                  style: TextStyle(
                                    color: msg.isSystem
                                        ? AppTheme.accent // Güncellendi
                                        : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 7. ALT BAR (Hediyeler + Mesaj Kutusu)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
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
                    // Hediye Butonları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildGiftBtn(
                          "🐲",
                          "Dragon",
                          "25K Coin",
                          AppTheme.danger, // Güncellendi
                          () => _handleSendGift('Dragon', '🐲'),
                        ),
                        _buildGiftBtn(
                          "🛳️",
                          "Yacht",
                          "8.5K Coin",
                          AppTheme.accentLight, // Güncellendi
                          () => _handleSendGift('Yacht', '🛳️'),
                        ),
                        _buildGiftBtn(
                          "❤️",
                          "Kalp",
                          "10 Coin",
                          AppTheme.danger, // Güncellendi
                          () => _handleSendGift('Heart', '❤️'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mesaj Gönderme Kutusu
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
                              hintText: "Sohbete Katılın...",
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
                                borderSide: const BorderSide(
                                  color: Colors.white10,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(
                                  color: AppTheme.accent.withOpacity(0.5), // Güncellendi
                                ),
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
                              color: AppTheme.accent, // Güncellendi
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
    );
  }

  // Hediye Butonu Widget'ı
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