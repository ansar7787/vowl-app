import 'package:flutter/material.dart';

/// Static security alert screen shown when the app detects a rooted or
/// jailbroken device. Intentionally wraps its own [MaterialApp] because it
/// may be displayed before the main application [MaterialApp] is mounted
/// (e.g., from `main.dart` as a root replacement).
///
/// Uses absolute sizes throughout — [ScreenUtil] and [Localizations] are
/// not guaranteed to be available at this early render stage.
class InsecureDeviceScreen extends StatelessWidget {
  const InsecureDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Semantics(
          liveRegion: true,
          label: 'Security alert: this device is not supported',
          child: RepaintBoundary(
            // FIX (RESPONSIVENESS/ACCESSIBILITY): a fixed Column centered
            // directly in the viewport overflows at large accessibility
            // text-scale factors (up to 3.0x) on small devices (320x568),
            // since this early-boot screen renders before ScreenUtil /
            // Localizations are guaranteed available and can't rely on
            // responsive sizing helpers. SingleChildScrollView +
            // ConstrainedBox(minHeight: viewport) preserves the exact
            // current centered appearance when content fits, and only
            // scrolls (instead of clipping/overflowing) when it doesn't.
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 64.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security_rounded,
                          color: Colors.redAccent,
                          size: 80,
                          semanticLabel: 'Security warning',
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'SECURITY ALERT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vowl cannot run on rooted or jailbroken devices'
                          ' to protect the game economy and user data integrity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Please use a standard device to continue'
                          ' your adventure.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14,
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
