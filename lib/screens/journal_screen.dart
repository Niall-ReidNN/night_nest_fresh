import 'package:flutter/material.dart';
import 'grounding_screen.dart';
import '../models/journal_entry.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<JournalEntry> entries = [];
  final TextEditingController controller = TextEditingController();
  String _selectedMood = 'Neutral';
  final List<String> _moods = ['Happy', 'Calm', 'Neutral', 'Sad', 'Anxious'];
  final Map<String, String> _moodEmoji = {
    'Happy': '😊',
    'Calm': '😌',
    'Neutral': '😐',
    'Sad': '😢',
    'Anxious': '😟',
  };

  static const _prefsKey = 'journal_entries_v1';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  String _formatDateTimeUK(DateTime t) {
    final day = t.day.toString().padLeft(2, '0');
    final month = t.month.toString().padLeft(2, '0');
    final year = t.year.toString();
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _loadEntries() async {
    // If user is signed in, prefer reading from Firestore (cloud). Otherwise
    // fall back to local SharedPreferences.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('journal')
            .orderBy('timestamp', descending: false)
            .get();
        final docs = snap.docs;
        setState(() {
          entries.clear();
          entries.addAll(
            docs.map((d) {
              final data = d.data();
              // timestamp might be stored as ISO string
              final map = <String, dynamic>{
                'text': data['text'],
                'mood': data['mood'],
                'timestamp': data['timestamp'],
              };
              return JournalEntry.fromJson(Map<String, dynamic>.from(map));
            }).toList(),
          );
        });
        return;
      } catch (e) {
        // fall back to local if Firestore read fails
        debugPrint('⚠️ Firestore read failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = json.decode(raw) as List<dynamic>;
      setState(() {
        entries.clear();
        entries.addAll(
          list
              .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      });
    } catch (_) {
      // ignore parse errors
    }
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  void saveEntry() {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        entries.add(
          JournalEntry(
            text: text,
            timestamp: DateTime.now(),
            mood: _selectedMood,
          ),
        );
        controller.clear();
      });
      // persist and show a confirmation so it's obvious the entry was saved
      _saveAll().then((_) {
        // Also try saving to Firestore if the user is signed-in
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          try {
            final entry = entries.last;
            FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('journal')
                .add(entry.toJson());
          } catch (e) {
            debugPrint('⚠️ Firestore write failed: $e');
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Entry saved')));
        }
      });
    }
  }

  @override
  void dispose() {
    // Ensure entries are saved when leaving the screen
    _saveAll();
    controller.dispose();
    super.dispose();
  }

  Map<String, int> _moodCounts({int days = 14}) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days));
    final counts = <String, int>{for (var m in _moods) m: 0};
    for (final e in entries) {
      if (e.timestamp.isAfter(cutoff)) {
        final mood = e.mood ?? 'Neutral';
        if (counts.containsKey(mood)) {
          counts[mood] = counts[mood]! + 1;
        }
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return GroundingScaffold(
      title: 'Journal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Input card
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.white.withOpacity(0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedMood,
                          items: _moods
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    '${_moodEmoji[m] ?? ''} $m',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMood = v ?? 'Neutral'),
                          decoration: const InputDecoration(
                            labelText: 'Mood',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          dropdownColor: const Color(0xFF071A2B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E6A8),
                        ),
                        child: const Text('Save Entry'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white24),

          // Mood trend summary (recent N days)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: Colors.white.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mood Trend (last 14 days)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final counts = _moodCounts(days: 14);
                      final total = counts.values.fold<int>(0, (a, b) => a + b);
                      return Column(
                        children: _moods.map((m) {
                          final count = counts[m] ?? 0;
                          final fraction = total == 0
                              ? 0.0
                              : (count / total).clamp(0.0, 1.0);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    '${_moodEmoji[m] ?? ''} $m',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: fraction,
                                        child: Container(
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00E6A8),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 36,
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Entries list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.white.withOpacity(0.04),
                  child: ListTile(
                    title: Text(
                      entry.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _formatDateTimeUK(entry.timestamp),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: entry.mood != null
                        ? Chip(
                            backgroundColor: Colors.white10,
                            label: Text(
                              '${_moodEmoji[entry.mood!] ?? ''} ${entry.mood!}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
