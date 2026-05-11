import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsecureDeviceScreen extends StatelessWidget {
  const InsecureDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security_rounded,
                  color: Colors.redAccent,
                  size: 80,
                ),
                const SizedBox(height: 32),
                Text(
                  "SECURITY ALERT",
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Vowl cannot run on rooted or jailbroken devices to protect the game economy and user data integrity.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  "Please use a standard device to continue your adventure.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
