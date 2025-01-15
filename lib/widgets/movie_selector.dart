// movie_selector.dart
import 'package:fliccsy/providers/genre_provider.dart';
import 'package:fliccsy/providers/movie_provider.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieSelector extends ConsumerStatefulWidget {
  const MovieSelector({super.key});

  @override
  ConsumerState<MovieSelector> createState() => _MovieSelectorState();
}

class _MovieSelectorState extends ConsumerState<MovieSelector> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();
  }

  int _currentPage = 1;
  String? _searchQuery;
  List<Movie> _searchResults = [];
  bool _noSearchResults = false;

  // Future<void> _fetchMovies([bool isSearch = false]) async {
  //   final selectedGenres = ref.read(genreProvider);
  //   final genreIds =
  //       selectedGenres.map((genre) => genre.id).join('&genre_ids=');

  //   try {
  //     final url = isSearch
  //         ? 'http://localhost:8000/movies/search?query=${Uri.encodeComponent(_searchQuery!)}&page=$_currentPage'
  //         : 'http://localhost:8000/movies/discover?$genreIds&page=$_currentPage';

  //     final response = await http.get(
  //       Uri.parse(url),
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       setState(() {
  //         if (isSearch) {
  //           _searchResults = (data['result'] as List)
  //               .map((movie) => Movie.fromJson(movie))
  //               .toList();
  //           _noSearchResults = _searchResults.isEmpty;
  //         } else {
  //           _movies = (data['result'] as List)
  //               .map((movie) => Movie.fromJson(movie))
  //               .toList();
  //         }
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _fetchMovies([bool isSearch = false]) async {
    final selectedGenres = ref.read(genreProvider);
    final genreIds =
        selectedGenres.map((genre) => genre.id).join('&genre_ids=');

    try {
      // Simulate API call for now
      await Future.delayed(Duration(seconds: 1));

      final dummyResponse = isSearch
          ? {
              "page": 1,
              "result": _searchQuery == "noresults"
                  ? []
                  : [
                      {
                        "id": 3,
                        "backdrop_path":
                            "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                        "title": "Search Result: $_searchQuery",
                        "release_date": "2024-01-15"
                      },
                      {
                        "id": 4,
                        "backdrop_path":
                            "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                        "title": "Another $_searchQuery Movie",
                        "release_date": "2023-12-25"
                      },
                    ]
            }
          : {
              "page": 1,
              "result": [
                {
                  "id": 1,
                  "backdrop_path":
                      "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                  "title": "Movie 1",
                  "release_date": "2024-01-15"
                },
                {
                  "id": 2,
                  "backdrop_path":
                      "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                  "title": "Movie 2",
                  "release_date": "2023-12-20"
                },
                {
                  "id": 5,
                  "backdrop_path":
                      "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                  "title": "Movie 3",
                  "release_date": "2023-11-15"
                },
                {
                  "id": 6,
                  "backdrop_path":
                      "https://m.media-amazon.com/images/I/A1PaCX4oXjL.jpg",
                  "title": "Movie 4",
                  "release_date": "2023-10-10"
                },
              ]
            };

      setState(() {
        if (isSearch) {
          _searchResults = (dummyResponse['result'] as List)
              .map((movie) => Movie.fromJson(movie))
              .toList();
          _noSearchResults = _searchResults.isEmpty;
        } else {
          _movies = (dummyResponse['result'] as List)
              .map((movie) => Movie.fromJson(movie))
              .toList();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMovies = ref.watch(selectedMoviesProvider);
    final progress = selectedMovies.length / 10; // Assuming 10 is max

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search movies...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          BorderSide(color: AppColors.primary, width: 2.0),
                    ),
                    contentPadding: EdgeInsets.only(left: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _searchController.text.isEmpty
                            ? Icons.search
                            : Icons.clear,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = null;
                            _searchResults.clear();
                            _noSearchResults = false;
                          });
                        }
                      },
                    ),
                  ),
                  onSubmitted: (query) {
                    if (query.isEmpty) {
                      setState(() {
                        _searchQuery = null;
                        _searchResults.clear();
                        _noSearchResults = false;
                      });
                    } else {
                      setState(() {
                        _searchQuery = query;
                        _isLoading = true;
                      });
                      _fetchMovies(true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center, // Ensures children are centered
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Text(
                      '${selectedMovies.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_noSearchResults)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'No results found for "$_searchQuery"',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing recommended movies instead:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 260, // Fixed height for each item
                  ),
                  itemCount: _searchResults.isNotEmpty
                      ? _searchResults.length
                      : _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _searchResults.isNotEmpty
                        ? _searchResults[index]
                        : _movies[index];
                    return _MovieCard(movie: movie);
                  },
                ),
        ),
      ],
    );
  }
}

class _MovieCard extends ConsumerWidget {
  final Movie movie;

  const _MovieCard({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected =
        ref.watch(selectedMoviesProvider.notifier).isSelected(movie);
    final year = DateTime.parse(movie.releaseDate).year;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          ref.read(selectedMoviesProvider.notifier).removeMovie(movie);
        } else {
          ref.read(selectedMoviesProvider.notifier).addMovie(movie);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(movie.backdropPath),
                  fit: BoxFit.cover,
                ),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${movie.title} ($year)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
