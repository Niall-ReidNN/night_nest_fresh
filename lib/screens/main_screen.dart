import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _otherUsers = 0;
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _startSimulated();
  }

  void _startSimulated() {
    final rnd = Random();
    _simTimer?.cancel();
    // Simulate 0..5 other users updating every 5 seconds
    _simTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final simulated = rnd.nextInt(6);
      if (mounted) setState(() => _otherUsers = simulated);
    });
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF003A3F),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/night_nest_logo.png',
                      width: 220,
                      height: 220,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _otherUsers > 0
                          ? 'There are $_otherUsers other parents online looking for support'
                          : 'Other parents are looking for support - connect in chat',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.self_improvement),
                          label: const Text('Grounding'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/grounding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E6A8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.book_outlined),
                          label: const Text('Journal'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/journal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5EE2D7),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.insights_outlined),
                          label: const Text('Mood Tracker'),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/mood'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB347),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF003A3F),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  launchUrl(
                    Uri(scheme: 'mailto', path: 'hello@thenightnest.co.uk'),
                  );
                },
                child: Text(
                  'Contact: hello@thenightnest.co.uk',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feedback dialog and EmailJS integration removed as requested.
}
