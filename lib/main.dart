import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    routes: {
      '/':        (_) => const SplashScreen(),
      '/login':   (_) => const LoginScreen(),
      '/profile': (_) => const ProfileScreen(),
      '/main':    (_) => const MainScreen(),
    },
  );
}
