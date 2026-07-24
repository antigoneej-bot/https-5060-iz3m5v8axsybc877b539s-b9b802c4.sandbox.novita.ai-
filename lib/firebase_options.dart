// File generated for Mystic Cat Journal (mycatapp-99bc8).
// This file was created manually from the Firebase Console configuration
// (google-services.json for Android, Firebase Web app config for Web).
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by re-running the FlutterFire CLI.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by re-running the FlutterFire CLI.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by re-running the FlutterFire CLI.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by re-running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5myNzD4x-eAYHRWLD7DT86cbNuYgy2Sk',
    appId: '1:874265239553:web:ecb7b61d6d1e761b63a000',
    messagingSenderId: '874265239553',
    projectId: 'mycatapp-99bc8',
    authDomain: 'mycatapp-99bc8.firebaseapp.com',
    storageBucket: 'mycatapp-99bc8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyACQyOCdLnfqe9q1VDuOKZvhlMIHjqjhks',
    appId: '1:874265239553:android:c55a29d01bb558fc63a000',
    messagingSenderId: '874265239553',
    projectId: 'mycatapp-99bc8',
    storageBucket: 'mycatapp-99bc8.firebasestorage.app',
  );
}
