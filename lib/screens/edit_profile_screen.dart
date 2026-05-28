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
  final _nameController = TextEditingController(text: "Alexander");
  final _bioController = TextEditingController(text: "Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği");
  final _heightController = TextEditingController(text: "180");
  final _weightController = TextEditingController(text: "75");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: context.textPrimary)),
      ),
      body: MainBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(label: "Ad / Nickname", hint: "Örnek: Alexander", controller: _nameController, icon: LucideIcons.user),
                const SizedBox(height: 12),
                CustomTextField(label: "Bio", hint: "Kendinden bahset", controller: _bioController, maxLines: 3, icon: LucideIcons.fileText),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: CustomTextField(label: "Boy (cm)", hint: "180", controller: _heightController, isNumber: true, icon: LucideIcons.arrowUpRight)),
                    const SizedBox(width: 8),
                    Expanded(child: CustomTextField(label: "Kilo (kg)", hint: "75", controller: _weightController, isNumber: true, icon: LucideIcons.activity)),
                  ],
                ),
                const SizedBox(height: 24),
                PremiumButton(
                  text: "Kaydet",
                  icon: LucideIcons.save,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kaydedildi!"), backgroundColor: Colors.green));
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
