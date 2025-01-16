import 'package:fliccsy/models/movie.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

import 'package:shimmer/shimmer.dart';

class MovieCard extends ConsumerWidget {
  final Movie movie;
  final bool isFront;
  final StateNotifierProvider<MovieNotifier, MovieState> movieProvider;

  const MovieCard({
    Key? key,
    required this.movie,
    required this.isFront,
    required this.movieProvider,
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
      onPanEnd: (_) => notifier.endDragging(size),
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
            // Bottom action buttons
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.description, color: Colors.white),
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
                    IconButton(
                      icon: const Icon(Icons.info, color: Colors.white),
                      onPressed: () {
                        // Handle info button press
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.star, color: Colors.white),
                      onPressed: () {
                        // Handle rating button press
                      },
                    ),
                  ],
                ),
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
