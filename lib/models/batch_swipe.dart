enum SwipeAction { interested, watched_liked, not_interested, not_sure }

class BatchSwipe {
  final String movieId;
  final SwipeAction action;

  BatchSwipe({
    required this.movieId,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'movie_id': movieId,
        'action': action.toString().split('.').last,
      };
}
