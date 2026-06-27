import 'package:flutter/material.dart';

class AjansBadgeWrapper extends StatelessWidget {
  final Widget child;
  final bool isAjans;

  const AjansBadgeWrapper({
    super.key,
    required this.child,
    required this.isAjans,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAjans) return child;

    return Stack(
      alignment: Alignment.bottomRight, // Rozeti köşeye koyuyoruz
      children: [
        child,
        // 🔥 AJANS ROZETİ (Çerçevenin üstünde küçük bir yıldız)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, size: 12, color: Colors.amber),
          ),
        ),
      ],
    );
  }
}
