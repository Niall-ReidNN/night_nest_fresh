import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late String _greeting;

  @override
  void initState() {
    super.initState();

    // Determine greeting based on time of day
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = 'Good Morning ☀️';
    } else if (hour >= 12 && hour < 17) {
      _greeting = 'Good Afternoon 🌤️';
    } else if (hour >= 17 && hour < 21) {
      _greeting = 'Good Evening 🌅';
    } else {
      _greeting = 'Good Night 🌙';
    }

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Wait 4 seconds, then fade out over 1 second and navigate to affirmation screen
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      _fadeController.reverse(from: 1.0).then((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/affirmation');
      });
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
      backgroundColor: const Color(0xFF003A3F),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.85,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white.withAlpha((0.8 * 255).toInt()),
                    BlendMode.modulate,
                  ),
                  child: Image.asset(
                    'assets/images/night_nest_logo.png',
                    width: 250,
                    height: 250,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
