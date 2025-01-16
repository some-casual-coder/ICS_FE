import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
  String runtimePreference = 'medium';
  List<String> selectedLanguages = ['en'];
  double minRating = 7.0;
  RangeValues yearRange = const RangeValues(1970, 2024);
  final List<String> availableLanguages = [
    'en',
    'es',
    'fr',
    'de',
    'it',
    'ja',
    'ko',
    'zh'
  ];

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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.roomName} Settings'),
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

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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
