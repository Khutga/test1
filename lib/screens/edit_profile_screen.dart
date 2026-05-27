import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';
import '../widgets/custom_widgets.dart'; 
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Alexander");
  final TextEditingController _bioController = TextEditingController(text: "Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği");
  final TextEditingController _heightController = TextEditingController(text: "180");
  final TextEditingController _weightController = TextEditingController(text: "75");

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil dəyişiklikləri yadda saxlanıldı!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Profili Redaktə Et", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: MainBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(label: "Ad / Nickname", hint: "Məsələn: Alexander", controller: _nameController, icon: LucideIcons.user),
              const SizedBox(height: 16),
              CustomTextField(label: "Bio (Haqqında qısa məlumat)", hint: "Özün haqqında yaz", controller: _bioController, maxLines: 3, icon: LucideIcons.fileText),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: CustomTextField(label: "Boy (sm)", hint: "180", controller: _heightController, isNumber: true, icon: LucideIcons.arrowUpRight)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: "Çəki (kq)", hint: "75", controller: _weightController, isNumber: true, icon: LucideIcons.activity)),
                ],
              ),
              const SizedBox(height: 32),
              
              PremiumButton(
                text: "Dəyişiklikləri Yadda Saxla",
                icon: LucideIcons.save,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}