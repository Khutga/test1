import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Projendeki yolları kendi klasör yapına göre kontrol et
import 'core/app_colors.dart';
import 'core/theme_provider.dart';
import 'screens/mainScreen/mainPage.dart';
import 'screens/accountScreen/registration_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: FiFiLiveApp()));
}

class FiFiLiveApp extends StatelessWidget {
  const FiFiLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDark;
        SystemChrome.setSystemUIOverlayStyle(
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return MaterialApp(
          title: 'FiFi Live',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AuthProvider'ın o anki durumunu dinle (true, false veya loading)
    final authState = ref.watch(authProvider);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(authProvider.notifier).testGirisYap();
  });
    return authState.when(
      data: (isLoggedIn) {
        if (isLoggedIn) {
          return const MainNavigator(); // Giriş yapılmışsa ana sayfa
        } else {
          return const RegistrationScreen(); // Yapılmamışsa kayıt ekranı
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), // Kontrol edilirken dönen yuvarlak
        ),
      ),
      // Hata durumunda kırmızı ekran basmak yerine direkt Registration ekranına atıyoruz
      error: (_, __) => const RegistrationScreen(),
    );
  }
}
