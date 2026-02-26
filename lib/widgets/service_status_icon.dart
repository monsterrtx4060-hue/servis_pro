import 'package:flutter/material.dart';

class ServiceStatusIcon extends StatelessWidget {
  final String? status;

  const ServiceStatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = (status ?? '').toString().trim();

    if (s == 'Tamamlandı') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (s == 'İptal') {
      return const Icon(Icons.cancel, color: Colors.red);
    }
    if (s == 'Parça Bekliyor') {
      return const Icon(Icons.access_time, color: Colors.orange);
    }

    return const SizedBox.shrink();
  }
}
