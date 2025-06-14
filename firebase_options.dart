// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnjLqhG_K8aWF7QgOLFKq5I0L-zuwAyn4',
    authDomain: 'studentportal-49d00.firebaseapp.com',
    projectId: 'studentportal-49d00',
    storageBucket: 'studentportal-49d00.firebasestorage.app',
    messagingSenderId: '286125361384',
    appId: '1:286125361384:web:6824c0958929f86a23215d',
    measurementId: 'G-N3BZ5DTNLE',
  );
}