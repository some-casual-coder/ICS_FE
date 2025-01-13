import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(authServiceProvider).signInWithGoogle();
              // Navigate to home screen or handle success
            } catch (e) {
              // Handle error (show snackbar, dialog, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error signing in: $e')),
              );
            }
          },
          child: const Text('Sign in with Google'),
        ),
      ),
    );
  }
}
