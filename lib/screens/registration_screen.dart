import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../main.dart'; // Ana ekrana geçiş için

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _step = 1;
  String _selfieStatus = 'idle'; // 'idle', 'capturing', 'done'
  
  // Form Verileri
  String _gender = 'Kişi (Male)';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _zodiac = 'Qoç';
  final TextEditingController _bioController = TextEditingController();

  final List<String> _zodiacSigns = [
    'Qoç', 'Buğa', 'Əkizlər', 'Xərçəng', 'Şir', 'Qız', 
    'Tərəzi', 'Əqrəb', 'Oxatan', 'Oğlaq', 'Dolça', 'Balıqlar'
  ];

  void _handleSelfieSimulation() async {
    setState(() => _selfieStatus = 'capturing');
    
    // Yüz tanıma / kamera simülasyonu (2 saniye)
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _selfieStatus = 'done');
    }
  }

  void _completeRegistration() {
    // Burada API çağrısı yapıp verileri kaydedebilirsin.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Qeydiyyat uğurla tamamlandı!"), backgroundColor: Colors.green),
    );
    
    // Ana ekrana yönlendir
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigator()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Bar (Başlık ve Adım)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "FiFi Live Qeydiyyat",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryPink),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.2),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Addım $_step / 3", style: const TextStyle(color: AppColors.primaryPurple, fontSize: 12)),
                  )
                ],
              ),
              const Spacer(),
              
              // Dinamik İçerik (Adımlara Göre)
              if (_step == 1) _buildStep1(),
              if (_step == 2) _buildStep2(),
              if (_step == 3) _buildStep3(),
              
              const Spacer(),
              
              // Alt Butonlar (Geri ve İleri/Tamamla)
              Row(
                children: [
                  if (_step > 1)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.borderWhite),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Geri", style: TextStyle(color: AppColors.textGray)),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_step == 2 && _nameController.text.isEmpty) 
                          ? null 
                          : () {
                              if (_step < 3) {
                                setState(() => _step++);
                              } else {
                                _completeRegistration();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        disabledBackgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_step == 3 ? "Tamamla" : "Növbəti", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Xoş gəldiniz! Cinsinizi seçin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Sizə ən uyğun tövsiyələri göstərmək üçün bu seçim vacibdir.", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Kişi (Male)', '♂', Colors.blue, "Ödənişli Mesajlar")),
            const SizedBox(width: 16),
            Expanded(child: _buildGenderOption('Qadın (Female)', '♀', AppColors.primaryPink, "Hediye Qazanmaq")),
          ],
        )
      ],
    );
  }

  Widget _buildGenderOption(String label, String icon, Color color, String subTitle) {
    final isSelected = _gender == label;
    return GestureDetector(
      onTap: () => setState(() => _gender = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white10,
          border: Border.all(color: isSelected ? color : AppColors.borderWhite, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(icon, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subTitle, style: const TextStyle(fontSize: 10, color: AppColors.textGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Profil Məlumatları", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _buildTextField("Ad / Nickname", _nameController, hint: "Məsələn: Alexander"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Yaş", _ageController, isNumber: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField("Boy (cm)", _heightController, isNumber: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildTextField("Kilo (kg)", _weightController, isNumber: true)),
          ],
        ),
        const SizedBox(height: 12),
        const Text("Bürc Seçimi", style: TextStyle(fontSize: 12, color: AppColors.textGray)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderWhite),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _zodiac,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              items: _zodiacSigns.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _zodiac = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField("Öz haqqınızda (Bio)", _bioController, maxLines: 3, hint: "Hobbiləriniz, maraqlarınız..."),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}), // Update UI for validation
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fake Hesabın Qarşısını Almaq üçün Selfie Doğrulama", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Platformanın güvənliyi üçün real olduğunuzu təsdiqləyin.", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
        const SizedBox(height: 32),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3), width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              if (_selfieStatus == 'idle') ...[
                const CircleAvatar(radius: 40, backgroundColor: Colors.white10, child: Text("📸", style: TextStyle(fontSize: 32))),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleSelfieSimulation,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                  child: const Text("Doğrulamaq üçün Selfie Çək", style: TextStyle(color: Colors.white)),
                )
              ],
              if (_selfieStatus == 'capturing') ...[
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 6),
                ),
                const SizedBox(height: 16),
                const Text("Kamera yoxlanılır ve analiz edilir...", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
              ],
              if (_selfieStatus == 'done') ...[
                const CircleAvatar(radius: 40, backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 40)),
                const SizedBox(height: 16),
                const Text("Mükəmməl! Hesab Təsdiqləndi", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Mavi Təsdiqlənmiş profil nişanı aldınız.", style: TextStyle(color: AppColors.textGray, fontSize: 10)),
              ]
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldAlert, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Qadın istifadəçilər təsdiqləndikdən sonra yayımlardan və gələn zənglərdən 100% pul qazanma şansı əldə edirlər.",
                  style: TextStyle(color: Colors.amber, fontSize: 10),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}