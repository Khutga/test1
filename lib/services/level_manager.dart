import 'dart:math';
import 'package:flutter/material.dart';

class LevelManager {
  // 1. XP'den mevcut Level'i hesaplar
  static int getLevel(int xp) {
    if (xp <= 0) return 1;
    return (sqrt(xp / 100)).floor() + 1;
  }

  // 2. Bir sonraki Level'a geçmek için Bar'ın % kaç dolu olduğunu bulur (0.0 - 1.0)
  static double getProgress(int xp) {
    if (xp <= 0) return 0.0;
    int currentLevel = getLevel(xp);
    int currentLevelBaslangicXp = (pow(currentLevel - 1, 2) * 100).toInt();
    int nextLevelXp = (pow(currentLevel, 2) * 100).toInt();
    
    int xpIntoLevel = xp - currentLevelBaslangicXp;
    int xpNeededForNext = nextLevelXp - currentLevelBaslangicXp;
    
    if (xpNeededForNext == 0) return 0.0;
    return xpIntoLevel / xpNeededForNext;
  }

  // 3. Sonraki Level için gereken Toplam XP'yi verir
  static int getNextLevelXp(int xp) {
    int currentLevel = getLevel(xp);
    return (pow(currentLevel, 2) * 100).toInt();
  }

  // 4. 🔥 VIP ÇERÇEVE RENGİ
  static Color getFrameColor(int level) {
    if (level >= 30) return Colors.purpleAccent; // Efsanevi
    if (level >= 20) return Colors.amber;        // Altın
    if (level >= 10) return Colors.blueGrey;     // Gümüş
    return Colors.transparent;                   // Başlangıç
  }
}