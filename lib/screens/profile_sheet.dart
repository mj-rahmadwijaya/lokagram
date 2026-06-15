import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class ProfileSheet extends StatefulWidget {
  final Session session;
  const ProfileSheet({super.key, required this.session});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  ProfileResponse? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile =
        await ApiService().getProfile(token: widget.session.token);
    if (mounted) setState(() { _profile = profile; _loading = false; });
  }

  String get _initials {
    final name = _profile?.nama ?? widget.session.employeeName;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final outletName = _profile?.outletName ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── BAGIAN ATAS: header gradient ─────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Tombol Back
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded,
                            size: 16, color: AppColors.textSubOnGrad),
                        SizedBox(width: 4),
                        Text('Back',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSubOnGrad,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.glassBorder, width: 2),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textOnGrad)
                      : Text(
                          _initials,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnGrad),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Nama karyawan
              Text(
                _profile?.nama ?? widget.session.employeeName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnGrad),
              ),
              if (outletName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    outletName,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSubOnGrad),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // ── BAGIAN BAWAH: konten info ─────────────────────────────────────
        Container(
          color: const Color(0xFFF0F4FF),
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad + 24),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSection(
                      title: 'Informasi Karyawan',
                      rows: [
                        _InfoRow(label: 'Nama', value: _profile?.nama ?? '-'),
                        _InfoRow(
                            label: 'Phone', value: _profile?.phone ?? '-'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: 'Informasi Store',
                      rows: [
                        _InfoRow(
                            label: 'Outlet ID',
                            value: _profile?.outletId ?? '-'),
                        _InfoRow(
                            label: 'Name',
                            value: _profile?.outletName ?? '-'),
                        _InfoRow(
                            label: 'Alamat', value: _profile?.alamat ?? '-'),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5)),
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }
}
