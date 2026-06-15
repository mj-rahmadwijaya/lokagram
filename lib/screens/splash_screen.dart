import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../services/session_service.dart';
import '../services/store_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'store_settings_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;

    final store = await StoreService().loadStore();
    if (!mounted) return;

    if (store == null) {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (context, a, b) =>
            const StoreSettingsScreen(isInitialSetup: true),
        transitionsBuilder: (context, anim, b, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ));
      return;
    }

    final session = await SessionService().loadSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, a, b) =>
          session != null ? const MainScreen() : const LoginScreen(),
      transitionsBuilder: (context, anim, b, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/logo.png',
                  width: 220,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Presensi, izin dan cuti',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == 0 ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFBBDEFB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
