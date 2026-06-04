import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatCallScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;
  final String username;
  final bool isVideoCall;
  final int currentRelationshipLevel;

  const ChatCallScreen({
    super.key,
    required this.chatData,
    required this.username,
    required this.isVideoCall,
    required this.currentRelationshipLevel,
  });

  @override
  State<ChatCallScreen> createState() => _ChatCallScreenState();
}

class _ChatCallScreenState extends State<ChatCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack> _remoteVideoTracks = {};
  bool _isLoading = true;
  bool _isMicMuted = false;

  final String pyServerUrl = 'https://yayin.sunucucodefellas.shop';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndConnect();
  }

  Future<void> _checkPermissionsAndConnect() async {
    // ⚠️ Seviye kontrolünü tam burada yapıyoruz
    if (widget.isVideoCall && widget.currentRelationshipLevel < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⚠️ Görüntülü aramada kamera açmak için İlişki Seviyesi en az 3 olmalıdır!",
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      });
    }
    _connectToCallRoom();
  }

  Future<void> _connectToCallRoom() async {
    try {
      await [Permission.camera, Permission.microphone].request();

      final prefs = await SharedPreferences.getInstance();
      int kendiId = prefs.getInt('kullanici_id') ?? 1;
      int karsiId = int.tryParse(widget.chatData['id'].toString()) ?? 0;

      // 🔥 ÇÖZÜM 1: Oda ismini sadece sayılardan üretiyoruz, çökmesi İMKANSIZ!
      int kucukId = kendiId < karsiId ? kendiId : karsiId;
      int buyukId = kendiId > karsiId ? kendiId : karsiId;
      final String callRoomName = "arama_room_${kucukId}_$buyukId";

      final response = await http.post(
        Uri.parse('$pyServerUrl/get_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room': callRoomName,
          'username': widget.username,
          'is_host': true,
        }),
      );

      final token = jsonDecode(response.body)['token'];
      _room = Room();
      _listener = _room?.createListener();

      _listener?.on<TrackSubscribedEvent>((event) {
        if (event.track is VideoTrack && event.participant != null) {
          setState(
            () => _remoteVideoTracks[event.participant!.identity] =
                event.track as VideoTrack,
          );
        }
      });

      _listener?.on<TrackUnsubscribedEvent>((event) {
        if (event.track is VideoTrack && event.participant != null) {
          setState(
            () => _remoteVideoTracks.remove(event.participant!.identity),
          );
        }
      });

      _listener?.on<DataReceivedEvent>((event) {
        final msg = jsonDecode(utf8.decode(event.data));
        if (msg['type'] == 'call_ended') {
          _hangUp();
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );
      await _room?.localParticipant?.setMicrophoneEnabled(true);

      // Sadece İlişki Seviyesi 3 veya daha yüksekse kamerayı açtırıyoruz!
      if (widget.isVideoCall && widget.currentRelationshipLevel >= 3) {
        await _room?.localParticipant?.setCameraEnabled(true);
        final pubs = _room?.localParticipant?.videoTrackPublications;
        if (pubs != null && pubs.isNotEmpty) {
          setState(() => _localVideoTrack = pubs.first.track as VideoTrack?);
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _toggleMic() async {
    setState(() => _isMicMuted = !_isMicMuted);
    await _room?.localParticipant?.setMicrophoneEnabled(!_isMicMuted);
  }

  void _hangUp() async {
    try {
      final payload = jsonEncode({'type': 'call_ended'});
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
    } catch (e) {}
    await _room?.disconnect();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                _remoteVideoTracks.isNotEmpty
                    ? VideoTrackRenderer(
                        _remoteVideoTracks.values.first,
                        fit: VideoViewFit.cover,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white10,
                              child: Icon(
                                LucideIcons.user,
                                size: 40,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.chatData['name'] ?? 'Arama Yapılıyor...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                if (_localVideoTrack != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    right: 16,
                    child: Container(
                      width: 110,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: VideoTrackRenderer(
                          _localVideoTrack!,
                          fit: VideoViewFit.cover,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'mic',
                        backgroundColor: _isMicMuted
                            ? Colors.red
                            : Colors.white10,
                        onPressed: _toggleMic,
                        child: Icon(
                          _isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
                          color: Colors.white,
                        ),
                      ),
                      FloatingActionButton(
                        heroTag: 'hangup',
                        backgroundColor: Colors.red,
                        onPressed: _hangUp,
                        child: const Icon(
                          LucideIcons.phoneOff,
                          color: Colors.white,
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
