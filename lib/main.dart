import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/progression_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/tutorial_provider.dart';
import 'providers/inapp_provider.dart';
import 'widgets/spotlight_overlay.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/email_verify_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/welly_welcome_screen.dart';
import 'screens/growth/growth_screen.dart';
import 'widgets/bw_scaffold.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  // I reminder periodici vengono pianificati da SettingsProvider.init() e
  // LocaleProvider.init() (rescheduleBwReminders in app_localizations.dart),
  // in base a lingua, frequenza scelta e pausa attiva.

  // AdMob — inizializzazione prima di runApp
  await MobileAds.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()..init()),
        ChangeNotifierProvider(create: (_) => ProgressionProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()..init()),
        ChangeNotifierProvider(create: (_) => TutorialProvider()..init()),
        ChangeNotifierProvider(create: (_) => InAppProvider()..init()),
        ChangeNotifierProvider(create: (_) => SpotlightController()),
      ],
      child: const BewellApp(),
    ),
  );
}

class BewellApp extends StatelessWidget {
  const BewellApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ascolta sia SettingsProvider che ThemeProvider per ricostruire il tema
    return Consumer2<SettingsProvider, ThemeProvider>(
      builder: (context, settings, theme, _) {
        return MaterialApp(
          title: 'Be Well',
          // Il MaterialTheme viene generato dalla palette attiva
          theme: theme.buildMaterialTheme(
            largeText: settings.largeText,
            highContrast: settings.highContrast,
          ),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Consumer<ThemeProvider>(
              builder: (context, theme, _) {
                if (!theme.isAmbient) return child ?? const SizedBox();
                return Stack(
                  children: [
                    Positioned(
                      top: 0, left: 0, right: 0, height: 100,
                      child: CustomPaint(
                        painter: HorizonPainter(
                          dark: theme.paletteData.isDark,
                          bgColor: theme.paletteData.bg,
                        ),
                      ),
                    ),
                    child ?? const SizedBox(),
                  ],
                );
              },
            );
          },
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
      case '/welly-welcome':
        return _fadeRoute(const WellyWelcomeScreen());
      case '/growth':
        return _fadeRoute(const GrowthScreen());
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







