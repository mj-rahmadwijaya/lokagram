import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _sandiCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _sandiCtrl.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    final email = _emailCtrl.text.trim();
    final sandi = _sandiCtrl.text.trim();

    if (email.isEmpty || sandi.isEmpty) {
      ShadToaster.of(context).show(const ShadToast.destructive(
          description: Text('Email dan sandi tidak boleh kosong')));
      return;
    }

    // Dummy credentials untuk testing
    const _dummyUser = 'test';
    const _dummyPass = '123456';
    final isDummy = email == _dummyUser && sandi == _dummyPass;

    if (!isDummy && !email.contains('@')) {
      ShadToaster.of(context).show(const ShadToast.destructive(
          description: Text('Format email tidak valid')));
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));

    final String name;
    final String savedEmail;
    if (isDummy) {
      name = 'Test';
      savedEmail = 'test@grandepos.io';
    } else {
      // Nama dari email (sebelum @)
      final raw = email.split('@')[0].replaceAll(RegExp(r'[._]'), ' ');
      name = raw
          .split(' ')
          .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
      savedEmail = email;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', savedEmail);
    await prefs.setString('employee_name', name);

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const MainScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  void _belumTersedia() {
    ShadToaster.of(context).show(
        const ShadToast(description: Text('Fitur belum tersedia')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              // Ikon kecil
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: Color(0xFF1976D2), size: 28),
              ),
              const SizedBox(height: 24),
              const Text(
                'Selamat Datang',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 6),
              Text('Presensi menjadi mudah!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 36),

              // Email
              const Text('Email',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ShadInput(
                controller: _emailCtrl,
                placeholder: const Text('Masukkan email'),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.email_outlined,
                      size: 18, color: Colors.grey),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Sandi
              const Text('Sandi',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ShadInput(
                controller: _sandiCtrl,
                placeholder: const Text('Masukkan sandi'),
                leading: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.lock_outline,
                      size: 18, color: Colors.grey),
                ),
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                ),
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _masuk(),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _belumTersedia,
                  child: const Text('Lupa kata sandi?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Masuk
              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: _loading ? null : _masuk,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Masuk'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
