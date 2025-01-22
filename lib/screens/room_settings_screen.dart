import 'dart:convert';
import 'dart:io';

import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RoomSettingsPage extends StatefulWidget {
  final String roomId;
  final String roomName;

  const RoomSettingsPage({
    Key? key,
    required this.roomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<RoomSettingsPage> createState() => _RoomSettingsPageState();
}

class _RoomSettingsPageState extends State<RoomSettingsPage> {
  bool isLoading = true;
  String runtimePreference = 'medium';
  List<String> selectedLanguages = ['en'];
  double minRating = 7.0;
  RangeValues yearRange = const RangeValues(1970, 2024);
  final List<String> availableLanguages = [
    'en',
    'sw',
    'es',
    'fr',
    'de',
    'yo',
    'ig',
    'zu',
    'xh',
    'af',
  ];

  @override
  void initState() {
    super.initState();
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/rooms/${widget.roomId}/preferences'
        : 'http://localhost:8000/rooms/${widget.roomId}/preferences';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['preferences'] != null) {
          setState(() {
            runtimePreference =
                data['preferences']['runtime_preference'] ?? 'medium';
            selectedLanguages = List<String>.from(
                data['preferences']['language_preference'] ?? ['en']);
            minRating = (data['preferences']['min_rating'] ?? 7.0).toDouble();
            final yearRangeData =
                data['preferences']['release_year_range'] ?? [1970, 2024];
            yearRange = RangeValues(
              yearRangeData[0].toDouble(),
              yearRangeData[1].toDouble(),
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preferences: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updatePreferences() async {
    final url = Platform.isAndroid
        ? 'http://10.0.2.2:8000/rooms/${widget.roomId}/preferences'
        : 'http://localhost:8000/rooms/${widget.roomId}/preferences';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'runtime_preference': runtimePreference,
          'language_preference': selectedLanguages,
          'min_rating': minRating,
          'release_year_range': [
            yearRange.start.round(),
            yearRange.end.round()
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update preferences');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.fredoka(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.fredoka(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Runtime Preference
            const Text(
              'Movie Length Preference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'short', label: Text('Short')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'long', label: Text('Long')),
              ],
              selected: {runtimePreference},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return AppColors.primaryAccent.withOpacity(0.1);
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primaryAccent;
                    }
                    return AppColors.primary;
                  },
                ),
              ),
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  runtimePreference = selection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Language Selection
            const Text(
              'Languages',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: availableLanguages.map((lang) {
                return FilterChip(
                  label: Text(lang.toUpperCase()),
                  selected: selectedLanguages.contains(lang),
                  selectedColor: AppColors.primaryAccent,
                  checkmarkColor: AppColors.primary,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedLanguages.add(lang);
                      } else {
                        selectedLanguages.remove(lang);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Minimum Rating
            const Text(
              'Minimum Rating',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: minRating,
              min: 0,
              max: 10,
              divisions: 20,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primaryAccent.withOpacity(0.3),
              label: minRating.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  minRating = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Release Year Range
            const Text(
              'Release Year Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: yearRange,
              min: 1900,
              max: 2024,
              divisions: 124,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primaryAccent.withOpacity(0.3),
              labels: RangeLabels(
                yearRange.start.round().toString(),
                yearRange.end.round().toString(),
              ),
              onChanged: (values) {
                setState(() {
                  yearRange = values;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
