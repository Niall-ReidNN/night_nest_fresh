import 'dart:async';
import 'package:flutter/material.dart';

/// Grounding techniques screen — restored cleanly.
/// Reusable scaffold to match ChatScreen's visual style.
class GroundingScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const GroundingScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF071A2B),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF071A2B),
                      Color(0xFF003A3F),
                      Color(0xFF002E4D),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class GroundingScreen extends StatelessWidget {
  const GroundingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_Technique>[
      _Technique('Box Breathing', Icons.air, const BoxBreathingScreen()),
      _Technique(
        '5-4-3-2-1',
        Icons.filter_5,
        const FiveFourThreeTwoOneScreen(),
      ),
      _Technique('Affirmations', Icons.favorite, const AffirmationsScreen()),
      _Technique(
        'Progressive Muscle',
        Icons.fitness_center,
        const ProgressiveMuscleScreen(),
      ),
      _Technique('Body Scan', Icons.self_improvement, const BodyScanScreen()),
      _Technique(
        'Guided Imagery',
        Icons.landscape,
        const GuidedImageryScreen(),
      ),
      _Technique(
        'Gentle Movement',
        Icons.directions_walk,
        const GentleMovementScreen(),
      ),
    ];

    return GroundingScaffold(
      title: 'Grounding Techniques',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on screen width
          int crossAxisCount;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 1; // Mobile
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 2; // Tablet
          } else {
            crossAxisCount = 3; // Web/Large screen
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final t = items[index];
              return Card(
                margin: EdgeInsets.zero,
                color: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => t.screen),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E6A8).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            t.icon,
                            color: const Color(0xFF00E6A8),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.5),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Technique {
  final String title;
  final IconData icon;
  final Widget screen;
  const _Technique(this.title, this.icon, this.screen);
}

class BoxBreathingScreen extends StatefulWidget {
  const BoxBreathingScreen({super.key});
  @override
  State<BoxBreathingScreen> createState() => _BoxBreathingScreenState();
}

class _BoxBreathingScreenState extends State<BoxBreathingScreen> {
  Timer? _timer;
  int _count = 4;
  int _phase = 0;
  bool _running = false;

  final _names = ['Breathe In', 'Hold', 'Breathe Out', 'Hold'];

  void _start() {
    if (_running) return;
    setState(() {
      _running = true;
      _count = 4;
      _phase = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _count--;
        if (_count <= 0) {
          _phase = (_phase + 1) % 4;
          _count = 4;
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Box Breathing',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _names[_phase],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00E6A8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E6A8).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$_count',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00E6A8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _running ? _stop : _start,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E6A8),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _running ? 'Stop' : 'Start',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FiveFourThreeTwoOneScreen extends StatelessWidget {
  const FiveFourThreeTwoOneScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: '5-4-3-2-1',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Notice 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AffirmationsScreen extends StatelessWidget {
  const AffirmationsScreen({super.key});
  static const _affirmations = [
    'You are doing your best — that is enough.',
    'You are allowed to rest and recover.',
    'This feeling will pass; you are not alone.',
    'You are worthy of love and compassion, especially from yourself.',
    'Your struggles do not define your worth.',
    'It is okay to ask for help and take breaks.',
    'You are stronger than you believe.',
    'Progress, not perfection, is the goal.',
    'You deserve peace and happiness.',
    'Every day is a new opportunity to be kind to yourself.',
    'Your feelings are valid and important.',
    'You are capable of handling this moment.',
  ];
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Affirmations',
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: _affirmations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.favorite, color: const Color(0xFF00E6A8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _affirmations[i],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
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

class ProgressiveMuscleScreen extends StatelessWidget {
  const ProgressiveMuscleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Progressive Muscle Relaxation',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Tense and release muscle groups from toes to head.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BodyScanScreen extends StatelessWidget {
  const BodyScanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Body Scan',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Bring gentle attention to each part of your body, head to toes.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GuidedImageryScreen extends StatelessWidget {
  const GuidedImageryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Guided Imagery',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Imagine a calm, safe place — notice details, colours, sounds, and textures.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GentleMovementScreen extends StatelessWidget {
  const GentleMovementScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Gentle Movement',
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Card(
              margin: EdgeInsets.zero,
              color: Colors.white.withOpacity(0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Try slow neck rolls, shoulder shrugs, and ankle circles with mindful breathing.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
