import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  const RoomSelectionScreen({super.key});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final Map<String, int> _roomCounts = {};

  @override
  void initState() {
    super.initState();
    _listenToRoomPresence();
  }

  void _listenToRoomPresence() {
    final rooms = [
      'nicu',
      'babies_at_home',
      'children_in_hospital',
      'night_feeding',
      'breastfeeding',
      'general',
    ];
    for (final room in rooms) {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(room)
          .collection('presence')
          .snapshots()
          .listen((snap) {
            if (mounted) {
              setState(() {
                _roomCounts[room] = snap.docs.length;
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
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
            _buildRoomCard(
              context,
              roomId: 'nicu',
              title: 'NICU',
              description: 'Support for parents with babies in NICU',
              icon: Icons.baby_changing_station,
              color: const Color(0xFF00E6A8),
            ),
            const SizedBox(height: 16),
            _buildRoomCard(
              context,
              roomId: 'babies_at_home',
              title: 'Babies at Home',
              description: 'Connect with parents caring for babies at home',
              icon: Icons.home,
              color: const Color(0xFF00C9A8),
            ),
            const SizedBox(height: 16),
            _buildRoomCard(
              context,
              roomId: 'children_in_hospital',
              title: 'Children in Hospital',
              description: 'Support for parents with hospitalized children',
              icon: Icons.local_hospital,
              color: const Color(0xFF00ACA8),
            ),
            const SizedBox(height: 16),
            _buildRoomCard(
              context,
              roomId: 'night_feeding',
              title: 'Night Feeding',
              description: 'Chat with other parents during night feeds',
              icon: Icons.nightlight_round,
              color: const Color(0xFF9C78E6),
            ),
            const SizedBox(height: 16),
            _buildRoomCard(
              context,
              roomId: 'breastfeeding',
              title: 'Breastfeeding',
              description: 'Support and tips for breastfeeding parents',
              icon: Icons.child_care,
              color: const Color(0xFF00BFA6),
            ),
            const SizedBox(height: 16),
            _buildRoomCard(
              context,
              roomId: 'general',
              title: 'General Support',
              description: 'Open discussion for all parents',
              icon: Icons.forum,
              color: const Color(0xFF008FA8),
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF003A3F).withOpacity(0.8),
              child: ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.white),
                title: const Text(
                  'Saved chats',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'View messages you saved locally',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/saved_chats');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String roomId,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final count = _roomCounts[roomId] ?? 0;

    return Card(
      color: const Color(0xFF003A3F).withOpacity(0.8),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(roomId: roomId, roomName: title),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      count > 0
                          ? '$count ${count == 1 ? 'person' : 'people'} online'
                          : 'No one online yet',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
