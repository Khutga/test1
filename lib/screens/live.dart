import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

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
    Key? key,
    required this.username,
    required this.roomName,
    this.isHost = true,
  }) : super(key: key);

  @override
  State<PremiumLiveStreamPage> createState() => _PremiumLiveStreamPageState();
}

class _PremiumLiveStreamPageState extends State<PremiumLiveStreamPage>
    with TickerProviderStateMixin {
  late final Room _room;
  EventsListener<RoomEvent>? _listener;

  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  bool _isLoading = true;

  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  final Random _random = Random();

  Timer? _streamTimer;
  int _streamDurationInSeconds = 0;

  final String apiServerUrl = 'https://yayin.sunucucodefellas.shop/get_token';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';

  final List<String> _giftOptions = ['💖', '🚀', '🔥', '💎', '👑'];

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
      setState(() => _streamDurationInSeconds++);
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

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
      _listener = _room.createListener();

      _listener!.on<TrackSubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          setState(
            () => _remoteVideoTracks[event.participant.identity] =
                event.track as VideoTrack,
          );
        }
      });

      _listener!.on<TrackUnsubscribedEvent>((event) {
        if (event.track is VideoTrack) {
          setState(() => _remoteVideoTracks.remove(event.participant.identity));
        }
      });

      _listener!.on<ParticipantDisconnectedEvent>((event) {
        setState(() => _remoteVideoTracks.remove(event.participant.identity));
      });

      _listener!.on<DataReceivedEvent>((event) {
        final decoded = utf8.decode(event.data);
        final msgData = jsonDecode(decoded);

        if (msgData['type'] == 'chat') {
          _addChatMessage(msgData['sender'] ?? "Anonim", msgData['text']);
        } else if (msgData['type'] == 'gift') {
          final icon = msgData['icon'] ?? '💖';
          _triggerGiftAnimation(icon);
          _addChatMessage(
            "Sistem",
            "${msgData['sender']} $icon gönderdi!",
            isSystem: true,
          );
        }
      });

      await _room.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );

      if (widget.isHost) {
        await _room.localParticipant?.setCameraEnabled(true);
        await _room.localParticipant?.setMicrophoneEnabled(true);
        final publications = _room.localParticipant?.videoTrackPublications;
        if (publications != null && publications.isNotEmpty) {
          setState(
            () => _localVideoTrack = publications.first.track as VideoTrack?,
          );
        }
      }

      setState(() {
        _isLoading = false;
        _addChatMessage("Sistem", "Bağlantı başarılı!", isSystem: true);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _addChatMessage("Sistem", "Bağlantı Hatası!", isSystem: true);
      });
    }
  }

  void _addChatMessage(String sender, String text, {bool isSystem = false}) {
    setState(() {
      _chatMessages.insert(
        0,
        ChatMessage(sender: sender, text: text, isSystem: isSystem),
      );
      if (_chatMessages.length > 50) _chatMessages.removeLast();
    });
  }

  void _sendMessage() async {
    if (_chatController.text.isNotEmpty &&
        _room.connectionState == ConnectionState.active) {
      final text = _chatController.text;
      final payload = jsonEncode({
        'type': 'chat',
        'text': text,
        'sender': widget.username,
      });
      await _room.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addChatMessage(widget.username, text);
      _chatController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _sendSelectedGift(String emoji) async {
    _triggerGiftAnimation(emoji);
    if (_room.connectionState == ConnectionState.active) {
      final payload = jsonEncode({
        'type': 'gift',
        'sender': widget.username,
        'icon': emoji,
      });
      await _room.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addChatMessage("Sistem", "Bir $emoji gönderdin!", isSystem: true);
    }
  }

  void _triggerGiftAnimation(String emoji) {
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

  void _showGiftSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Hediye Gönder",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _giftOptions
                  .map(
                    (emoji) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _sendSelectedGift(emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // YENİ DİNAMİK EKRAN BÖLÜCÜ SİSTEMİ
  Widget _buildDynamicVideoLayout() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );

    List<VideoTrack> allTracks = [];
    if (widget.isHost && _localVideoTrack != null)
      allTracks.add(_localVideoTrack!);
    allTracks.addAll(_remoteVideoTracks.values);

    if (allTracks.isEmpty)
      return const Center(
        child: Text(
          "Yayıncı bekleniyor...",
          style: TextStyle(color: Colors.white),
        ),
      );

    // EMÜLATÖR ÇÖKMESİNİ ENGELLEYEN CRITICAL KOD: ValueKey(track.sid)
    Widget buildTrack(VideoTrack track) {
      return Container(
        key: ValueKey(track.sid),
        color: Colors.black,
        child: VideoTrackRenderer(track, fit: VideoViewFit.cover),
      );
    }

    // 1 KİŞİ: Tam ekran
    if (allTracks.length == 1) {
      return buildTrack(allTracks[0]);
    }
    // 2 KİŞİ: Altlı Üstlü Eşit
    else if (allTracks.length == 2) {
      return Column(
        children: [
          Expanded(child: buildTrack(allTracks[0])),
          Container(height: 2, color: Colors.black),
          Expanded(child: buildTrack(allTracks[1])),
        ],
      );
    }
    // 3 KİŞİ: 1 Büyük Üstte, 2 Küçük Altta
    else if (allTracks.length == 3) {
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
    }
    // 4 KİŞİ VE ÜZERİ: Eşit Kareler (Grid)
    else {
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
    _room.disconnect();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. DİNAMİK KAMERA YERLEŞİMİ
          IgnorePointer(child: _buildDynamicVideoLayout()),

          // 2. İZLEYİCİ İÇİN PIP (Sadece izleyici olup kendi kamerası açıksa)
          if (!_isLoading && !widget.isHost && _localVideoTrack != null)
            Positioned(
              top: 110,
              right: 16,
              width: 90,
              height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: IgnorePointer(
                    child: VideoTrackRenderer(
                      _localVideoTrack!,
                      fit: VideoViewFit.cover,
                    ),
                  ),
                ),
              ),
            ),

          // 3. ALT GÖLGE
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 400,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. ÜST BAR
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                      color: Colors.white.withOpacity(0.15),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(_streamDurationInSeconds),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // 5. UÇUŞAN SEÇİLİ HEDİYELER
          ..._floatingGifts
              .map(
                (gift) => Positioned(
                  bottom: 100,
                  left: gift.left,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(gift.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(sin(value * pi * 4) * 20, -value * 200),
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
            bottom: 80,
            left: 16,
            width: 280,
            height: 250,
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
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isSystem
                              ? Colors.pinkAccent.withOpacity(0.2)
                              : Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                          border: msg.isSystem
                              ? Border.all(
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                )
                              : null,
                        ),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              if (!msg.isSystem)
                                TextSpan(
                                  text: "${msg.sender}: ",
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              TextSpan(
                                text: msg.text,
                                style: TextStyle(
                                  color: msg.isSystem
                                      ? Colors.pinkAccent
                                      : Colors.white,
                                  fontSize: 13,
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

          // 7. ALT KONTROLLER (Hediye Seçici Butonu)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Sohbete katıl...",
                            hintStyle: const TextStyle(color: Colors.white60),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.cyanAccent,
                                size: 20,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showGiftSelector,
                  child: Container(
                    height: 45,
                    width: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
