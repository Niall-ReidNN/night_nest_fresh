import 'dart:math';
import 'package:flutter/material.dart';

class AffirmationScreen extends StatefulWidget {
  const AffirmationScreen({super.key});

  @override
  State<AffirmationScreen> createState() => _AffirmationScreenState();
}

class _AffirmationScreenState extends State<AffirmationScreen>
    with SingleTickerProviderStateMixin {
  final List<String> affirmations = const [
    "You are doing better than you think 💛",
    "Your feelings are valid 🌙",
    "You deserve rest and peace 🕊️",
    "Even small steps matter 🐾",
    "You are not alone 🤝",
    "You are enough 💖",
  ];

  late String affirmation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final random = Random();
    affirmation = affirmations[random.nextInt(affirmations.length)];

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Stay visible for 4 seconds, then fade out over 1 second
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        _fadeController.reverse(from: 1.0).then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/consent');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF5EE2D7).withOpacity(0.1),
                        const Color(0xFF00E6A8).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5EE2D7).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    affirmation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Take a moment to breathe',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
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
