import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase Options
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFLmyjyLklK1Gak6Nty7rvoKqVS9lN-zg',
    appId: '1:58643172194:web:a0bc9837ef58897c',
    messagingSenderId: '58643172194',
    projectId: 'personal-finance-flutter-a88c0',
    authDomain: 'personal-finance-flutter-a88c0.firebaseapp.com',
    storageBucket: 'personal-finance-flutter-a88c0.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFLmyjyLklK1Gak6Nty7rvoKqVS9lN-zg',
    appId: '1:58643172194:android:5aaef175a9cfacee7aba3b',
    messagingSenderId: '58643172194',
    projectId: 'personal-finance-flutter-a88c0',
    storageBucket: 'personal-finance-flutter-a88c0.firebasestorage.app',
  );
}
