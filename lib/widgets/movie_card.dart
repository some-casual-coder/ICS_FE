import 'package:fliccsy/models/movie.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:fliccsy/widgets/swipe_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:shimmer/shimmer.dart';

class MovieCard extends ConsumerWidget {
  final Movie movie;
  final bool isFront;
  final StateNotifierProvider<MovieNotifier, MovieState> movieProvider;
  final Function(SwipeStatus) onSwipeComplete;

  const MovieCard({
    Key? key,
    required this.movie,
    required this.isFront,
    required this.movieProvider,
    required this.onSwipeComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isFront) return _buildCard(context);
    final state = ref.watch(movieProvider);
    final notifier = ref.read(movieProvider.notifier);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onPanStart: notifier.startDragging,
      onPanUpdate: (details) => notifier.updatePosition(details, size),
      onPanEnd: (_) => notifier.endDragging(size, onSwipeComplete),
      child: AnimatedContainer(
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: state.isDragging ? 0 : 400),
        transform: _calculateMatrix(state, size),
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Image with shimmer loading
            Image.network(
              movie.imageUrl,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: const Alignment(-0.3, 0),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              },
            ),

// Bottom action buttons with gradient and container
            Positioned(
              bottom: 16, // Moved up slightly from the bottom
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient background that extends upward
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black
                              .withOpacity(0.4), // Stronger opacity at bottom
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.8], // Gradient extends higher up
                      ),
                    ),
                    height: 100, // Adjust based on your needs
                  ),
                  // Action buttons container
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.75), // Slightly transparent
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.description,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      _buildDescriptionDrawer(context),
                                );
                              },
                            ),
                            Text(
                              'Overview',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.swipe_rounded,
                                color: Colors.blue[300],
                                size: 28,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (context) => SwipeTutorialOverlay(
                                    onClose: () => Navigator.of(context).pop(),
                                  ),
                                );
                              },
                            ),
                            Text(
                              'How to Use',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.star,
                                    color: Colors.orange[400],
                                    size: 28,
                                  ),
                                  onPressed: () {},
                                ),
                                Text(
                                  movie.rating != null
                                      ? "${movie.rating!.toStringAsFixed(1)}/10"
                                      : "None",
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Movie title at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionDrawer(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.75,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                movie.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(
                    movie.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Matrix4 _calculateMatrix(MovieState state, Size size) {
    final center = size.center(Offset.zero);
    final angle = state.angle * math.pi / 180;
    return Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(angle)
      ..translate(-center.dx, -center.dy)
      ..translate(state.position.dx, state.position.dy);
  }
}
