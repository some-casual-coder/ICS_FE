// File generated by FlutterFire CLI.
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
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCD8N1MG5RPWmYOfIN8lO4klvK9s1ev8tQ',
    appId: '1:705275486056:web:4b2dcb7fbaad2dff02c0dd',
    messagingSenderId: '705275486056',
    projectId: 'duet-8fbde',
    authDomain: 'duet-8fbde.firebaseapp.com',
    storageBucket: 'duet-8fbde.firebasestorage.app',
    measurementId: 'G-CQNFTC791P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCShhtswOLNivTbtmRlsma3t1RecFDB5jY',
    appId: '1:705275486056:android:6b70f5530d5d250c02c0dd',
    messagingSenderId: '705275486056',
    projectId: 'duet-8fbde',
    storageBucket: 'duet-8fbde.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDfDqAQ5OcONjECXhGWTUw4C3ix8nXHoS4',
    appId: '1:705275486056:ios:309b256fd438625d02c0dd',
    messagingSenderId: '705275486056',
    projectId: 'duet-8fbde',
    storageBucket: 'duet-8fbde.firebasestorage.app',
    androidClientId: '705275486056-5tk026huvadk1c6rsm4ci2gtisqbkqd5.apps.googleusercontent.com',
    iosClientId: '705275486056-dvlj6rd4j3vgp0h42fl1logn99qk93es.apps.googleusercontent.com',
    iosBundleId: 'com.example.fliccsy',
  );
}
