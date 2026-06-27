import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:nivi/services/sql_servis.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/custom_widgets.dart';
import '../../core/app_colors.dart';

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
class HostLivePage extends StatefulWidget {
  final String username;
  final String roomName;
  final String etiket;

  const HostLivePage({
    super.key,
    required this.username,
    required this.roomName,
    required this.etiket,
  });

  @override
  State<HostLivePage> createState() => _HostLivePageState();
}

class _HostLivePageState extends State<HostLivePage> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  bool _isLoading = true;
  int _viewerCount = 0;
  String _activeRoomName = "";

  DateTime? _yayinBaslamaZamani;

  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- HEDİYE ANİMASYON DEĞİŞKENLERİ ---
  final List<FloatingGift> _floatingGifts = [];
  int _giftIdCounter = 0;
  final Random _random = Random();

  // --- PK BATTLE DEĞİŞKENLERİ ---
  bool _isPkActive = false;
  String _pkOpponentName = "";
  int _pkTimeLeft = 120;
  int _hostScore = 0;
  int _opponentScore = 0;
  Timer? _pkTimer;
  Timer? _pkInviteTimer;
  int? _currentIncomingRequestId;

  // 🔥 YENİ: PK Renk Kodlamaları
  final Color _hostColor = Colors.blueAccent;
  final Color _opponentColor = AppTheme.danger;

  final String pyServerUrl = 'https://yayin.sunucucodefellas.shop';
  final String livekitServerUrl = 'wss://nivi-44k377vl.livekit.cloud';
  final String phpApiUrl = 'http://codefellas.com.tr/apps/nivi/api/api.php';
  final String phpApiKey = 'GizliAnahtar_Codefellas_2026!';

  @override
  void initState() {
    super.initState();
    _activeRoomName = widget.roomName;
    _connectToLiveKit(_activeRoomName);
    _startPkInviteListener();
  }

  // ==========================================
  // SQL FONKSİYONLARI
  // ==========================================
  Future<List<dynamic>> _sqlCek(
    String tablo,
    Map<String, dynamic> sartlar,
  ) async {
    try {
      final res = await http.post(
        Uri.parse(phpApiUrl),
        body: {
          'api_key': phpApiKey,
          'islem': sartlar.isEmpty ? 'cek' : 'ozel_cek',
          'tablo': tablo,
          'sartlar': jsonEncode(sartlar),
          'geri_dondur': '',
        },
      );
      final data = jsonDecode(res.body);
      if (data['durum'] == 'basarili' && data['veri'] != null)
        return data['veri'];
    } catch (e) {
      debugPrint("SQL Çekme Hatası: $e");
    }
    return [];
  }

  Future<void> _sqlGuncelle(
    String tablo,
    Map<String, dynamic> veriler,
    Map<String, dynamic> sartlar,
  ) async {
    await http.post(
      Uri.parse(phpApiUrl),
      body: {
        'api_key': phpApiKey,
        'islem': 'guncelle',
        'tablo': tablo,
        'veriler': jsonEncode(veriler),
        'sartlar': jsonEncode(sartlar),
        'geri_dondur': '',
      },
    );
  }

  Future<void> _sqlEkle(String tablo, Map<String, dynamic> veriler) async {
    await http.post(
      Uri.parse(phpApiUrl),
      body: {
        'api_key': phpApiKey,
        'islem': 'ekle',
        'tablo': tablo,
        'veriler': jsonEncode(veriler),
        'sartlar': "{}",
        'geri_dondur': '',
      },
    );
  }

  Future<void> _sqlSil(String tablo, Map<String, dynamic> sartlar) async {
    await http.post(
      Uri.parse(phpApiUrl),
      body: {
        'api_key': phpApiKey,
        'islem': 'sil',
        'tablo': tablo,
        'sartlar': jsonEncode(sartlar),
        'geri_dondur': '',
      },
    );
  }

  // ==========================================
  // DAVET RADARI
  // ==========================================
  void _startPkInviteListener() {
    _pkInviteTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isPkActive) return;

      final gelenDavetler = await _sqlCek('pk_istekleri', {
        'alici_oda': widget.roomName,
        'durum': 'bekliyor',
      });
      if (gelenDavetler.isNotEmpty) {
        final req = gelenDavetler.first;
        if (_currentIncomingRequestId != req['id']) {
          _currentIncomingRequestId = int.parse(req['id'].toString());
          _showIncomingPkDialog(req);
        }
      }

      final kabulEdilenler = await _sqlCek('pk_istekleri', {
        'gonderen_oda': widget.roomName,
        'durum': 'kabul',
      });
      if (kabulEdilenler.isNotEmpty) {
        final req = kabulEdilenler.first;
        await _sqlSil('pk_istekleri', {'id': req['id']});
        _addSystemMessage("${req['alici_isim']} PK davetini kabul etti!");
        _startPk(req['alici_isim']);
      }

      final reddedilenler = await _sqlCek('pk_istekleri', {
        'gonderen_oda': widget.roomName,
        'durum': 'red',
      });
      if (reddedilenler.isNotEmpty) {
        final req = reddedilenler.first;
        await _sqlSil('pk_istekleri', {'id': req['id']});
        _addSystemMessage("${req['alici_isim']} PK davetini reddetti.");
      }
    });
  }

  void _showIncomingPkDialog(Map<String, dynamic> req) {
    if (_remoteVideoTracks.isNotEmpty) {
      _sqlGuncelle('pk_istekleri', {'durum': 'red'}, {'id': req['id']});
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "⚔️ Meydan Okuma!",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${req['gonderen_isim']} seni PK'ya davet ediyor. Kabul edersen odalar birleşecek!",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _sqlGuncelle('pk_istekleri', {'durum': 'red'}, {'id': req['id']});
              _currentIncomingRequestId = null;
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
              _currentIncomingRequestId = null;
              await _sqlGuncelle(
                'pk_istekleri',
                {'durum': 'kabul'},
                {'id': req['id']},
              );

              await http.post(
                Uri.parse('$pyServerUrl/forward_room'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'source_room': widget.roomName,
                  'target_room': req['gonderen_oda'],
                  'action': 'merge',
                }),
              );

              final mergePayload = jsonEncode({
                'type': 'room_merging',
                'target_room': req['gonderen_oda'],
              });
              await _room?.localParticipant?.publishData(
                utf8.encode(mergePayload),
                reliable: true,
              );

              await _room?.disconnect();
              _activeRoomName = req['gonderen_oda'];
              await _connectToLiveKit(_activeRoomName);
            },
            child: const Text(
              "Savaşa Katıl",
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
  // LIVEKIT BAĞLANTISI
  // ==========================================
  Future<void> _connectToLiveKit(String targetRoom) async {
    final prefs = await SharedPreferences.getInstance();
    final int? kayitliId = prefs.getInt('kullanici_id');
    setState(() => _isLoading = true);
    try {
      await [Permission.camera, Permission.microphone].request();

      final response = await http.post(
        Uri.parse('$pyServerUrl/get_token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room': targetRoom,
          'username': widget.username,
          'user_id': kayitliId?.toString(),
          'is_host': true,
          'etiket': widget.etiket,
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
          if (_isPkActive && e.participant!.identity == _pkOpponentName) {
            _endPk("Rakip bağlantıdan koptu!");
          }
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
              if (receiver == widget.username)
                _hostScore += (points as int);
              else if (receiver == _pkOpponentName)
                _opponentScore += (points as int);
            });
          }
        } else if (msgData['type'] == 'pk_start') {
          setState(() {
            _isPkActive = true;
            _pkOpponentName = msgData['opponent'];
            _pkTimeLeft = 120;
            _hostScore = 0;
            _opponentScore = 0;
          });
        } else if (msgData['type'] == 'pk_tick') {
          setState(() => _pkTimeLeft = msgData['time']);
        } else if (msgData['type'] == 'pk_end') {
          _endPk("PK Sona Erdi.");
        }
      });

      await _room?.connect(
        livekitServerUrl,
        token,
        connectOptions: const ConnectOptions(autoSubscribe: true),
      );

      await _room?.localParticipant?.setCameraEnabled(true);
      await _room?.localParticipant?.setMicrophoneEnabled(true);
      final publications = _room?.localParticipant?.videoTrackPublications;
      if (publications != null && publications.isNotEmpty) {
        if (mounted)
          setState(
            () => _localVideoTrack = publications.first.track as VideoTrack?,
          );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _updateViewerCount();
        });
        _addSystemMessage("Yayın başarıyla başlatıldı.");
        _yayinBaslamaZamani = DateTime.now(); // YAYIN BAŞLAMA SAATİNİ KAYDET
      }
    } catch (e) {
      _addSystemMessage("Bağlantı Hatası!");
    }
  }

  void _updateViewerCount() =>
      setState(() => _viewerCount = _room?.remoteParticipants.length ?? 0);

  // ==========================================
  // YENİ NESİL HEDİYE YÖNETİMİ
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
    setState(() {
      _floatingGifts.removeWhere((g) => g.id == id);
    });
  }

  // ==========================================
  // PK DAVET MENU VE BATTLE YÖNETİMİ
  // ==========================================
  void _showPkMenu() async {
    if (_remoteVideoTracks.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Meydan okumak için yayında yalnız olmalısınız! (Çoklu yayında PK atılamaz)",
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    final aktifYayinlar = await _sqlCek('aktif_yayinlar', {});
    final uygunYayinlar = aktifYayinlar
        .where(
          (y) =>
              y['yayin_sahibi_isim'] != widget.username &&
              (y['yonlendirilen_oda'] == null || y['yonlendirilen_oda'] == ""),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                border: Border(
                  top: BorderSide(color: AppTheme.accent.withOpacity(0.3)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "⚔️ Başka Yayıncılara Meydan Oku",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (uygunYayinlar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Şu an meydan okunacak aktif yayıncı yok.",
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: uygunYayinlar.length,
                        itemBuilder: (context, index) {
                          final p = uygunYayinlar[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        LucideIcons.radio,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      p['yayin_sahibi_isim'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.danger,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _sqlEkle('pk_istekleri', {
                                      'gonderen_isim': widget.username,
                                      'gonderen_oda': widget.roomName,
                                      'alici_isim': p['yayin_sahibi_isim'],
                                      'alici_oda': p['oda_adi'],
                                      'durum': 'bekliyor',
                                    });
                                    _addSystemMessage(
                                      "${p['yayin_sahibi_isim']} kişisine davet gönderildi. Cevap bekleniyor...",
                                    );
                                  },
                                  child: const Text(
                                    "Davet Et",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  void _startPk(String opponentName) async {
    await _sqlEkle('aktif_pk', {
      'oda_adi': _activeRoomName,
      'host_ismi': widget.username,
      'rakip_ismi': opponentName,
    });

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

    _pkTimer?.cancel();
    _pkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pkTimeLeft > 0) {
        setState(() => _pkTimeLeft--);
        _room?.localParticipant?.publishData(
          utf8.encode(jsonEncode({'type': 'pk_tick', 'time': _pkTimeLeft})),
        );
      } else {
        _endPk("Süre doldu!");
      }
    });
  }

  void _endPk(String reason) async {
    _pkTimer?.cancel();
    setState(() => _isPkActive = false);

    if (_activeRoomName == widget.roomName) {
      _room?.localParticipant?.publishData(
        utf8.encode(jsonEncode({'type': 'pk_end'})),
      );
      await _sqlSil('aktif_pk', {'oda_adi': _activeRoomName});
    } else {
      await http.post(
        Uri.parse('$pyServerUrl/forward_room'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source_room': widget.roomName,
          'target_room': _activeRoomName,
          'action': 'unmerge',
        }),
      );
      final payload = jsonEncode({
        'type': 'room_merging',
        'target_room': widget.roomName,
      });
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );

      await _room?.disconnect();
      _activeRoomName = widget.roomName;
      await _connectToLiveKit(_activeRoomName);
    }
    _addSystemMessage(reason);
  }

  Future<bool> _onWillPop() async {
    final payload = jsonEncode({'type': 'room_closed'});
    await _room?.localParticipant?.publishData(
      utf8.encode(payload),
      reliable: true,
    );

    await http.post(
      Uri.parse('$pyServerUrl/end_stream'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'room': widget.roomName}),
    );
    if (_isPkActive) await _sqlSil('aktif_pk', {'oda_adi': _activeRoomName});

    //  YAYIN KAPATINCA XP KAZANMA SİSTEMİ
    if (_yayinBaslamaZamani != null) {
      int gecenDakika = DateTime.now()
          .difference(_yayinBaslamaZamani!)
          .inMinutes;

      // Adam en az 1 dakika yayında kaldıysa XP ver
      if (gecenDakika > 0) {
        final prefs = await SharedPreferences.getInstance();
        int kendiId = prefs.getInt('kullanici_id') ?? 1;

        await SqlServis.xpEkle(kendiId, 'yayin_dakika', gecenDakika);
        debugPrint("Yayın bitti. $gecenDakika dakika için XP verildi!");
      }
    }

    return true;
  }

  // ==========================================
  // UI VE CHAT
  // ==========================================
  void _addSystemMessage(String text) {
    if (mounted)
      setState(
        () => _chatMessages.insert(
          0,
          ChatMessage(sender: "Sistem", text: text, isSystem: true),
        ),
      );
  }

  void _addChatMessage(String sender, String text) {
    if (mounted)
      setState(() {
        _chatMessages.insert(0, ChatMessage(sender: sender, text: text));
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
      await _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
      );
      _addChatMessage(widget.username, text);
      _chatController.clear();
      FocusScope.of(context).unfocus();
    }
  }

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
      Color trackBorderColor = Colors.transparent;
      if (_isPkActive) {
        if (data['name'] == widget.username) {
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
              // 🔥 YENİ: PK Modunda yatay sığdırma (contain), Normal modda dikey/tam sığdırma (cover)
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
            if (data['name'] != widget.username &&
                _activeRoomName == widget.roomName)
              Positioned(
                top: 12,
                right: 12,
                child: GlassIconButton(
                  icon: LucideIcons.logOut,
                  color: AppTheme.danger,
                  onTap: () => _endPk("Misafir gönderildi."),
                ),
              ),
          ],
        ),
      );
    }

    if (allTracks.length == 1) return buildTrack(allTracks[0]);

    // 2 Kişi olduğunda yan yana ve ortada ayırıcıyla göster
    if (allTracks.length == 2)
      return Row(
        children: [
          Expanded(child: buildTrack(allTracks[0])),
          Container(width: 2, color: Colors.black),
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
    _pkInviteTimer?.cancel();
    _pkTimer?.cancel();
    _room?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double pkPercentage = (_hostScore + _opponentScore) == 0
        ? 0.5
        : (_hostScore / (_hostScore + _opponentScore));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: _buildVideoLayout()),

            // ÜST BAR
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      "Yayıncı",
                                      style: TextStyle(
                                        color: AppTheme.accentGold,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: AppTheme.accent.withOpacity(
                                            0.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        widget.etiket,
                                        style: const TextStyle(
                                          color: AppTheme.accentLight,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                        onTap: () async {
                          if (await _onWillPop()) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PK BARI
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${widget.username}\n$_hostScore",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _hostColor,
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
                                style: TextStyle(
                                  color: _opponentColor,
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
                              backgroundColor: _opponentColor.withOpacity(0.9),
                              color: _hostColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // HEDİYELER
            ..._floatingGifts
                .map(
                  (gift) => AnimatedFloatingGift(
                    key: ValueKey(gift.id),
                    gift: gift,
                    onComplete: () => _removeGift(gift.id),
                  ),
                )
                .toList(),

            // CHAT LİSTESİ
            Positioned(
              bottom: 90,
              left: 16,
              width: 280,
              height: 220,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black, Colors.black],
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
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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

            // ALT BAR
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                  left: 16,
                  right: 16,
                  top: 24,
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
                    if (!_isPkActive && _activeRoomName == widget.roomName)
                      GestureDetector(
                        onTap: _showPkMenu,
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.danger, Colors.orange],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.danger.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            "⚔️",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              hintText: "Sohbete yaz...",
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.3),
                              contentPadding: const EdgeInsets.symmetric(
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
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.send,
                          size: 18,
                          color: Colors.white,
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
