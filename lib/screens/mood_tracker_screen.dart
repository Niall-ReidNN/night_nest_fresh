import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final List<JournalEntry> _entries = [];
  static const _prefsKey = 'journal_entries_v1';

  final Map<String, String> _moodEmoji = {
    'Happy': '😊',
    'Calm': '😌',
    'Neutral': '😐',
    'Sad': '😢',
    'Anxious': '😟',
  };

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = json.decode(raw) as List<dynamic>;
      setState(() {
        _entries.clear();
        _entries.addAll(
          list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)),
        );
      });
    } catch (_) {
      // ignore parse errors
    }
  }

  /// Build a map from Date (yyyy-mm-dd) to latest mood for that day
  Map<String, String> _computeDailyMood() {
    final Map<String, String> map = {};
    for (final e in _entries) {
      final key = e.timestamp.toIso8601String().substring(0, 10);
      // prefer the later entry (we iterate in insertion order, so overwrite is fine)
      if (e.mood != null) map[key] = e.mood!;
    }
    return map;
  }

  List<DateTime> _lastNDays(int n) {
    final today = DateTime.now();
    return List.generate(
      n,
      (i) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daily = _computeDailyMood();
    final days = _lastNDays(14);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh entries',
            onPressed: _loadEntries,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last 14 days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final d = days[idx];
                  final key = d.toIso8601String().substring(0, 10);
                  final mood = daily[key];
                  final emoji = mood != null ? (_moodEmoji[mood] ?? '') : '-';
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).cardColor,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Recent entries',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('No journal entries yet'))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, i) {
                        final e =
                            _entries[_entries.length - 1 - i]; // newest first
                        return ListTile(
                          title: Text(e.text),
                          subtitle: Text(_formatDateTimeUK(e.timestamp)),
                          trailing: e.mood != null
                              ? Chip(
                                  label: Text(
                                    '${_moodEmoji[e.mood!] ?? ''} ${e.mood!}',
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeUK(DateTime t) {
    final day = t.day.toString().padLeft(2, '0');
    final month = t.month.toString().padLeft(2, '0');
    final year = t.year.toString();
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
