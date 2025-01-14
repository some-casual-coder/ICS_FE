import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/widgets/movie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwipeScreen extends ConsumerWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movieStateProvider);
    final notifier = ref.read(movieStateProvider.notifier);

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
            child: state.movies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No more movies!',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => notifier.reset(),
                          child: const Text('Start Over'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: state.movies
                        .map((movie) => MovieCard(
                              movie: movie,
                              isFront: state.movies.last == movie,
                            ))
                        .toList(),
                  ),
          ),
        ),
      ),
    );
  }
}
