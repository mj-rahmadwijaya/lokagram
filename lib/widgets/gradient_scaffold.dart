import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Scaffold dengan latar gradient penuh layar.
///
/// Membungkus [Scaffold] standar di dalam [Container] bergradient
/// sehingga semua layar bisa langsung mendapatkan latar gradient
/// tanpa mengulang dekorasi yang sama.
class GradientScaffold extends StatelessWidget {
  /// Konten utama layar.
  final Widget body;

  /// AppBar opsional. Otomatis transparan agar gradient terlihat di baliknya.
  final PreferredSizeWidget? appBar;

  /// Widget navigasi bawah opsional.
  final Widget? bottomNavigationBar;

  /// FAB opsional.
  final Widget? floatingActionButton;

  /// Apakah body meluas ke balik AppBar. Default: true.
  final bool extendBodyBehindAppBar;

  /// Gradient latar. Default: [AppGradients.primary].
  final Gradient? gradient;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.primary,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
