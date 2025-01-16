import 'package:fliccsy/models/user_data.dart';
import 'package:flutter/material.dart';

class ProgressTracker extends StatelessWidget {
  const ProgressTracker({
    super.key,
    required this.user,
  });

  final MapEntry<String, UserData> user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Main battery container
        Container(
          width: 48,
          height: 24,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: user.value.totalMovies! > 0
                    ? user.value.swipeProgress! / user.value.totalMovies!
                    : 0,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
        ),
        Positioned(
          right: -4,
          child: Container(
            width: 4,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(2),
              ),
            ),
          ),
        ),
        // Positioned(
        //   left: 56, // Adjust based on your needs
        //   child: Text(
        //     '${user.value.swipeProgress}/${user.value.totalMovies}',
        //     style: TextStyle(
        //       color: Colors.grey.shade600,
        //       fontSize: 12,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
