import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Simüle edilmiş mevcut kullanıcı datası
  final TextEditingController _nameController = TextEditingController(text: "Alexander");
  final TextEditingController _bioController = TextEditingController(text: "Müzik, Kodlama ve Kahve. ☕️\nİstanbul ♍️ Başak Erkeği");
  final TextEditingController _ageController = TextEditingController(text: "22");
  final TextEditingController _heightController = TextEditingController(text: "180");
  final TextEditingController _weightController = TextEditingController(text: "75");
  
  String _gender = 'Kişi (Male)';
  String _zodiac = 'Başak';
  String _selectedColor = 'purple-pink';

  final List<Map<String, String>> _colors = [
    {'id': 'purple-pink', 'name': 'Neon Purple-Pink', 'hex': '#A855F7'},
    {'id': 'cyber-blue', 'name': 'Cyber Blue', 'hex': '#06B6D4'},
    {'id': 'flame-gold', 'name': 'Flame Gold', 'hex': '#F59E0B'},
    {'id': 'luxe-emerald', 'name': 'Luxe Emerald', 'hex': '#10B981'},
  ];

  final List<String> _zodiacSigns = ['Qoç', 'Buğa', 'Əkizlər', 'Xərçəng', 'Şir', 'Başak', 'Tərəzi', 'Əqrəb', 'Oxatan', 'Oğlaq', 'Dolça', 'Balıqlar'];

  Color _hexToColor(String hexString) {
    return Color(int.parse(hexString.substring(1, 7), radix: 16) + 0xFF000000);
  }

  void _handleSave() {
    // Burada API güncelleme mantığı olur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil dəyişiklikləri yadda saxlanıldı!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Profili Redaktə Et", style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Teması Seçici
            const Text("Profil Avatarı Teması", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final c = _colors[index];
                final isSelected = _selectedColor == c['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c['id']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryPurple.withOpacity(0.15) : Colors.white10,
                      border: Border.all(color: isSelected ? AppColors.primaryPurple : AppColors.borderWhite),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(color: _hexToColor(c['hex']!), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c['name']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            _buildTextField("Ad / Nickname", _nameController),
            const SizedBox(height: 12),
            _buildTextField("Bio (Haqqında qısa məlumat)", _bioController, maxLines: 3),
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown("Cins", _gender, ['Kişi (Male)', 'Qadın (Female)'], (val) => setState(() => _gender = val!)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown("Bürc", _zodiac, _zodiacSigns, (val) => setState(() => _zodiac = val!)),
                ),
              ],
            ),

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

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Yadda Saxla", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}