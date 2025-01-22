import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/providers/auth_provider.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/services/batch_interaction_service.dart';
import 'package:fliccsy/services/websockets/websocket_service.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/movie_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  final StateNotifierProvider<MovieNotifier, MovieState> movieProvider;

  const SwipeScreen({
    super.key,
    required this.movieProvider,
  });

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final _interactionService = InteractionService();
  final webSocketServiceProvider = Provider((ref) => WebSocketService());

  @override
  void initState() {
    super.initState();
    print('SwipeScreen: Initializing with 15 total movies');
    ref.read(webSocketServiceProvider).updateStatus('swiping');
    print('SwipeScreen: Status updated to swiping');
  }

  void _updateSwipeProgress(MovieState state) {
    final swipedCount = state.upSwipes +
        state.downSwipes +
        state.rightSwipes +
        state.leftSwipes;

    print('SwipeScreen: Updating progress - $swipedCount/15');
    ref
        .read(webSocketServiceProvider)
        .updateProgress(swipedCount, state.movies.length);
  }

  Future<bool> _handleSwipingComplete(String userId) async {
    ref.read(webSocketServiceProvider).updateStatus('completed');
    // Record batch swipes
    return await _interactionService.recordBatchSwipesFromState(
      userId: userId,
      state: ref.read(widget.movieProvider),
    );
  }

  void _showSwipeNotification(BuildContext context, SwipeStatus status) {
    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case SwipeStatus.interested:
        message = "Interested";
        backgroundColor = Colors.green;
        icon = Icons.thumb_up;
        break;
      case SwipeStatus.notInterested:
        message = "Not Interested";
        backgroundColor = Colors.red;
        icon = Icons.thumb_down;
        break;
      case SwipeStatus.watchedAndLiked:
        message = "Watched & Liked";
        backgroundColor = Colors.blue;
        icon = Icons.favorite;
        break;
      case SwipeStatus.notSure:
        message = "Not sure";
        backgroundColor = Colors.orange;
        icon = Icons.watch_later;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: backgroundColor,
        duration: const Duration(milliseconds: 500),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.movieProvider);
    final user = ref.watch(authStateProvider).value;
    _updateSwipeProgress(state);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Set status back to joined if leaving early
          if (state.movies.isNotEmpty) {
            ref.read(webSocketServiceProvider).updateStatus('joined');
          }
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
          title: Text(
            'Swiping',
            style: GoogleFonts.fredoka(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                      radius: 20,
                    ),
                  )
                : state.movies.isEmpty
                    ? FutureBuilder<bool>(
                        future: _interactionService.recordBatchSwipesFromState(
                          userId: user?.uid ?? '',
                          state: state,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Saving your choices...'),
                                ],
                              ),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == false) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.red,
                                    size: 100,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Failed to save choices',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: const Text(
                                      'Back to Room',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.green,
                                  size: 100,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Swiping Complete!',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Back to Room',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Stack(
                        children: state.movies
                            .map((movie) => MovieCard(
                                  movie: movie,
                                  isFront: state.movies.last == movie,
                                  movieProvider: widget.movieProvider,
                                  onSwipeComplete: (status) =>
                                      _showSwipeNotification(context, status),
                                ))
                            .toList(),
                      ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    final movieState = ref.read(widget.movieProvider);
    final webSocketService = ref.read(webSocketServiceProvider);

    // Only update status if we still have movies and the service exists
    if (movieState.movies.isNotEmpty) {
      webSocketService.updateStatus('joined');
    }
    super.dispose();
  }
}
