import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/movie_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwipeScreen extends ConsumerWidget {
  final StateNotifierProvider<MovieNotifier, MovieState> movieProvider;
  const SwipeScreen({
    super.key,
    required this.movieProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movieProvider);
    final notifier = ref.read(movieProvider.notifier);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Session Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Total Swipes: ${state.upSwipes + state.downSwipes + state.rightSwipes + state.leftSwipes}'),
                  const Divider(),
                  Text('Interested (Right): ${state.rightSwipes}'),
                  Text('Not Interested (Left): ${state.leftSwipes}'),
                  Text('Watched & Liked (Up): ${state.upSwipes}'),
                  Text('Not Sure (Down): ${state.downSwipes}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
          return;
        }
        return;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Movie Swipe'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Session Statistics'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Total Swipes: ${state.upSwipes + state.downSwipes + state.rightSwipes + state.leftSwipes}'),
                        const Divider(),
                        Text('Interested (Right): ${state.rightSwipes}'),
                        Text('Not Interested (Left): ${state.leftSwipes}'),
                        Text('Watched & Liked (Up): ${state.upSwipes}'),
                        Text('Not Sure (Down): ${state.downSwipes}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: state.isLoading
                ? const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20, // Makes it a bit larger
                    ),
                  )
                : state.movies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No movies found!',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => notifier.reset(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary, // Set background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      30), // Rounded corners
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8), // Optional padding
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Ensures the button's size adjusts to its content
                                children: [
                                  Icon(Icons.refresh,
                                      color: Colors.white), // Retry icon
                                  const SizedBox(
                                      width: 8), // Space between icon and text
                                  const Text(
                                    'Retry',
                                    style: TextStyle(
                                        color: Colors
                                            .white), // Ensure text color contrasts with the background
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: state.movies
                            .map((movie) => MovieCard(
                                  movie: movie,
                                  isFront: state.movies.last == movie,
                                  movieProvider: movieProvider,
                                ))
                            .toList(),
                      ),
          ),
        ),
      ),
    );
  }
}
