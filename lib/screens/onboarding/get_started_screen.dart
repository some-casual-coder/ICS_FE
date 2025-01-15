import 'package:fliccsy/screens/onboarding/onboarding_screen.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/smile_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 72),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Larger, less solid circle
                  Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  // Image
                  Image.asset(
                    'assets/images/get_started.png',
                    height: 400,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    "Hey there!",
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 30, // Now width and height are swapped from before
                    height: 15,
                    child: CustomPaint(
                      painter: SmileLinePainter(color: AppColors.primary),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 2),
              Text(
                "Let's get to know you a bit better so we can suggest the best movies. It won't take long, promise!",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  color: AppColors.darkAccent,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
