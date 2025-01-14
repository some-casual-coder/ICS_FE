class Movie {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String releaseDate;
  final double? rating;

  const Movie({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.releaseDate,
    this.rating,
  });

  Movie copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? description,
    String? releaseDate,
    double? rating,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
    );
  }
}
