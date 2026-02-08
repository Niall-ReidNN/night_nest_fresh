// TODO: Run 'flutterfire configure' to replace this with your real Firebase config
// This is a placeholder that allows the app to compile.
// Firebase features won't work until you configure a real project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUKse_m2BUkUJ2XcHD10Ew6FgtPt-bejw',
    appId: '1:669800937615:web:a0dbe490189278219798fa',
    messagingSenderId: '669800937615',
    projectId: 'night-nest-new',
    authDomain: 'night-nest-new.firebaseapp.com',
    storageBucket: 'night-nest-new.firebasestorage.app',
    measurementId: 'G-0T8DSGT83R',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDcyZi370iAKPSU9-yKbuFLd4gQUnw83pE',
    appId: '1:669800937615:android:6f8975e2313bccc29798fa',
    messagingSenderId: '669800937615',
    projectId: 'night-nest-new',
    storageBucket: 'night-nest-new.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgrQExFcmGcqy1Ldr8imfx2szjoXPkjgI',
    appId: '1:669800937615:ios:4e3ed070efe6022b9798fa',
    messagingSenderId: '669800937615',
    projectId: 'night-nest-new',
    storageBucket: 'night-nest-new.firebasestorage.app',
    iosBundleId: 'com.niallconsulting.nightnest', // Update this to your actual bundle ID
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBgrQExFcmGcqy1Ldr8imfx2szjoXPkjgI',
    appId: '1:669800937615:ios:4e3ed070efe6022b9798fa',
    messagingSenderId: '669800937615',
    projectId: 'night-nest-new',
    storageBucket: 'night-nest-new.firebasestorage.app',
    iosBundleId: 'com.example.nightNestFresh',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDUKse_m2BUkUJ2XcHD10Ew6FgtPt-bejw',
    appId: '1:669800937615:web:af1306041cad09469798fa',
    messagingSenderId: '669800937615',
    projectId: 'night-nest-new',
    authDomain: 'night-nest-new.firebaseapp.com',
    storageBucket: 'night-nest-new.firebasestorage.app',
    measurementId: 'G-8ZBH7WSVGQ',
  );

}