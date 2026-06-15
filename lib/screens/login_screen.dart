import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/session.dart';
import '../models/store.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import '../services/store_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_scaffold.dart';
import 'main_screen.dart';
import 'store_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  final _apiService = ApiService();
  final _sessionService = SessionService();
  final _storeService = StoreService();

  Store? _store;
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStore() async {
    final store = await _storeService.loadStore();
    if (mounted) setState(() => _store = store);
  }

  Future<void> _openStoreSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreSettingsScreen(initialStore: _store),
      ),
    );
    _loadStore();
  }

  Future<void> _login() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      _showToast('PIN tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final deviceId = await _sessionService.getDeviceId();
      final response = await _apiService.login(
        pin: pin,
        uniqueIdDevice: deviceId,
        timestamp: DateTime.now(),
      );

      if (!mounted) return;

      if (!response.success) {
        _showToast(response.message, isError: true);
        return;
      }

      final existingSession = await _sessionService.loadSession();
      final newSession = _buildSession(response, deviceId);

      if (existingSession == null) {
        await _confirmSaveSession(
          title: 'Simpan data ke device?',
          body: 'Data karyawan dan outlet akan disimpan di device ini.',
          session: newSession,
        );
      } else {
        final cocok = existingSession.staffId == response.karyawan!.staffId &&
            existingSession.outletId == response.karyawan!.outletId &&
            existingSession.uniqueId == response.karyawan!.uniqueId;

        if (cocok) {
          await _confirmSaveSession(
            title: 'Data cocok, lanjutkan?',
            body: 'Login sebagai ${newSession.employeeName} di ${newSession.outletName}.',
            session: newSession,
          );
        } else {
          if (!mounted) return;
          _showAlert(
            title: 'Data Tidak Cocok',
            body: 'Data dari server tidak cocok dengan data device ini. Hubungi admin.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Session _buildSession(LoginResponse response, String deviceId) {
    final outlet = response.outlet!;
    final karyawan = response.karyawan!;
    return Session(
      token: response.token!,
      staffId: karyawan.staffId,
      outletId: karyawan.outletId,
      uniqueId: karyawan.uniqueId,
      employeeName: 'Budi Santoso',
      phone: '-',
      outletName: outlet.name,
      outletAddress: outlet.alamat,
      outletLat: outlet.lat,
      outletLng: outlet.lng,
      logoUrl: response.logoUrl,
    );
  }

  Future<void> _confirmSaveSession({
    required String title,
    required String body,
    required Session session,
  }) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok != true) return;

    await _sessionService.saveSession(session);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, a, b) => const MainScreen(),
      transitionsBuilder: (context, anim, b, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  void _showAlert({required String title, required String body}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        surfaceTintColor: Colors.white,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    if (isError) {
      ShadToaster.of(context).show(ShadToast.destructive(
          description: Text(msg)));
    } else {
      ShadToaster.of(context).show(ShadToast(description: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Bagian atas: ikon & judul di atas gradient ---
              const SizedBox(height: 56),
              GlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 18,
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.textOnGrad,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Masukkan PIN',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnGrad,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gunakan PIN yang diberikan oleh admin.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSubOnGrad,
                ),
              ),
              const SizedBox(height: 32),

              // --- Form card melayang ---
              GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner info outlet
                    if (_store != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x26FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0x4DFFFFFF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.store_rounded,
                                size: 16, color: AppColors.textOnGrad),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _store!.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textOnGrad,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _openStoreSettings,
                              child: const Text(
                                'Ubah Outlet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSubOnGrad,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Label PIN
                    const Text(
                      'PIN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnGrad,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Input PIN
                    ShadInput(
                      controller: _pinCtrl,
                      placeholder: const Text('Masukkan PIN'),
                      leading: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.dialpad_rounded,
                            size: 18, color: Colors.grey),
                      ),
                      trailing: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _login(),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      child: GradientButton(
                        onPressed: _loading ? null : _login,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnGrad,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              // Teks dummy
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'PIN: 1234  (dummy)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSubOnGrad,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
