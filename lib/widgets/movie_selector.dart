// movie_selector.dart
import 'dart:io';

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

  Future<void> _fetchMovies([bool isSearch = false]) async {
    final selectedGenres = ref.read(genreProvider);
    final genreIds =
        selectedGenres.map((genre) => genre.id).join('&genre_ids=');
    setState(() {
      _isLoading = true;
      _movies.clear();
      _searchResults.clear();
    });

    try {
      final url_prefix =
          Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
      final url = isSearch
          ? '${url_prefix}/movies/search?query=${Uri.encodeComponent(_searchQuery!)}&page=$_currentPage'
          : '${url_prefix}/movies/discover?genre_ids=$genreIds&page=$_currentPage';

      print(url);

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;

        try {
          if (isSearch) {
            final newSearchResults = (data['results'] as List).map((movie) {
              return Movie.fromJson(movie);
            }).toList();

            setState(() {
              _searchResults = newSearchResults;
              _noSearchResults = _searchResults.isEmpty;
              _isLoading = false;
              print(
                  "Search state updated - Results count: ${_searchResults.length}");
            });
          } else {
            final newMovies = (data['results'] as List).map((movie) {
              return Movie.fromJson(movie);
            }).toList();

            setState(() {
              _movies = newMovies;
              _isLoading = false;
            });
          }
        } catch (e) {
          print("Error processing movies: $e");
          setState(() => _isLoading = false);
        }
      } else {
        print("Bad response status: ${response.statusCode}");
      }
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
                          _fetchMovies(false);
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
                  alignment: Alignment.center,
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
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final isSearchActive =
                  _searchQuery != null && _searchQuery!.isNotEmpty;
              final displayList = isSearchActive ? _searchResults : _movies;

              if (displayList.isEmpty) {
                return Center(
                  child: Text(isSearchActive
                      ? 'No results found'
                      : 'No movies available'),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 260,
                ),
                itemCount: displayList.length,
                itemBuilder: (context, index) {
                  try {
                    final movie = displayList[index];
                    return _MovieCard(movie: movie);
                  } catch (e) {
                    print("Error building movie at index $index: $e");
                    return const SizedBox.shrink();
                  }
                },
              );
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
    final year = movie.year;

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
                  image: NetworkImage(
                      'https://image.tmdb.org/t/p/original${movie.backdropPath}'),
                  fit: BoxFit.cover,
                ),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 40, // Fixed height for title area
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${movie.title} (${year?.toString() ?? 'N/A'})',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
