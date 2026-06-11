import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../widgets/custom_widgets.dart';

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

class LiveViewScreen extends StatefulWidget {
  final Map<String, dynamic> streamData;
  const LiveViewScreen({super.key, required this.streamData});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  // --- LIVEKIT DEĞİŞKENLERİ ---
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  final Map<String, VideoTrack> _remoteVideoTracks = {};
  bool _isLoading = true;
  int _viewerCount = 0;

  // --- SOHBET DEĞİŞKENLERİ ---
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- PK BATTLE DEĞİŞKENLERİ ---
  bool _isPkActive = false;
  String _pkOpponentName = "";
  int _pkTimeLeft = 0;
  int _hostScore = 0;
  int _opponentScore = 0;

  final Color _hostColor = Colors.blueAccent;
  final Color _opponentColor = AppTheme.danger;

  // --- HEDİYE DEĞİŞKENLERİ ---
  String? _giftEffect;
  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  final Random _random = Random();

  final String pyServerUrl = 'https://yayin.sunucucodefellas.shop';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';

  @override
  void initState() {
    super.initState();
    _connectToLiveKit();
  }

  // ==========================================
  // LIVEKIT BAĞLANTISI (İZLEYİCİ OLARAK)
  // ==========================================
  Future<void> _connectToLiveKit() async {
    try {
      final roomName = widget.streamData['oda_adi'] ?? '';
      final myUsername = widget.streamData['username'] ?? 'İzleyici';

      final response = await http.post(
        Uri.parse('$pyServerUrl/get_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room': roomName,
          'username': myUsername,
          'is_host': false,
        }),
      );

      final token = jsonDecode(response.body)['token'];
      _room = Room();
      _listener = _room?.createListener();

      _listener?.on<ParticipantConnectedEvent>((e) => _updateViewerCount());
      _listener?.on<ParticipantDisconnectedEvent>((e) {
        _updateViewerCount();
        if (e.participant != null) {
          setState(() => _remoteVideoTracks.remove(e.participant!.identity));
        }
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

        if (msgData['type'] == 'chat') {
          _addChatMessage(msgData['sender'], msgData['text']);
        } else if (msgData['type'] == 'gift') {
          final points = msgData['points'] ?? 10;
          final receiver = msgData['receiver'];

          if (msgData['icon'] != null) {
            _triggerFloatingAnimation(msgData['icon']);
          }

          _addSystemMessage(
            "${msgData['sender']}, $receiver'a hediye gönderdi!",
          );

          if (_isPkActive) {
            setState(() {
              if (receiver == widget.streamData['name'])
                _hostScore += (points as int);
              else if (receiver == _pkOpponentName)
                _opponentScore += (points as int);
            });
          }
        } else if (msgData['type'] == 'pk_start') {
          setState(() {
            _isPkActive = true;
            _pkOpponentName = msgData['opponent'];
            _hostScore = 0;
            _opponentScore = 0;
          });
        } else if (msgData['type'] == 'pk_tick') {
          setState(() => _pkTimeLeft = msgData['time']);
        } else if (msgData['type'] == 'pk_end') {
          setState(() {
            _isPkActive = false;
            _pkTimeLeft = 0;
          });
          _addSystemMessage("PK Sona Erdi.");
        } else if (msgData['type'] == 'room_closed') {
          _addSystemMessage("Yayıncı yayını sonlandırdı.");
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateViewerCount();
        });
        _addSystemMessage("Yayına bağlandınız.");
      }
    } catch (e) {
      _addSystemMessage("Bağlantı Hatası!");
    }
  }

  void _updateViewerCount() =>
      setState(() => _viewerCount = _room?.remoteParticipants.length ?? 0);

  // ==========================================
  // SOHBET VE SİSTEM MESAJLARI
  // ==========================================
  void _addSystemMessage(String text) {
    if (mounted) {
      setState(() {
        _chatMessages.insert(
          0,
          ChatMessage(sender: "Sistem", text: text, isSystem: true),
        );
      });
    }
  }

  void _addChatMessage(String sender, String text) {
    if (mounted) {
      setState(() {
        _chatMessages.insert(0, ChatMessage(sender: sender, text: text));
        if (_chatMessages.length > 50) _chatMessages.removeLast();
      });
    }
  }

  void _sendMessage() async {
    if (_chatController.text.isNotEmpty && _room?.localParticipant != null) {
      final text = _chatController.text;
      final myName = widget.streamData['username'] ?? 'İzleyici';

      final payload = jsonEncode({
        'type': 'chat',
        'text': text,
        'sender': myName,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addChatMessage(myName, text);
      _chatController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  // ==========================================
  // HEDİYE SİSTEMİ
  // ==========================================
  void _triggerFloatingAnimation(String emoji) {
    if (!mounted) return;
    final giftId = _giftIdCounter++;
    final double screenWidth = MediaQuery.of(context).size.width;
    final randomLeft =
        (screenWidth * 0.2) + _random.nextDouble() * (screenWidth * 0.6);

    setState(() {
      _floatingGifts.add(
        FloatingGift(id: giftId, left: randomLeft, emoji: emoji),
      );
    });
  }

  void _removeGift(int id) {
    if (!mounted) return;
    setState(() => _floatingGifts.removeWhere((g) => g.id == id));
  }

  void _handleSendGift(String giftType) async {
    setState(() => _giftEffect = giftType);
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _giftEffect = null);
    });

    int points = giftType == 'Dragon'
        ? 25000
        : giftType == 'Yacht'
        ? 8500
        : 10;
    String emoji = giftType == 'Dragon'
        ? "🐲"
        : giftType == 'Yacht'
        ? "🛳️"
        : "❤️";

    if (_isPkActive) {
      setState(() {
        _hostScore += points;
      });
    }

    _triggerFloatingAnimation(emoji);

    if (_room?.localParticipant != null) {
      final myName = widget.streamData['username'] ?? 'İzleyici';
      final payload = jsonEncode({
        'type': 'gift',
        'sender': myName,
        'receiver': widget.streamData['name'],
        'points': points,
        'icon': emoji,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addSystemMessage(
        "Sen, ${widget.streamData['name']}'a hediye gönderdin!",
      );
    }
  }

  // ==========================================
  // VİDEO EKRANI (Yan Yana & Yatay Sığdırma)
  // ==========================================
  Widget _buildVideoLayout() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_remoteVideoTracks.isEmpty) {
      return const Center(
        child: Text(
          "Yayın bekleniyor...",
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    List<Map<String, dynamic>> allTracks = [];
    _remoteVideoTracks.forEach(
      (id, track) => allTracks.add({'name': id, 'track': track}),
    );

    Widget buildTrack(Map<String, dynamic> data) {
      Color trackBorderColor = Colors.transparent;
      if (_isPkActive) {
        if (data['name'] == widget.streamData['name']) {
          trackBorderColor = _hostColor;
        } else if (data['name'] == _pkOpponentName) {
          trackBorderColor = _opponentColor;
        }
      }

      return Container(
        decoration: BoxDecoration(
          border: _isPkActive
              ? Border.all(color: trackBorderColor, width: 2)
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black,
              // 🔥 YENİ: PK aktifse yatay olarak sığdır (contain), değilse tam ekran yap (cover)
              child: VideoTrackRenderer(
                data['track'] as VideoTrack,
                fit: _isPkActive ? VideoViewFit.contain : VideoViewFit.cover,
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    color: _isPkActive
                        ? trackBorderColor.withOpacity(0.6)
                        : Colors.black.withOpacity(0.4),
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
          ],
        ),
      );
    }

    if (allTracks.length == 1) return buildTrack(allTracks[0]);

    if (allTracks.length == 2) {
      return Row(
        children: [
          Expanded(child: buildTrack(allTracks[0])),
          Container(width: 2, color: Colors.black),
          Expanded(child: buildTrack(allTracks[1])),
        ],
      );
    }

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
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double pkPercentage = (_hostScore + _opponentScore) == 0
        ? 0.5
        : (_hostScore / (_hostScore + _opponentScore));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. CANLI YAYIN VİDEO KATMANI
          Positioned.fill(child: _buildVideoLayout()),

          // 2. ÜST BAR
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          LucideIcons.user,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.streamData['name'] ?? 'Yayıncı',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "İzleyici: $_viewerCount",
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ],
            ),
          ),

          // 3. PK BARI
          if (_isPkActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${widget.streamData['name']}: $_hostScore XP",
                          style: TextStyle(
                            fontSize: 9,
                            color: _hostColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              "⚔️ PK",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              "0${_pkTimeLeft ~/ 60}:${(_pkTimeLeft % 60).toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$_pkOpponentName: $_opponentScore XP",
                          style: TextStyle(
                            fontSize: 9,
                            color: _opponentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pkPercentage,
                      backgroundColor: _opponentColor,
                      color: _hostColor,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ),

          // 4. UÇUŞAN HEDİYELER
          ..._floatingGifts
              .map(
                (gift) => AnimatedFloatingGift(
                  key: ValueKey(gift.id),
                  gift: gift,
                  onComplete: () => _removeGift(gift.id),
                ),
              )
              .toList(),

          // 5. SOHBET
          Positioned(
            bottom: 140,
            left: 12,
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
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: msg.isSystem
                                ? AppTheme.accent.withOpacity(0.2)
                                : Colors.black.withOpacity(0.4),
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
                    ),
                  );
                },
              ),
            ),
          ),

          // 6. ALT KONTROLLER
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                left: 12,
                right: 12,
                top: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGiftBtn(
                        "🐲",
                        "Dragon",
                        "25K",
                        Colors.red,
                        () => _handleSendGift('Dragon'),
                      ),
                      _buildGiftBtn(
                        "🛳️",
                        "Yacht",
                        "8.5K",
                        Colors.cyan,
                        () => _handleSendGift('Yacht'),
                      ),
                      _buildGiftBtn(
                        "❤️",
                        "Kalp",
                        "10",
                        Colors.pink,
                        () => _handleSendGift('Heart'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: "Sohbete katıl...",
                            hintStyle: const TextStyle(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                            filled: true,
                            fillColor: Colors.black45,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.send,
                            size: 14,
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

          // 7. TAM EKRAN HEDİYE EFEKTİ
          if (_giftEffect != null)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: _giftEffect == 'Dragon'
                      ? Colors.red.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.15),
                  child: Center(
                    child: Text(
                      _giftEffect == 'Dragon'
                          ? "🐲"
                          : _giftEffect == 'Yacht'
                          ? "🛳️"
                          : "❤️",
                      style: const TextStyle(fontSize: 100),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              cost,
              style: const TextStyle(fontSize: 8, color: Colors.amber),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// UÇUŞAN HEDİYE ANİMASYON MOTORU
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
        final bottomPos = 180.0 + (value * 300);
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
