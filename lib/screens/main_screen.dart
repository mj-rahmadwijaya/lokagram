import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'tabs/home_tab.dart';
import 'tabs/absensi_tab.dart';
import 'tabs/riwayat_tab.dart';
import 'tabs/profil_tab.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;
  final _absensiKey = GlobalKey<AbsensiTabState>();
  final _riwayatKey = GlobalKey<RiwayatTabState>();
  StreamSubscription<ServiceStatus>? _gpsSub;
  bool _gpsDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _gpsSub = Geolocator.getServiceStatusStream().listen(_onGpsStatusChange);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  void _onGpsStatusChange(ServiceStatus status) {
    if (status == ServiceStatus.disabled && mounted && !_gpsDialogShowing) {
      _showGpsOffDialog();
    } else if (status == ServiceStatus.enabled && mounted && _gpsDialogShowing) {
      Navigator.of(context).pop();
      _gpsDialogShowing = false;
    }
  }

  void _showGpsOffDialog() {
    _gpsDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          contentPadding:
              const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBE9E7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded,
                    size: 36, color: Color(0xFFE53935)),
              ),
              const SizedBox(height: 16),
              const Text(
                'GPS Dimatikan',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Aplikasi membutuhkan GPS untuk mencatat kehadiran. Aktifkan kembali lokasi Anda.',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _gpsDialogShowing = false;
                    await Geolocator.openLocationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Aktifkan GPS',
                      style: TextStyle(
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _gpsDialogShowing = false);
  }

  void _goTo(int i) {
    setState(() => _index = i);
    if (i == 1) _absensiKey.currentState?.refresh();
    if (i == 2) _riwayatKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeTab(onAbsensi: () => _goTo(1), onRiwayat: () => _goTo(2)),
          AbsensiTab(key: _absensiKey, onRiwayat: () => _goTo(2)),
          RiwayatTab(key: _riwayatKey),
          ProfilTab(onLogout: () {}),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(Icons.fingerprint),
            label: 'Absensi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
