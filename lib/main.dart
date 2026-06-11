import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'services/stream_proxy.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StreamProxy.start();
  WakelockPlus.enable();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF111111),
  ));
  runApp(const DemonTvPlusApp());
}

class DemonTvPlusApp extends StatelessWidget {
  const DemonTvPlusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DemonTv Plus',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.darkTheme,
    initialRoute: '/',
    onGenerateRoute: (settings) {
      Widget page;
      switch (settings.name) {
        case '/login':   page = const LoginScreen(); break;
        case '/profile': page = const ProfileScreen(); break;
        case '/main':    page = const MainScreen(); break;
        default:         page = const SplashScreen();
      }
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );
    },
  );
}
