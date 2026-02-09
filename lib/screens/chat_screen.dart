import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    super.key,
    this.roomId = 'general',
    this.roomName = 'Chat',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void _showReactionPicker(BuildContext context, int messageIndex) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF003A3F),
        child: Wrap(
          spacing: 12,
          children: ['👍', '😂', '❤️', '😢', '🔥', '😍']
              .map(
                (emoji) => GestureDetector(
                  onTap: () {
                    _addReaction(messageIndex, emoji);
                    Navigator.pop(context);
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _addReaction(int messageIndex, String emoji) async {
    if (messageIndex >= _messages.length) return;
    final msg = _messages[messageIndex];
    final coll = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages');
    
    final snap = await coll
        .where('timestamp', isEqualTo: Timestamp.fromDate(msg.timestamp))
        .limit(1)
        .get();
    
    if (snap.docs.isNotEmpty) {
      final docId = snap.docs.first.id;
      final docRef = coll.doc(docId);
      final currentReactions = Map<String, int>.from(msg.reactions);
      final newCount = (currentReactions[emoji] ?? 0) + 1;
      currentReactions[emoji] = newCount;
      
      await docRef.update({'reactions': currentReactions});
    }
  }

  // Save a message locally using SharedPreferences
  Future<void> _saveMessage(_Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_messages') ?? [];
    // Store as a simple string: "[timestamp] username: text"
    final entry =
        '[${message.timestamp.toIso8601String()}] ${message.username ?? "Anonymous"}: ${message.text}';
    if (!saved.contains(entry)) {
      saved.add(entry);
      await prefs.setStringList('saved_messages', saved);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message saved locally!')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message already saved.')));
      }
    }
  }

  final List<_Message> _messages = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _typingSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _presenceSub;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _username;
  Timer? _typingTimer;
  Timer? _presenceTimer;
  String? _otherUserTyping;

  // active users from Firestore presence
  final List<_ActiveUser> _activeUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _startChatListener();
    _startTypingListener();
    _startPresenceListener();
    _updatePresence();
    _controller.addListener(_onTextChanged);
    // Update presence every 30 seconds to show we're still online
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updatePresence();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _typingTimer?.cancel();
    _presenceTimer?.cancel();
    _removePresence();
    _clearTypingIndicator();
    _controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // AI Moderation: Check for inappropriate content
    if (!_moderateMessage(text)) {
      _showModerationWarning();
      return;
    }

    _clearTypingIndicator();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final username = _username ?? 'Anonymous';
    debugPrint('📤 Sending message from $username (uid: $uid): $text');
    try {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .add({
            'text': text,
            'uid': uid,
            'username': username,
            'timestamp': FieldValue.serverTimestamp(),
            'reactions': {},
          })
          .then((docRef) {
            debugPrint('✅ Message sent successfully: ${docRef.id}');
          })
          .catchError((e) {
            debugPrint('❌ Failed to send message: $e');
          });
    } catch (e) {
      debugPrint('❌ Exception sending message: $e');
      // fallback to local append if write fails
      setState(() {
        _messages.add(
          _Message(
            text: text,
            isMe: true,
            username: username,
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      _controller.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _moderateMessage(String text) {
    final lowerText = text.toLowerCase();

    // List of inappropriate words/phrases to block
    final blockedWords = [
      'fuck', 'shit', 'bitch', 'ass', 'damn', 'cunt', 'dick', 'pussy',
      'whore', 'slut', 'nigger', 'fag', 'retard', 'kill yourself',
      'kys', 'suicide', 'die', 'idiot', 'stupid', 'dumb', 'loser',
      // Add more as needed
    ];

    // Check for blocked words
    for (final word in blockedWords) {
      if (lowerText.contains(word)) {
        debugPrint('🚫 Message blocked: Contains inappropriate content');
        return false;
      }
    }

    // Check for excessive caps (yelling)
    final capsCount = text
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    if (text.length > 10 && capsCount / text.length > 0.7) {
      debugPrint('🚫 Message blocked: Excessive caps (yelling)');
      return false;
    }

    // Check for spam (repeated characters)
    final repeatedPattern = RegExp(r'(.)\1{4,}'); // 5+ same chars in a row
    if (repeatedPattern.hasMatch(text)) {
      debugPrint('🚫 Message blocked: Spam pattern detected');
      return false;
    }

    return true;
  }

  void _showModerationWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your message was blocked. Please be respectful and supportive.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _startChatListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🔵 Starting chat listener... (my UID: $myUid)');
    try {
      final coll = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('messages')
          .limit(100);
      _sub = coll.snapshots().listen(
        (snap) {
          debugPrint('📨 Received ${snap.docs.length} messages from Firestore');
          debugPrint(
            '   Document IDs: ${snap.docs.map((d) => d.id).join(", ")}',
          );
          final docs = snap.docs;
          final now = DateTime.now();
          final msgs = docs
              .map((d) {
                final data = d.data();
                final ts = data['timestamp'];
                DateTime time;
                if (ts is Timestamp) {
                  time = ts.toDate();
                } else if (ts is String) {
                  time = DateTime.tryParse(ts) ?? DateTime.now();
                } else {
                  time = DateTime.now();
                }
                final uid = data['uid'] as String?;
                final username = data['username'] as String?;
                final isFromMe = myUid == uid;
                final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
                final reactions = <String, int>{};
                reactionsData.forEach((key, value) {
                  reactions[key] = (value as num).toInt();
                });
                debugPrint(
                  '  Message from $username (uid: $uid) [${isFromMe ? "ME" : "OTHER"}]: ${data['text']}',
                );
                return _Message(
                  text: data['text'] as String? ?? '',
                  isMe: isFromMe,
                  username:
                      username ??
                      (uid == FirebaseAuth.instance.currentUser?.uid
                          ? _username
                          : 'Anonymous'),
                  timestamp: time,
                  reactions: reactions,
                );
              })
              // Only keep messages from the last 15 minutes
              .where((msg) => now.difference(msg.timestamp).inMinutes < 15)
              .toList();
          // Sort by timestamp manually since we removed orderBy
          msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          setState(() {
            _messages
              ..clear()
              ..addAll(msgs);
          });
          debugPrint(
            '✅ Updated UI with ${_messages.length} messages (${msgs.where((m) => m.isMe).length} from me, ${msgs.where((m) => !m.isMe).length} from others)',
          );
          // scroll to bottom after UI updates
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent + 60,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          });
        },
        onError: (e) {
          debugPrint('❌ Chat listener error: $e');
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to start chat listener: $e');
    }
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _focusNode.requestFocus();
      _updateTypingIndicator();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _clearTypingIndicator();
      });
    } else {
      _clearTypingIndicator();
    }
  }

  void _updateTypingIndicator() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('typing')
          .doc(uid)
          .set({
            'username': _username ?? 'Anonymous',
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('❌ Failed to update typing indicator: $e');
    }
  }

  void _clearTypingIndicator() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('typing')
          .doc(uid)
          .delete();
    } catch (e) {
      debugPrint('❌ Failed to clear typing indicator: $e');
    }
  }

  void _startTypingListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      final typingColl = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('typing');

      _typingSub = typingColl.snapshots().listen((snap) {
        final otherUsers = snap.docs
            .where((doc) => doc.id != myUid)
            .map((doc) => doc.data()['username'] as String?)
            .where((name) => name != null)
            .toList();

        setState(() {
          _otherUserTyping = otherUsers.isNotEmpty ? otherUsers.first : null;
        });
      });
    } catch (e) {
      debugPrint('❌ Failed to start typing listener: $e');
    }
  }

  void _updatePresence() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('presence')
          .doc(uid)
          .set({
            'username': _username ?? 'Anonymous',
            'online': true,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('❌ Failed to update presence: $e');
    }
  }

  void _removePresence() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('presence')
          .doc(uid)
          .delete();
    } catch (e) {
      debugPrint('❌ Failed to remove presence: $e');
    }
  }

  void _startPresenceListener() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    try {
      _presenceSub = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('presence')
          .snapshots()
          .listen(
            (snap) {
              final now = DateTime.now();
              final users = snap.docs
                  .where((doc) {
                    if (doc.id == myUid) return false;
                    final data = doc.data();
                    if (data['online'] != true) return false;

                    // Only count as online if lastSeen is within last 60 seconds
                    final lastSeen = data['lastSeen'];
                    if (lastSeen is Timestamp) {
                      final lastSeenDate = lastSeen.toDate();
                      final diff = now.difference(lastSeenDate).inSeconds;
                      return diff < 60;
                    }
                    return true; // If no timestamp, include them
                  })
                  .map((doc) {
                    final data = doc.data();
                    final username = data['username'] as String? ?? 'User';
                    final color = Color.lerp(
                      const Color(0xFF005F56),
                      const Color(0xFF00E6A8),
                      (doc.id.hashCode % 5) / 4,
                    )!;
                    return _ActiveUser(name: username, color: color);
                  })
                  .toList();

              setState(() {
                _activeUsers.clear();
                _activeUsers.addAll(users);
              });
            },
            onError: (e) {
              debugPrint('❌ Presence listener error: $e');
            },
          );
    } catch (e) {
      debugPrint('❌ Failed to start presence listener: $e');
    }
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('nightnest_username_v1');
      setState(() {
        _username = (name == null || name.isEmpty) ? 'Anonymous' : name;
      });
    } catch (_) {
      setState(() => _username = 'Anonymous');
    }
  }

  String _formatTime(DateTime t) {
    final hour = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final minute = t.minute.toString().padLeft(2, '0');
    final suffix = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 Building ChatScreen with ${_messages.length} messages');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.roomName} (${_messages.length} msgs, ${_activeUsers.length} active)',
        ),
        backgroundColor: const Color(0xFF071A2B),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // aurora gradient background (globe removed)
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

            // chat UI on top
            Column(
              children: [
                // Active users bar
                SizedBox(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _activeUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final u = _activeUsers[index];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: u.color,
                                    child: Text(
                                      _initials(u.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      u.name,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // current user
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF00E6A8),
                              child: Text(
                                _initials(_username ?? 'You'),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 72,
                              child: Text(
                                _username ?? 'You',
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to send a message!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final m = _messages[index];
                            final bubbleColor = m.isMe
                                ? const Color(0xFF00E6A8) // aurora green (sent)
                                : const Color(
                                    0xFF5EE2D7,
                                  ); // soft cyan (received)

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: m.isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: m.isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      LayoutBuilder(
                                    builder: (context, _) {
                                      final screenWidth = MediaQuery.of(
                                        context,
                                      ).size.width;
                                      final maxWidth = min(
                                        520.0,
                                        screenWidth * 0.78,
                                      );
                                      final textColor =
                                          bubbleColor.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white;
                                      final bool small = screenWidth < 360;

                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: maxWidth,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: bubbleColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color.fromRGBO(
                                                  0,
                                                  0,
                                                  0,
                                                  0.08,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(
                                                18,
                                              ),
                                              topRight: const Radius.circular(
                                                18,
                                              ),
                                              bottomLeft: Radius.circular(
                                                m.isMe ? 18 : 4,
                                              ),
                                              bottomRight: Radius.circular(
                                                m.isMe ? 4 : 18,
                                              ),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            child: Column(
                                              crossAxisAlignment: m.isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  m.username ??
                                                      (m.isMe
                                                          ? (_username ?? 'You')
                                                          : 'Support'),
                                                  style: TextStyle(
                                                    color: textColor
                                                        .withOpacity(0.95),
                                                    fontSize: small ? 9 : 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  m.text,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: small ? 12 : 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      _formatTime(m.timestamp),
                                                      style: TextStyle(
                                                        color: textColor
                                                            .withOpacity(0.85),
                                                        fontSize: small
                                                            ? 8
                                                            : 9,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: IconButton(
                                                        padding: EdgeInsets.zero,
                                                        icon: Icon(
                                                          Icons.bookmark_border,
                                                          color: textColor
                                                              .withOpacity(0.95),
                                                          size: 16,
                                                        ),
                                                        tooltip: 'Save message',
                                                        onPressed: () =>
                                                            _saveMessage(m),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (m.reactions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                                  child: Wrap(
                                    spacing: 4,
                                    children: m.reactions.entries
                                        .map(
                                          (e) => GestureDetector(
                                            onLongPress: () => _addReaction(index, e.key),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF003A3F)
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              child: Text(
                                                '${e.key} ${e.value}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              GestureDetector(
                                onLongPress: () => _showReactionPicker(context, index),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    left: 8,
                                    right: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF003A3F)
                                          .withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      '+',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                          },
                        ),
                ),
                const Divider(height: 1),
                // Typing indicator
                if (_otherUserTyping != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_otherUserTyping is typing',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 20,
                          height: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _TypingDot(delay: 0),
                              _TypingDot(delay: 200),
                              _TypingDot(delay: 400),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _send,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isMe;
  final String? username;
  final DateTime timestamp;
  final Map<String, int> reactions; // emoji -> count
  _Message({
    required this.text,
    required this.isMe,
    required this.username,
    required this.timestamp,
    this.reactions = const {},
  });
}

class _ActiveUser {
  final String name;
  final Color color;
  _ActiveUser({required this.name, required this.color});
}

String _initials(String name) {
  final parts = name.split(' ');
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// globe and marker rendering removed — chat background is now a simple aurora gradient
