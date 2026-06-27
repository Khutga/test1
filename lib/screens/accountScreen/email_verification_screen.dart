import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_colors.dart';
import '../../services/auth_servis.dart';
import '../../widgets/custom_widgets.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback
  onVerified; // Doğrulama başarılı olunca çalışacak fonksiyon

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = true;
  String _serverCode = ""; // Mailden dönen gerçek kod burada tutulacak

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
  }

  // Sayfa açılır açılmaz PHP servisine istek atıp mail gönderiyoruz
  Future<void> _sendVerificationEmail() async {
    setState(() => _isLoading = true);

    final res = await AuthServis.epostaDogrulamaKoduGonder(widget.email);

    if (res['basarili'] == true) {
      setState(() {
        _serverCode = res['kod']; // Gelen 6 haneli kodu hafızaya al
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doğrulama kodu mailinize gönderildi!"),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      print("Mail gönderme hatası: ${res['mesaj']}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['mesaj']), backgroundColor: AppTheme.danger),
      );
    }
  }

  // Kullanıcının girdiği kodu kontrol ediyoruz
  void _verifyCode() {
    final enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen kodu girin!"),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    if (enteredCode == _serverCode) {
      // Şifreler eşleşti, kayıt işlemine (veya yüz doğrulamaya) devam et
      widget.onVerified();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hatalı kod girdiniz, lütfen tekrar deneyin."),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Güvenlik Onayı"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: MainBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accent),
                      SizedBox(height: 16),
                      Text(
                        "Mail gönderiliyor, lütfen bekleyin...",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.mailCheck,
                          size: 60,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "E-posta Adresini Doğrula",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${widget.email} adresine 6 haneli bir doğrulama kodu gönderdik. Lütfen spam/gereksiz kutusunu da kontrol et.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      CustomTextField(
                        label: "Doğrulama Kodu",
                        hint: "Örn: 123456",
                        controller: _codeController,
                        icon: LucideIcons.shieldCheck,
                        isNumber: true,
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Doğrula ve Devam Et",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _sendVerificationEmail,
                        child: const Text(
                          "Kodu Tekrar Gönder",
                          style: TextStyle(
                            color: AppTheme.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
