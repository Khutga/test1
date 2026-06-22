import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nivi/screens/accountScreen/user_profile_screen.dart';
import '../core/app_colors.dart';

// ─── GLASS CONTAINER ───
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.border.withOpacity(0.5)),
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: container,
      );
    }
    return container;
  }
}

// ─── AVATAR ───
class GlowAvatar extends StatelessWidget {
  final String initial;
  final double radius;
  final Color? color;

  const GlowAvatar({
    super.key,
    required this.initial,
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accent;
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withOpacity(context.isDark ? 0.7 : 0.85),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.55,
        ),
      ),
    );
  }
}

// ─── PREMIUM BUTTON ───
class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          disabledBackgroundColor: context.textSecondary.withOpacity(0.15),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TEXT FIELD ───
class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool isNumber;
  final int maxLines;
  final TextInputType? keyboardType; // 🔥 Yeni parametre eklendi

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.isNumber = false,
    this.maxLines = 1,
    this.keyboardType, // 🔥 Parametreyi tanımladık
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          // 🔥 Eğer keyboardType verildiyse onu kullan, verilmediyse eski isNumber mantığına bak
          keyboardType: keyboardType ?? (isNumber ? TextInputType.number : TextInputType.text),
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: (maxLines == 1 && icon != null)
                ? Icon(icon, color: context.textSecondary, size: 18)
                : null,
            filled: true,
            fillColor: context.isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MENU TILE ───
class MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final Widget? trailing;

  const MenuActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              if (trailing != null) trailing!,
              if (badge == null && trailing == null)
                Icon(
                  LucideIcons.chevronRight,
                  color: context.textSecondary.withOpacity(0.4),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GRADIENT BADGE ───
class GradientBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const GradientBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = AppTheme.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GLASS ICON BUTTON ───
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: context.border.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color ?? context.textPrimary, size: 18),
      ),
    );
  }
}

// ─── LIVE STREAM CARD (KOMPAKT) ───

class LiveStreamCard extends StatelessWidget {
  final Map<String, dynamic> stream;
  final VoidCallback onTap;

  const LiveStreamCard({super.key, required this.stream, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. Veritabanından gelen verileri hata vermeyecek (null-safe) şekilde alıyoruz:
    final izleyiciSayisi = stream['izleyici_sayisi']?.toString() ?? '0';
    final yayinciIsmi = stream['yayin_sahibi_isim'] ?? 'Bilinmiyor';
    final etiket = stream['etiket']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap, // Kartın geneline tıklanınca yayına gider
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.card,
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(color: context.border.withOpacity(0.5)),
        ),
        child: Stack(
          children: [
            // Placeholder background
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: context.isDark
                      ? [Colors.grey[850]!, Colors.grey[900]!]
                      : [Colors.grey[200]!, Colors.grey[300]!],
                ),
              ),
            ),

            // CANLI badge
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.radio, color: Colors.white, size: 13),
                    SizedBox(width: 3),
                    Text(
                      "CANLI",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. İzleyici sayısı (Yeni Veritabanı Değişkeni ile)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.eye,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      izleyiciSayisi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Alt bilgi (İsim ve Etiket Yeni Veritabanı Değişkeni ile)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İSME TIKLAYINCA HIZLI PROFİL AÇILAN KISIM
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              hedefKullaniciAdi: yayinciIsmi,
                            ), 
                          ),
                        );
                      },
                      // Tıklama alanı (hitbox) biraz genişletildi ki kullanıcı rahatça basabilsin
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 4,
                          bottom: 4,
                          right: 16,
                        ),
                        color: Colors
                            .transparent, // Transparan arka plan tıklamayı algılar
                        child: Text(
                          yayinciIsmi,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Veritabanındaki etiket boş değilse ekrana bas
                    if (etiket.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              etiket,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB BUTTON ───
class GlassTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const GlassTabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent
              : (context.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : context.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ─── MAIN BACKGROUND (SADE) ───
class MainBackground extends StatelessWidget {
  final Widget child;
  const MainBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(color: context.bg, child: child);
  }
}
