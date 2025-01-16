import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/providers/onboarding_provider.dart';
import 'package:fliccsy/providers/submission_provider.dart';
import 'package:fliccsy/screens/onboarding/submitting_screen.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/genre_selector.dart';
import 'package:fliccsy/widgets/movie_selector.dart';
import 'package:fliccsy/widgets/preferences_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Choose Your Genres',
      description:
          'Select your favorite movie genres to personalize your experience',
      content: GenreSelector(), // Will be replaced with actual content
    ),
    const OnboardingPage(
      title: 'Favorite Movies',
      description: 'Pick some movies you love to help us understand your taste',
      content: MovieSelector(), // Will be replaced with actual content
    ),
    const OnboardingPage(
      title: 'General Preferences',
      description: 'Set up your viewing preferences for a better experience',
      content: PreferencesSelector(), // Will be replaced with actual content
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final user = await ref.read(authStateProvider.future);
      final userId = user?.uid ?? 'default_user_id';
      // final userId = "test_user_123";
      final success =
          await ref.read(submissionProvider.notifier).validateAndSubmit(userId);

      if (success) {
        if (!mounted) return;
        await ref
            .read(onboardingCompletedProvider.notifier)
            .completeOnboarding();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SubmittingScreen()),
        );
      } else {
        final error = ref.read(submissionProvider).error;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Please complete all sections')),
        );
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  TextButton(
                    onPressed: _currentPage == 0 ? null : _previousPage,
                    child: Text(
                      'Back',
                      style: TextStyle(
                        color: _currentPage == 0
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  // Page indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final Widget content;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.roboto(
              fontSize: 20,
              color: AppColors.darkAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CustomPaint(
            size: const Size(double.infinity, 2),
            painter: DottedLinePainter(color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashWidth = 5;
    const double dashSpace = 8;
    double currentX = 0;

    while (currentX < size.width) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
