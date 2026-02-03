import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';

const _usernameKey = 'nightnest_username_v1';
const _audioPreferenceKey = 'nightnest_audio_enabled_v1';
const _notificationsEnabledKey = 'nightnest_notifications_enabled_v1';
const _notificationHourKey = 'nightnest_notification_hour_v1';
const _notificationMinuteKey = 'nightnest_notification_minute_v1';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = true;
  bool _audioEnabled = true;
  bool _notificationsEnabled = false;
  int _notificationHour = 21; // 9 PM default
  int _notificationMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _usernameController.text = data?['username'] ?? '';
            _audioEnabled = data?['audioEnabled'] ?? true;
            _isLoading = false;
          });

          // Save to local storage for offline access
          if (data?['username'] != null) {
            await prefs.setString(_usernameKey, data!['username']);
          }
          await prefs.setBool(_audioPreferenceKey, _audioEnabled);
          return;
        }
      } catch (e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          debugPrint('Permission denied. Please check Firestore rules.');
        } else {
          debugPrint('Error loading from Firestore: $e');
        }
      }
    }

    // Fall back to local storage
    setState(() {
      _usernameController.text = prefs.getString(_usernameKey) ?? '';
      _audioEnabled = prefs.getBool(_audioPreferenceKey) ?? true;
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? false;
      _notificationHour = prefs.getInt(_notificationHourKey) ?? 21;
      _notificationMinute = prefs.getInt(_notificationMinuteKey) ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _scheduleNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    if (_notificationsEnabled) {
      // Schedule the notification
      await NotificationService().scheduleNightAffirmation(
        hour: _notificationHour,
        minute: _notificationMinute,
      );

      // Save preferences
      await prefs.setBool(_notificationsEnabledKey, true);
      await prefs.setInt(_notificationHourKey, _notificationHour);
      await prefs.setInt(_notificationMinuteKey, _notificationMinute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Night affirmations scheduled for ${_notificationHour.toString().padLeft(2, '0')}:${_notificationMinute.toString().padLeft(2, '0')}',
            ),
          ),
        );
      }
    } else {
      // Cancel notifications
      await NotificationService().cancelAllNotifications();
      await prefs.setBool(_notificationsEnabledKey, false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Night affirmations disabled')),
        );
      }
    }
  }

  Future<void> _saveUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = _usernameController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (username.isNotEmpty) {
      // Save locally
      await prefs.setString(_usernameKey, username);

      // Save to Firestore if authenticated
      if (uid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'username': username,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error saving to Firestore: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Username saved')));
      }
    } else {
      // Clear locally
      await prefs.remove(_usernameKey);

      // Clear in Firestore if authenticated
      if (uid != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'username': FieldValue.delete(),
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error clearing username in Firestore: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Username cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF071A2B),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF071A2B), Color(0xFF003A3F), Color(0xFF003A66)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Username Section
            Card(
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Username',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This name will be shown to others in chat',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Enter your username',
                        hintStyle: TextStyle(color: Colors.white38),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00E6A8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _saveUsername,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E6A8),
                      ),
                      child: const Text('Save Username'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Night Affirmations Section
            Card(
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Night Affirmations 🌙',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Receive a calming affirmation at bedtime',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text(
                        'Enable notifications',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        _scheduleNotifications();
                      },
                      activeColor: const Color(0xFF00E6A8),
                    ),
                    if (_notificationsEnabled) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Notification time',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<int>(
                              value: _notificationHour,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF003A3F),
                              items: List.generate(24, (i) => i)
                                  .map(
                                    (h) => DropdownMenuItem(
                                      value: h,
                                      child: Text(
                                        h.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _notificationHour = value);
                                  _scheduleNotifications();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            ':',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _notificationMinute,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF003A3F),
                              items: [0, 15, 30, 45]
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m.toString().padLeft(2, '0'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _notificationMinute = value);
                                  _scheduleNotifications();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // App Information Section
            Card(
              color: Colors.white.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Night Nest v1.0.0',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'An emotional support tool for all parents',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
