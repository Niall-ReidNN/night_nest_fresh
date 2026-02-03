import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AmbientSoundsScreen extends StatefulWidget {
  const AmbientSoundsScreen({super.key});

  @override
  State<AmbientSoundsScreen> createState() => _AmbientSoundsScreenState();
}

class _AmbientSoundsScreenState extends State<AmbientSoundsScreen> {
  late AudioPlayer _audioPlayer;
  String? _playingSound;
  double _volume = 0.7;
  bool _isPlaying = false;

  final List<_AmbientSound> _sounds = [
    _AmbientSound(
      name: 'Rain',
      icon: Icons.cloud_download,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      emoji: '🌧️',
    ),
    _AmbientSound(
      name: 'Ocean Waves',
      icon: Icons.waves,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      emoji: '🌊',
    ),
    _AmbientSound(
      name: 'Forest',
      icon: Icons.forest,
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      emoji: '🌲',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String url, String soundName) async {
    if (_playingSound == soundName && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_playingSound != soundName) {
        await _audioPlayer.play(UrlSource(url));
        setState(() {
          _playingSound = soundName;
          _isPlaying = true;
        });
      } else {
        await _audioPlayer.resume();
        setState(() => _isPlaying = true);
      }
    }
  }

  Future<void> _stopSound() async {
    await _audioPlayer.stop();
    setState(() {
      _playingSound = null;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambient Sounds'),
        backgroundColor: const Color(0xFF071A2B),
      ),
      body: Stack(
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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _sounds.length,
                    itemBuilder: (context, index) {
                      final sound = _sounds[index];
                      final isPlaying =
                          _playingSound == sound.name && _isPlaying;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isPlaying
                                ? const Color(0xFF00E6A8).withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00E6A8,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  sound.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sound.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPlaying
                                          ? 'Now playing...'
                                          : 'Tap to play',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _playSound(sound.url, sound.name),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPlaying
                                        ? const Color(
                                            0xFF00E6A8,
                                          ).withOpacity(0.3)
                                        : const Color(
                                            0xFF00E6A8,
                                          ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: const Color(0xFF00E6A8),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(_volume * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFF00E6A8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF00E6A8),
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: const Color(0xFF00E6A8),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: _volume,
                          onChanged: (value) async {
                            setState(() => _volume = value);
                            await _audioPlayer.setVolume(_volume);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isPlaying)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _stopSound,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Sound'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF00E6A8,
                              ).withOpacity(0.2),
                              foregroundColor: const Color(0xFF00E6A8),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientSound {
  final String name;
  final IconData icon;
  final String url;
  final String emoji;

  _AmbientSound({
    required this.name,
    required this.icon,
    required this.url,
    required this.emoji,
  });
}
