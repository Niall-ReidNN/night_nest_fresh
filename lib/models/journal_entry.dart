class JournalEntry {
  final String text;
  final DateTime timestamp;
  final String? mood; // e.g. "Happy", "Sad", "Calm"

  JournalEntry({required this.text, required this.timestamp, this.mood});

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'mood': mood,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    text: json['text'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    mood: json['mood'] as String?,
  );
}
