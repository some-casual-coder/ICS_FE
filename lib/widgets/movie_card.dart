import 'package:fliccsy/models/movie.dart';
import 'package:fliccsy/models/movie_state.dart';
import 'package:fliccsy/providers/movie_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

class MovieCard extends ConsumerWidget {
  final Movie movie;
  final bool isFront;

  const MovieCard({
    Key? key,
    required this.movie,
    required this.isFront,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isFront) return _buildCard();

    final state = ref.watch(movieStateProvider);
    final notifier = ref.read(movieStateProvider.notifier);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onPanStart: notifier.startDragging,
      onPanUpdate: (details) => notifier.updatePosition(details, size),
      onPanEnd: (_) => notifier.endDragging(size),
      child: AnimatedContainer(
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: state.isDragging ? 0 : 400),
        transform: _calculateMatrix(state, size),
        child: _buildCard(),
      ),
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

  Widget _buildCard() {
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
            Image.network(
              movie.imageUrl,
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: const Alignment(-0.3, 0),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
