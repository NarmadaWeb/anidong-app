// lib/main.dart

import 'package:anidong/providers/home_provider.dart';
import 'package:anidong/providers/local_data_provider.dart';
import 'package:anidong/providers/theme_provider.dart';
import 'package:anidong/providers/trending_provider.dart';
import 'package:anidong/screens/splash_screen.dart';
import 'package:anidong/services/ad_service.dart';
import 'package:anidong/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdService.instance.initialize();
  AdService.instance.loadRewardedAd();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => TrendingProvider()),
        ChangeNotifierProvider(create: (_) => LocalDataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AniDong',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
