import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..init(),
      child: const BewellApp(),
    ),
  );
}

class BewellApp extends StatelessWidget {
  const BewellApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be Well',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, p, _) {
        if (p.isLoading) return const SplashScreen();
        if (!p.isOnboarded) return const OnboardingScreen();
        return const HomeShell();
      },
    );
  }
}
