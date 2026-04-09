import 'dart:async';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../customers/customer_list_screen.dart';
import '../../core/database/database_helper.dart';

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
    final lastCustomer = await _checkLastCall();

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerListScreen(autoOpenCustomer: lastCustomer),
      ),
    );
  }

  Future<Map<String, dynamic>?> _checkLastCall() async {
    var status = await Permission.phone.request();
    if (!status.isGranted) return null;

    Iterable<CallLogEntry> entries = await CallLog.get();
    if (entries.isEmpty) return null;

    final lastCall = entries.first;
    final number = lastCall.number;

    if (number == null || number.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final lastSaved = prefs.getString("last_checked_number");

    // aynı numarayı tekrar açma
    if (lastSaved == number) return null;

    await prefs.setString("last_checked_number", number);

    final results = await DatabaseHelper.instance.searchCustomerByPhone(number);

    if (results.isNotEmpty) {
      return results.first;
    } else {
      return {"new_number": number};
    }
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
