import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedChatsScreen extends StatefulWidget {
  const SavedChatsScreen({super.key});

  @override
  State<SavedChatsScreen> createState() => _SavedChatsScreenState();
}

class _SavedChatsScreenState extends State<SavedChatsScreen> {
  List<String> _saved = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saved = prefs.getStringList('saved_messages')?.reversed.toList() ?? [];
    });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_messages');
    setState(() => _saved = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Chats'),
        backgroundColor: const Color(0xFF071A2B),
        actions: [
          if (_saved.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Clear all saved chats',
              onPressed: () async {
                final ok =
                    await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Clear saved chats?'),
                        content: const Text(
                          'This will remove all saved chats.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (ok) await _clearAll();
              },
            ),
        ],
      ),
      body: _saved.isEmpty
          ? Center(
              child: Text(
                'No saved chats yet.',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _saved.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = _saved[index];
                return ListTile(
                  title: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                  isThreeLine: true,
                  dense: false,
                  onTap: () {},
                );
              },
            ),
    );
  }
}
