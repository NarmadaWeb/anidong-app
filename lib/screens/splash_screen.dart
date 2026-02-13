// lib/screens/splash_screen.dart

import 'package:anidong/data/services/config_service.dart';
import 'package:anidong/data/services/notification_service.dart';
import 'package:anidong/screens/main_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSecurityAndNetwork();
  }

  Future<void> _checkSecurityAndNetwork() async {
    // 1. Root Detection
    bool isJailbroken = false;
    try {
      isJailbroken = await SafeDevice.isJailBroken;
    } catch (e) {
      debugPrint("Error checking jailbreak status: $e");
    }

    if (isJailbroken && mounted) {
      _showErrorDialog(
        title: 'Security Alert',
        message:
            'Perangkat Anda terdeteksi di-root. Aplikasi tidak dapat dijalankan demi keamanan.',
        buttonText: 'Exit',
        onPressed: () => SystemNavigator.pop(),
      );
      return;
    }

    // 2. Internet Connection Check
    await _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    bool hasConnection = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      hasConnection = !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint("Error checking internet connection: $e");
      // Fallback to assuming connection if check fails, to avoid blocking user
      hasConnection = true;
    }

    if (!hasConnection && mounted) {
      _showErrorDialog(
        title: 'No Internet Connection',
        message:
            'Aplikasi membutuhkan koneksi internet. Silakan aktifkan data atau Wi-Fi Anda.',
        buttonText: 'Exit',
        onPressed: () => SystemNavigator.pop(),
        secondaryButtonText: 'Retry',
        onSecondaryPressed: () {
          Navigator.of(context).pop(); // Close dialog
          _checkSecurityAndNetwork(); // Retry checks
        },
      );
      return;
    }

    // If all checks pass
    if (mounted) {
       await _initNotifications();
      _navigateToHome();
    }
  }

  Future<void> _initNotifications() async {
      try {
        final notificationService = NotificationService();
        await notificationService.init();
        await notificationService.scheduleDailySilentNotifications();
      } catch (e) {
        debugPrint("Error initializing notifications: $e");
      }
  }

  void _showErrorDialog({
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (secondaryButtonText != null && onSecondaryPressed != null)
              TextButton(
                onPressed: onSecondaryPressed,
                child: Text(secondaryButtonText),
              ),
            TextButton(
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToHome() async {
    // Fetch configuration and wait for minimum splash duration in parallel
    final minSplashTime = Future.delayed(const Duration(milliseconds: 3000));
    final configFetch = ConfigService().fetchApiConfig();

    await Future.wait([minSplashTime, configFetch]);

    // Pindah ke halaman utama dan hapus splash screen dari tumpukan navigasi
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.movie_filter_rounded,
                  size: 150,
                  color: AppColors.accent,
                );
              },
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
