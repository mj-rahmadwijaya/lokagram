import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'main_screen.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          loggedIn ? const MainScreen() : const LoginScreen(),
      transitionsBuilder: (_, anim, __, child) =>
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
                child: _buildIcon(),
              ),
              const SizedBox(height: 36),
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
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

  Widget _buildIcon() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lingkaran background besar
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
          ),
          // Kotak ikon utama
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.event_available_rounded,
                size: 48, color: Colors.white),
          ),
          // Dot hijau kanan atas
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                  color: Color(0xFF43A047), shape: BoxShape.circle),
            ),
          ),
          // Dot biru kecil kiri bawah
          Positioned(
            bottom: 18,
            left: 10,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  color: Color(0xFF90CAF9), shape: BoxShape.circle),
            ),
          ),
          // Dot oranye kanan bawah
          Positioned(
            bottom: 10,
            right: 20,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  color: Color(0xFFFFB74D), shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
