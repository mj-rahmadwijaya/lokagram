import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onAbsensi;
  final VoidCallback onRiwayat;
  const HomeTab({super.key, required this.onAbsensi, required this.onRiwayat});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _service = AttendanceService();
  String _nama = '';
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  static const _bulan = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  static const _hari = [
    'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _service.loadRecords();
    if (!mounted) return;
    setState(() {
      _nama = prefs.getString('employee_name') ?? 'Karyawan';
      _records = records.reversed.toList();
      _loading = false;
    });
  }

  List<AttendanceRecord> get _bulanIni {
    final now = DateTime.now();
    return _records
        .where((r) =>
            r.timestamp.month == now.month && r.timestamp.year == now.year)
        .toList();
  }

  int get _hadirCount => _bulanIni.length;
  int get _luarZonaCount => _bulanIni.where((r) => !r.isInsideZone).length;

  String _formatTanggal(DateTime dt) {
    return '${_hari[dt.weekday % 7]}, ${dt.day} ${_bulan[dt.month]} ${dt.year}';
  }

  String _formatWaktu(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tanggalHari =
        '${_hari[now.weekday % 7]}, ${now.day} ${_bulan[now.month]} ${now.year}';
    final firstName = _nama.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // Header biru
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(28)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Halo, $firstName ',
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        const Text('🙋',
                                            style:
                                                TextStyle(fontSize: 20)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tanggalHari,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFBBDEFB)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stat cards
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Hadir',
                                  value: '$_hadirCount Hari',
                                  icon: Icons.check_circle_outline,
                                  color: const Color(0xFF43A047),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Luar Zona',
                                  value: '$_luarZonaCount Hari',
                                  icon: Icons.location_off_outlined,
                                  color: const Color(0xFFFF7043),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Bulan',
                                  value: _bulan[now.month],
                                  icon: Icons.calendar_month_outlined,
                                  color: const Color(0xFF9C27B0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Tombol Absensi cepat
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: widget.onAbsensi,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fingerprint,
                                    color: Color(0xFF43A047), size: 28),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Absensi Sekarang',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text('Tap untuk check in',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // Judul Absensi Terbaru
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Absensi Terbaru',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E))),
                          GestureDetector(
                            onTap: widget.onRiwayat,
                            child: const Text('Lihat Semua',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1976D2),
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                  // List
                  _records.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined,
                                      size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('Belum ada absensi',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              if (i >= _records.length && i > 4) return null;
                              final r = _records[i];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 10),
                                child: _RecordItem(
                                  record: r,
                                  tanggal: _formatTanggal(r.timestamp),
                                  waktu: _formatWaktu(r.timestamp),
                                ),
                              );
                            },
                            childCount:
                                _records.length > 5 ? 5 : _records.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBBDEFB))),
        ],
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final AttendanceRecord record;
  final String tanggal;
  final String waktu;

  const _RecordItem({
    required this.record,
    required this.tanggal,
    required this.waktu,
  });

  @override
  Widget build(BuildContext context) {
    final inZone = record.isInsideZone;
    return Container(
      padding: const EdgeInsets.all(14),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: inZone
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFBE9E7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              inZone ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: inZone
                  ? const Color(0xFF43A047)
                  : const Color(0xFFFF7043),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tanggal,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(record.gpsMode.label,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(waktu,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: inZone
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inZone ? 'Dalam Zona' : 'Luar Zona',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: inZone
                          ? const Color(0xFF43A047)
                          : const Color(0xFFFF7043)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
