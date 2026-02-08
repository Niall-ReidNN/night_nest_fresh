import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/journal_entry.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/affirmation_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/room_selection_screen.dart';
import 'screens/consent_screen.dart';
import 'screens/saved_chats_screen.dart';
import 'screens/mood_tracker_screen.dart';
import 'screens/main_screen.dart';
import 'screens/globe_screen.dart';
import 'screens/grounding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  // Sign in anonymously
  try {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    final uid = cred.user?.uid;
    debugPrint('✅ Signed in anonymously: $uid');

    // One-time migration: upload local journal entries to Firestore
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('journal_entries_v1');
      if (raw != null) {
        try {
          final list = json.decode(raw) as List<dynamic>;
          final coll = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('journal');
          for (final item in list) {
            final je = JournalEntry.fromJson(item as Map<String, dynamic>);
            await coll.add({
              'text': je.text,
              'mood': je.mood,
              'timestamp': je.timestamp.toIso8601String(),
            });
          }
          await prefs.remove('journal_entries_v1');
          debugPrint(
            '✅ Migrated ${list.length} local journal entries to Firestore',
          );
        } catch (e) {
          debugPrint('⚠️ Migration failed: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('⚠️ Anonymous sign-in failed: $e');
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notification service initialized');
  } catch (e) {
    debugPrint('⚠️ Notification service init failed: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('nightnest_authenticated', false);
  final initialRoute = '/password';
  
  runApp(NightNestApp(initialRoute: initialRoute));
}

class NightNestApp extends StatelessWidget {
  const NightNestApp({super.key, this.initialRoute = '/'});

  final String initialRoute;

  // Firebase Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    // Use the splash gradient colors as the app palette
    const splashTop = Color(0xFF071A2B); // deep teal
    const splashMid = Color(0xFF003A3F); // deep green-blue
    const accent = Color(0xFF00E6A8); // bright cyan-green used as accent

    final theme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: splashTop,
      scaffoldBackgroundColor: splashTop,
      colorScheme: ColorScheme.dark(
        primary: splashTop,
        secondary: accent,
        surface: splashMid,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: splashTop, elevation: 0),
      cardColor: splashMid,
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
      ),
    );

    return MaterialApp(
      title: 'Night Nest',
      theme: theme,
      navigatorObservers: [observer],
      initialRoute: initialRoute,
      routes: {
        '/password': (context) => const PasswordScreen(),
        '/': (context) => const SplashScreen(),
        '/affirmation': (context) => const AffirmationScreen(),
        '/consent': (context) => const ConsentScreen(),
        '/main': (context) => const MainScreen(),
        '/journal': (context) => const JournalScreen(),
        '/chat': (context) => const RoomSelectionScreen(),
        '/saved_chats': (context) => const SavedChatsScreen(),
        '/globe': (context) => const GlobeScreen(),
        '/mood': (context) => const MoodTrackerScreen(),
        '/grounding': (context) => const GroundingScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
