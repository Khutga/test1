import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';
import '../mainScreen/mainPage.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _epostaController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  bool _isLoading = false;
  bool _sifreGizli = true;

  Future<void> _girisYap() async {
    final eposta = _epostaController.text.trim();
    final sifre = _sifreController.text.trim();

    if (eposta.isEmpty || sifre.isEmpty) {
      _snackBar("Lütfen e-posta ve şifre alanlarını doldurun.", AppTheme.danger);
      return;
    }

    setState(() => _isLoading = true);

    // Veritabanında e-posta + şifre eşleşmesi ara
    final res = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {
        'eposta': eposta,
        'sifre_hash': sifre,
      },
    );

    setState(() => _isLoading = false);

    if (res.basarili && res.veri.isNotEmpty) {
      // Giriş başarılı — kullanıcı ID'sini hafızaya kaydet
      final int kullaniciId = int.parse(res.veri.first['id'].toString());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('kullanici_id', kullaniciId);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigator()),
          (route) => false,
        );
      }
    } else {
      _snackBar("E-posta veya şifre hatalı.", AppTheme.danger);
    }
  }

  void _snackBar(String mesaj, Color renk) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: renk),
    );
  }

  @override
  void dispose() {
    _epostaController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── LOGO ───
                  const Text(
                    "FiFi Live",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.accent,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Hesabınıza giriş yapın",
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ─── FORM ───
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // E-posta
                        Text(
                          "E-posta",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _epostaController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: "ornek@email.com",
                            hintStyle: TextStyle(
                              color: context.textSecondary.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(LucideIcons.mail, color: context.textSecondary, size: 20),
                            filled: true,
                            fillColor: context.isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        Text(
                          "Şifre",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _sifreController,
                          obscureText: _sifreGizli,
                          style: TextStyle(fontSize: 14, color: context.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Şifrenizi girin",
                            hintStyle: TextStyle(
                              color: context.textSecondary.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(LucideIcons.lock, color: context.textSecondary, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _sifreGizli = !_sifreGizli),
                              child: Icon(
                                _sifreGizli ? LucideIcons.eyeOff : LucideIcons.eye,
                                color: context.textSecondary,
                                size: 20,
                              ),
                            ),
                            filled: true,
                            fillColor: context.isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: context.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Giriş Butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _girisYap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              disabledBackgroundColor: context.textSecondary.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Giriş Yap",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── KAYIT OL LİNKİ ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Hesabın yok mu? ",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                          );
                        },
                        child: const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}