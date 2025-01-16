import 'dart:io';

import 'package:fliccsy/models/genre.dart';
import 'package:fliccsy/providers/genre_provider.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GenreSelector extends ConsumerStatefulWidget {
  const GenreSelector({super.key});

  @override
  ConsumerState<GenreSelector> createState() => _GenreSelectorState();
}

class _GenreSelectorState extends ConsumerState<GenreSelector> {
  List<Genre> _availableGenres = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGenres();
  }

  Future<void> _fetchGenres() async {
    try {
      final url = Platform.isAndroid
          ? 'http://10.0.2.2:8000/genres'
          : 'http://localhost:8000/genres';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _availableGenres = (data['genres'] as List)
              .map((genre) => Genre.fromJson(genre))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Future<void> _fetchGenres() async {
  //   // Simulate API delay
  //   await Future.delayed(const Duration(milliseconds: 800));

  //   final dummyGenres = {
  //     "genres": [
  //       {"id": 28, "name": "Action"},
  //       {"id": 12, "name": "Adventure"},
  //       {"id": 16, "name": "Animation"},
  //       {"id": 35, "name": "Comedy"},
  //       {"id": 80, "name": "Crime"},
  //       {"id": 99, "name": "Documentary"},
  //       {"id": 18, "name": "Drama"},
  //       {"id": 10751, "name": "Family"},
  //       {"id": 14, "name": "Fantasy"},
  //       {"id": 36, "name": "History"},
  //       {"id": 27, "name": "Horror"},
  //       {"id": 10402, "name": "Music"},
  //       {"id": 9648, "name": "Mystery"},
  //       {"id": 10749, "name": "Romance"},
  //       {"id": 878, "name": "Science Fiction"},
  //       {"id": 10770, "name": "TV Movie"},
  //       {"id": 53, "name": "Thriller"},
  //       {"id": 10752, "name": "War"},
  //       {"id": 37, "name": "Western"}
  //     ]
  //   };

  //   setState(() {
  //     _availableGenres = (dummyGenres['genres'] as List)
  //         .map((genre) => Genre.fromJson(genre as Map<String, dynamic>))
  //         .toList();
  //     _isLoading = false;
  //   });
  // }

  void _selectGenre(Genre genre) {
    setState(() {
      _availableGenres.remove(genre);
    });
    ref.read(genreProvider.notifier).addGenre(genre);
  }

  void _removeGenre(Genre genre) {
    setState(() {
      _availableGenres.add(genre);
    });
    ref.read(genreProvider.notifier).removeGenre(genre);
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenres = ref.watch(genreProvider);
    return Column(
      children: [
        if (selectedGenres.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(1),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedGenres
                  .map((genre) => _buildSelectedGenreChip(genre))
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableGenres
                          .map((genre) => _buildGenreButton(genre))
                          .toList(),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreButton(Genre genre) {
    return OutlinedButton(
      onPressed: () => _selectGenre(genre),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        genre.name,
        style: GoogleFonts.roboto(
          color: Colors.grey.shade700,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildSelectedGenreChip(Genre genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            genre.name,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeGenre(genre),
            child: const Icon(
              Icons.close,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
