import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_colors.dart';
import 'core/theme_provider.dart';
import 'screens/mainScreen/mainPage.dart';
import 'screens/accountScreen/login_screen.dart'; 
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
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (isLoggedIn) {
        if (isLoggedIn) {
          return const MainNavigator(); // Giriş yapılmışsa ana sayfa
        } else {
          return const LoginScreen(); // Login
        }
      },
     loading: () => const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(), 
        ),
      ),
      error: (_, __) => const MainNavigator(),
    );
  }
}
  