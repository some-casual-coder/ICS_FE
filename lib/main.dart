import 'package:firebase_core/firebase_core.dart';
import 'package:fliccsy/screens/onboarding/get_started_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyCD8N1MG5RPWmYOfIN8lO4klvK9s1ev8tQ",
            authDomain: "duet-8fbde.firebaseapp.com",
            projectId: "duet-8fbde",
            storageBucket: "duet-8fbde.firebasestorage.app",
            messagingSenderId: "705275486056",
            appId: "1:705275486056:web:eb0f88519a64b0da02c0dd",
            measurementId: "G-6V2B27EL97"));
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fliccsy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const AuthWrapper(),
      home: const GetStartedScreen(),
    );
  }
}
