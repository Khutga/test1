import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> chatData;

  const ChatScreen({super.key, required this.chatData});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"id": 1, "text": "Merhaba, yayınıma geldiğin için teşekkürler!", "sender": 'them', "time": '14:20'}
  ];
  bool _isAiLoading = false;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        "id": DateTime.now().millisecondsSinceEpoch,
        "text": _controller.text,
        "sender": 'me',
        "time": 'Şimdi'
      });
      _controller.clear();
    });
  }

  Future<void> _handleAIAssist() async {
    setState(() => _isAiLoading = true);
    
    // TODO: Burada Gemini API servisini çağıracaksın.
    // Şimdilik 1 saniyelik bir gecikme simülasyonu yapıyoruz.
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _controller.text = "Selam! Yayın harikaydı, enerjine bayıldım. 😊";
      _isAiLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryPink.withOpacity(0.5),
              child: Text(widget.chatData['name'][0], style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.chatData['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text("Çevrimiçi", style: TextStyle(fontSize: 10, color: Colors.green)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m['sender'] == 'me';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      gradient: isMe ? const LinearGradient(colors: [AppColors.primaryPurple, AppColors.primaryPink]) : null,
                      color: isMe ? null : Colors.white10,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isMe ? const Radius.circular(0) : null,
                        bottomLeft: !isMe ? const Radius.circular(0) : null,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m['text'], style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(m['time'], style: TextStyle(fontSize: 9, color: isMe ? Colors.white70 : AppColors.textGray)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom Input Alanı
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                InkWell(
                  onTap: _isAiLoading ? null : _handleAIAssist,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
                    ),
                    child: _isAiLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink))
                        : const Icon(LucideIcons.sparkles, color: AppColors.primaryPurple, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Mesaj yaz...",
                      hintStyle: const TextStyle(color: AppColors.textGray),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}