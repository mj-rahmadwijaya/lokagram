import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
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
