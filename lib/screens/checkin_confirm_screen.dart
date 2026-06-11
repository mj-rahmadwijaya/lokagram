import 'package:flutter/material.dart';
import '../models/session.dart';

class CheckinConfirmScreen extends StatelessWidget {
  final Session session;
  const CheckinConfirmScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('CheckinConfirmScreen — TODO')),
    );
  }
}
