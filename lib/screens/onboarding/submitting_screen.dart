import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:fliccsy/providers/submission_provider.dart';
import 'package:fliccsy/screens/home_screen.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubmittingScreen extends ConsumerStatefulWidget {
  const SubmittingScreen({super.key});

  @override
  ConsumerState<SubmittingScreen> createState() => _SubmittingScreenState();
}

class _SubmittingScreenState extends ConsumerState<SubmittingScreen> {
  late ConfettiController _confettiController;
  String _currentText = '';
  Timer? _timer;

  final Map<SubmissionStep, String> _stepTexts = {
    SubmissionStep.genres: 'Setting up genres...',
    SubmissionStep.movies: 'Setting up movies...',
    SubmissionStep.preferences: 'Saving preferences...',
    SubmissionStep.completed: 'Profile setup complete!',
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _startTypeAnimation();
  }

  void _startTypeAnimation() {
    final submissionState = ref.read(submissionProvider);
    final fullText = _stepTexts[submissionState.currentStep] ?? '';

    int index = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (index <= fullText.length) {
        setState(() {
          _currentText = fullText.substring(0, index);
        });
        index++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _currentText = '';
          });
          if (submissionState.currentStep == SubmissionStep.completed) {
            _confettiController.play();
            Future.delayed(const Duration(seconds: 4), () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(submissionProvider, (previous, next) {
      if (previous?.currentStep != next.currentStep) {
        _startTypeAnimation();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(
                ref.watch(submissionProvider).currentStep ==
                        SubmissionStep.completed
                    ? Icons.check
                    : Icons.hourglass_empty,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentText,
              style: const TextStyle(
                color: AppColors.darkAccent,
                fontSize: 18,
                fontFamily: 'Fredoka',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
