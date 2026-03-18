import 'dart:async';
import 'package:flutter/material.dart';
import '../customers/customer_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerListScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85, // büyüklük ayarı (0.75-0.9 arası deneyebiliriz)
          child: Image.asset(
            'assets/splash.png',
            fit: BoxFit.contain, // kırpma yapmaz, logonun tamamı görünür
          ),
        ),
      ),
    );
  }
}
