import 'package:fliccsy/providers/preferences_provider.dart';
import 'package:fliccsy/screens/onboarding/onboarding_screen.dart';
import 'package:fliccsy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferencesSelector extends ConsumerWidget {
  const PreferencesSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(preferencesProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Runtime Section
            PreferenceSection(
              title: 'Runtime',
              options: const ['Short', 'Medium', 'Long'],
              selectedOptions: preferences.movieLength,
              onOptionSelected: (option) {
                ref
                    .read(preferencesProvider.notifier)
                    .toggleMovieLength(option.toLowerCase());
              },
              descriptions: const {
                'Short': '< 90 min',
                'Medium': '90-120 min',
                'Long': '> 150 min',
              },
              showDivider: true,
            ),

            const SizedBox(height: 24),

            // Era Section
            PreferenceSection(
              title: 'Preferred era',
              options: const ['Classics', '2000s', '2010s', 'Recent'],
              selectedOptions: preferences.preferredEras,
              onOptionSelected: (option) {
                ref
                    .read(preferencesProvider.notifier)
                    .togglePreferredEra(option.toLowerCase());
              },
              showDivider: true,
            ),

            const SizedBox(height: 24),

            // Locality Section
            PreferenceSection(
              title: 'Locality',
              options: const ['Local', 'International', 'Both'],
              selectedOptions: preferences.languagePreference != null
                  ? [preferences.languagePreference!]
                  : [],
              onOptionSelected: (option) {
                ref
                    .read(preferencesProvider.notifier)
                    .setLanguagePreference(option.toLowerCase());
              },
              showDivider: false,
              singleSelect: true,
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final List<String> selectedOptions;
  final Function(String) onOptionSelected;
  final Map<String, String>? descriptions;
  final bool showDivider;
  final bool singleSelect;

  const PreferenceSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOptions,
    required this.onOptionSelected,
    this.descriptions,
    this.showDivider = true,
    this.singleSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Fredoka',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option.toLowerCase());
            return PreferenceButton(
              label: option,
              isSelected: isSelected,
              onPressed: () => onOptionSelected(option),
            );
          }).toList(),
        ),
        if (descriptions != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: descriptions!.entries.map((entry) {
              return Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              );
            }).toList(),
          ),
        ],
        if (showDivider) ...[
          const SizedBox(height: 16),
          CustomPaint(
            size: const Size(double.infinity, 2),
            painter: DottedLinePainter(color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}

class PreferenceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const PreferenceButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
    );
  }
}
