import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

Widget adminField(String label, TextEditingController controller, {bool isNumber = false}) {
  return Builder(
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ],
    ),
  );
}

Widget adminBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
  );
}

void silOnayDialog(BuildContext context, VoidCallback onSil) {
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: context.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Silmek istediğine emin misin?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary)),
      content: Text("Bu işlem geri alınamaz.", style: TextStyle(color: context.textSecondary, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text("İptal", style: TextStyle(color: context.textSecondary))),
        ElevatedButton(
          onPressed: () { Navigator.pop(c); onSil(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text("Sil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}