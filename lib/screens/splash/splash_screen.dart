import 'dart:async';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';

import '../customers/customer_list_screen.dart';
import '../../core/database/database_helper.dart';
import '../customers/customer_detail_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final lastNumber = await _getLastCallNumber();

    if (lastNumber != null && lastNumber.isNotEmpty) {
      final results = await DatabaseHelper.instance.searchCustomerByPhone(
        lastNumber,
      );

      if (results.isNotEmpty) {
        final customer = results.first;

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customerId: customer['id'],
              customerName: customer['name'],
            ),
          ),
        );
        return;
      }
    }

    // müşteri bulunamazsa normal liste açılır
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CustomerListScreen()),
    );
  }

  Future<String?> _getLastCallNumber() async {
    try {
      Iterable<CallLogEntry> entries = await CallLog.get();

      if (entries.isNotEmpty) {
        final number = entries.first.number;
        return number;
      }
    } catch (e) {
      // izin yoksa buraya düşer
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: Image.asset('assets/splash.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
