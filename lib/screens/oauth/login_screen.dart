// lib/screens/oauth/login_screen.dart

import 'package:anidong/providers/auth_provider.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:provider/provider.dart';

// --- TAMBAHKAN IMPORT INI ---
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
// ----------------------------

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // Google Sign-In hanya didukung di platform mobile (Android & iOS)
    bool isSignInSupported = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    // ----------------------------------------------------

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau ilustrasi
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome to AniDong',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to discover your favorite anime and donghua.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 48),

              if (isSignInSupported)
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.state == AuthState.authenticating) {
                      return const CircularProgressIndicator(color: AppColors.accent);
                    }
                    return ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.signInWithGoogle();
                      },
                      icon: const Icon(Boxicons.bxl_google, size: 24),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Google Sign-In hanya didukung di Android dan iOS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              // ---------------------------------------------

              if (Provider.of<AuthProvider>(context).errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Error: ${Provider.of<AuthProvider>(context).errorMessage}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
