import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/widgets/custom_widgets.dart';
import '../../core/app_colors.dart';
import '../../main.dart';
import '../mainScreen/mainPage.dart';
import '../../services/auth_servis.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _step = 1;
  String _selfieStatus = 'idle';

  String _gender = 'Erkek (Male)';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _epostaController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _zodiac = '';
 


  String _calculateZodiac(DateTime date) {
    int day = date.day;
    int month = date.month;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Koç ♈';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Boğa ♉';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 21)) return 'İkizler ♊';
    if ((month == 6 && day >= 22) || (month == 7 && day <= 22)) return 'Yengeç ♋';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Aslan ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Başak ♍';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Terazi ♎';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Akrep ♏';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Yay ♐';
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'Oğlak ♑';
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Kova ♒';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Balık ♓';
    return '';
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: eighteenYearsAgo,
      firstDate: DateTime(1950),
      lastDate: eighteenYearsAgo,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accent,
              onPrimary: Colors.white,
              surface: context.card,
              onSurface: context.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _zodiac = _calculateZodiac(picked);
      });
    }
  }

  void _handleSelfieSimulation() async {
    setState(() => _selfieStatus = 'capturing');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _selfieStatus = 'done');
  }

  void _completeRegistration() async {
    if (_nameController.text.isEmpty || _epostaController.text.isEmpty || _sifreController.text.isEmpty || _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen zorunlu alanları doldurun.")));
      return;
    }

    // Format: YYYY-MM-DD
    String dogumTarihi = "${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}";
    String secilenCinsiyet = _gender == 'Erkek (Male)' ? 'Erkek' : (_gender == 'Kadın (Female)' ? 'Kadın' : 'Belirtmek İstemiyor');

    var res = await AuthServis.hesapOlustur(
      kullaniciAdi: _nameController.text.trim(),
      eposta: _epostaController.text.trim(),
      sifre: _sifreController.text.trim(),
      dogumTarihi: dogumTarihi,
      cinsiyet: secilenCinsiyet,
      ekAlanlar: {
        "biyografi": _bioController.text,
        "boy": _heightController.text.isNotEmpty ? int.tryParse(_heightController.text) : null,
        "kilo": _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        "burc": _zodiac,
      }
    );

    if (res.basarili && res.eklenenId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('kullanici_id', int.parse(res.eklenenId!)); // ID'yi hafızaya al

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarılı!"), backgroundColor: AppTheme.success));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigator()),
          (route) => false,
        );
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.mesaj), backgroundColor: AppTheme.danger));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "FiFi Live",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Adım $_step / 3",
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (_step == 1) _buildStep1(context),
                        if (_step == 2) _buildStep2(context),
                        if (_step == 3) _buildStep3(context),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (_step > 1)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OutlinedButton(
                              onPressed: () => setState(() => _step--),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                side: BorderSide(color: context.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                "Geri",
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: (_step == 2 && (_nameController.text.isEmpty || _selectedBirthDate == null))
                              ? null
                              : () {
                                  if (_step < 3) {
                                    setState(() => _step++);
                                  } else {
                                    _completeRegistration();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            disabledBackgroundColor: context.textSecondary.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            _step == 3 ? "Kaydı Tamamla" : "Sonraki Adım",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Zaten hesabın var mı? ",
                      style: TextStyle(color: context.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Giriş Yap",
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
    );
  }

  Widget _buildStep1(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hoş Geldiniz! Cinsiyetinizi Seçin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            "Size en uygun tavsiyeleri göstermek için bu seçim önemlidir.",
            style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(context, 'Erkek (Male)', '♂', AppTheme.accentLight, "Ücretli Mesajlar"),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption(context, 'Kadın (Female)', '♀', AppTheme.danger, "Hediye Kazanmak"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(BuildContext context, String label, String icon, Color color, String subTitle) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : context.isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
          border: Border.all(color: isSelected ? color : context.border, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(icon, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
            const SizedBox(height: 4),
            Text(subTitle, style: TextStyle(fontSize: 12, color: isSelected ? context.textPrimary : context.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profil Bilgileri", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.textPrimary)),
          const SizedBox(height: 24),
         _buildTextField(context, "Kullanıcı Adı", _nameController, hint: "Örnek: Alexander", icon: LucideIcons.user),
          const SizedBox(height: 16),
          _buildTextField(context, "E-posta", _epostaController, hint: "E-posta adresiniz", icon: LucideIcons.mail),
          const SizedBox(height: 16),
          _buildTextField(context, "Şifre", _sifreController, hint: "Şifreniz", icon: LucideIcons.key),
          const SizedBox(height: 16),

          Text("Doğum Tarihi", style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectBirthDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, color: context.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedBirthDate == null ? "Doğum Tarihinizi seçin" : "${_selectedBirthDate!.day}.${_selectedBirthDate!.month}.${_selectedBirthDate!.year}",
                    style: TextStyle(color: _selectedBirthDate == null ? context.textSecondary : context.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          if (_zodiac.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text("Burcunuz", style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 12),
                  Text(_zodiac, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(LucideIcons.lock, color: context.textSecondary, size: 16),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(context, "Boy (cm)", _heightController, isNumber: true, icon: LucideIcons.arrowUpRight)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(context, "Kilo (kg)", _weightController, isNumber: true, icon: LucideIcons.activity)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(context, "Kendiniz hakkında (Bio)", _bioController, maxLines: 3, hint: "Hobileriniz, sizi tanımlayan şeyler...", icon: LucideIcons.fileText),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, {String? hint, bool isNumber = false, int maxLines = 1, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.5), fontSize: 14),
            prefixIcon: maxLines == 1 ? Icon(icon, color: context.textSecondary, size: 20) : null,
            filled: true,
            fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Selfie Doğrulama", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            "Platformun güvenliği için gerçek biri olduğunuzu doğrulayın. Sadece birkaç saniyenizi alacak.",
            style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.05),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 1.5),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                if (_selfieStatus == 'idle') ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: context.card, shape: BoxShape.circle, border: Border.all(color: context.border)),
                    child: const Icon(LucideIcons.camera, size: 48, color: AppTheme.accent),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _handleSelfieSimulation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Kamerayı Aç", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
                if (_selfieStatus == 'capturing') ...[
                  const SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 4),
                  ),
                  const SizedBox(height: 24),
                  const Text("Yüz hatlarınız analiz ediliyor...", style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
                if (_selfieStatus == 'done') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppTheme.success.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.check, color: AppTheme.success, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text("Mükemmel! Onaylandı", style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text("Mavi onay rozeti hesabınıza eklendi.", style: TextStyle(color: context.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}