import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'profile_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  final _sessionService = SessionService();

  Session? _session;
  List<AbsensiItem> _items = [];
  bool _loading = true;
  bool _checkingOut = false;

  static const _namaHari = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  static const _namaBulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final session = await _sessionService.loadSession();
    if (!mounted) return;
    if (session == null) {
      setState(() => _loading = false);
      return;
    }
    final items = await _apiService.getAbsensiList(token: session.token);
    if (!mounted) return;
    setState(() {
      _session = session;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _checkout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Checkout'),
        content: const Text('Pastikan Anda sudah selesai bekerja hari ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Checkout',
                style: TextStyle(color: Color(0xFFFF9800))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _checkingOut = true);
    try {
      final session = _session;
      if (session != null) {
        final res = await _apiService.checkout(token: session.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message),
          backgroundColor: const Color(0xFF43A047),
        ));
      }
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _openProfile() {
    final session = _session;
    if (session == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileSheet(session: session),
    );
  }

  String _formatTanggal(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    return '${_namaHari[dt.weekday % 7]}, $d ${_namaBulan[dt.month]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _items.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _AbsensiCard(
                              item: _items[i],
                              tanggal: _formatTanggal(_items[i].tanggal),
                            ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCheckoutBar(),
    );
  }

  Widget _buildHeader() {
    final session = _session;
    return Container(
      color: const Color(0xFF1976D2),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo, ${session?.employeeName ?? ''}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  session?.outletName ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFFBBDEFB)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: Center(
                child: Text(
                  _initials(session?.employeeName ?? ''),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _checkingOut ? null : _checkout,
          icon: _checkingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.logout_rounded, size: 20),
          label: Text(_checkingOut ? 'Memproses...' : 'Checkout',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Belum ada riwayat absensi',
              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

class _AbsensiCard extends StatelessWidget {
  final AbsensiItem item;
  final String tanggal;

  const _AbsensiCard({required this.item, required this.tanggal});

  @override
  Widget build(BuildContext context) {
    final hadir = item.status == 'hadir';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hadir
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hadir ? Icons.check_rounded : Icons.close_rounded,
              color: hadir
                  ? const Color(0xFF43A047)
                  : const Color(0xFFE53935),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tanggal,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E))),
                if (hadir) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.jam,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hadir
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hadir ? 'Hadir' : 'Absen',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hadir
                      ? const Color(0xFF43A047)
                      : const Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}
