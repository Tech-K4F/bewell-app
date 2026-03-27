import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/onboarding_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/email_verify_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';
import 'services/notification_service.dart';

// NOTA: quando hai completato il setup Firebase (Blocco 2 e 3 della guida),
// aggiungi questi due import e decommentali:
//
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTA: quando hai firebase_options.dart, sostituisci con:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: const BewellApp(),
    ),
  );
}

class BewellApp extends StatelessWidget {
  const BewellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Be Well',
          theme: AppTheme.build(
            highContrast: settings.highContrast,
            largeText: settings.largeText,
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return _fadeRoute(const SplashScreen());
      case '/login':
        return _slideRoute(const LoginScreen());
      case '/register':
        return _slideRoute(const RegisterScreen());
      case '/email-verify':
        final email = settings.arguments as String? ?? '';
        return _slideRoute(EmailVerifyScreen(email: email));
      case '/forgot-password':
        return _slideRoute(const ForgotPasswordScreen());
      case '/onboarding':
        return _fadeRoute(const OnboardingScreen());
      case '/home':
        return _fadeRoute(const HomeShell());
      default:
        return _fadeRoute(const HomeShell());
    }
  }

  static PageRoute _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRoute _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offset, child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}

