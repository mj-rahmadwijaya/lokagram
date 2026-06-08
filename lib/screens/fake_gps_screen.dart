import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGpsScreen extends StatefulWidget {
  const FakeGpsScreen({super.key});

  @override
  State<FakeGpsScreen> createState() => _FakeGpsScreenState();
}

class _FakeGpsScreenState extends State<FakeGpsScreen> {
  static const _key = 'dev_fake_gps';
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _enabled = prefs.getBool(_key) ?? false;
      _loading = false;
    });
  }

  Future<void> _toggle(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, val);
    if (!mounted) return;
    setState(() => _enabled = val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Fake GPS',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF1A1A2E))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Warning banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFFFD54F), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFF57F17), size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Fitur ini hanya untuk keperluan pengujian. Jangan aktifkan saat absensi nyata.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF57F17),
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Toggle card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    title: const Text(
                      'Simulasi Fake GPS',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text(
                      'Paksa flag isMocked = true saat absensi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _enabled,
                    onChanged: _toggle,
                    activeColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _enabled
                        ? const Color(0xFFFBE9E7)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _enabled
                            ? Icons.gps_off_rounded
                            : Icons.gps_fixed_rounded,
                        color: _enabled
                            ? const Color(0xFFE53935)
                            : const Color(0xFF43A047),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _enabled
                            ? 'Fake GPS AKTIF — check-in akan terdeteksi sebagai lokasi palsu'
                            : 'Fake GPS tidak aktif — menggunakan GPS asli',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _enabled
                              ? const Color(0xFFE53935)
                              : const Color(0xFF43A047),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Penjelasan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cara Uji Anti Fake GPS',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 12),
                      _Step(
                        no: '1',
                        text:
                            'Pastikan store sudah dikonfigurasi di Pengaturan Store',
                      ),
                      _Step(
                        no: '2',
                        text:
                            'Set GPS Mode store ke "Anti Fake" di Pengaturan Store',
                      ),
                      _Step(
                        no: '3',
                        text: 'Aktifkan toggle Simulasi Fake GPS di atas',
                      ),
                      _Step(
                        no: '4',
                        text:
                            'Buka halaman Absensi → tombol Check In harus diblokir',
                      ),
                      _Step(
                        no: '5',
                        text:
                            'Matikan kembali toggle ini setelah selesai uji',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _Step extends StatelessWidget {
  final String no;
  final String text;
  final bool isLast;

  const _Step(
      {required this.no, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(no,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF424242),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}
