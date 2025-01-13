import 'package:fliccsy/auth/login_screen.dart';
import 'package:fliccsy/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state
    final authState = ref.watch(authStateProvider);

    // Return loading screen while waiting for auth state
    return authState.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text('Error: $error'),
      data: (user) {
        // If user is null, they're not signed in
        if (user == null) {
          return const LoginScreen();
        }
        // If user is signed in, show the main app
        return const HomeScreen();
      },
    );
  }
}
