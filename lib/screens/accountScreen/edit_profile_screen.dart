import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/sql_servis.dart';
import '../../widgets/custom_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = true;
  int _userId = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('kullanici_id') ?? 1;

    final res = await SqlServis.cek(
      tablo: 'hesaplar',
      sartlar: {'id': _userId},
    );
    if (res.basarili && res.veri.isNotEmpty) {
      final user = res.veri.first;
      _nameController.text = user['kullanici_adi'] ?? '';
      _bioController.text = user['biyografi'] ?? '';
      _heightController.text = user['boy']?.toString() ?? '';
      _weightController.text = user['kilo']?.toString() ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    setState(() => _isLoading = true);

    final res = await SqlServis.guncelle(
      tablo: 'hesaplar',
      veriler: {
        'kullanici_adi': _nameController.text.trim(),
        'isim': _nameController.text.trim(),
        'biyografi': _bioController.text.trim(),
        'boy': int.tryParse(_heightController.text.trim()),
        'kilo': double.tryParse(_weightController.text.trim()),
      },
      sartlar: {'id': _userId},
    );

    setState(() => _isLoading = false);

    if (res.basarili && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil başarıyla güncellendi!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profili Düzenle",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: context.textPrimary,
          ),
        ),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: "Kullanıcı Adı",
                        hint: "Örnek: Alexander",
                        controller: _nameController,
                        icon: LucideIcons.user,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: "Bio",
                        hint: "Kendinden bahset",
                        controller: _bioController,
                        maxLines: 3,
                        icon: LucideIcons.fileText,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Boy (cm)",
                              hint: "180",
                              controller: _heightController,
                              isNumber: true,
                              icon: LucideIcons.arrowUpRight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              label: "Kilo (kg)",
                              hint: "75",
                              controller: _weightController,
                              isNumber: true,
                              icon: LucideIcons.activity,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PremiumButton(
                        text: "Kaydet",
                        icon: LucideIcons.save,
                        onPressed: _saveData,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
