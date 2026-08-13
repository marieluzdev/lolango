import 'package:flutter/material.dart';

class DiscoveryFilter {
  final RangeValues ageRange;
  final String? gender; // 'male'|'female'|null
  final String? city;
  final Set<String> socials;

  DiscoveryFilter({
    required this.ageRange,
    this.gender,
    this.city,
    Set<String>? socials,
  }) : socials = socials ?? {}; 
}

class FilterModal extends StatefulWidget {
  final DiscoveryFilter initial;

  const FilterModal({super.key, required this.initial});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late RangeValues _age;
  String? _gender;
  String? _city;
  final Set<String> _socials = {};

  @override
  void initState() {
    super.initState();
    _age = widget.initial.ageRange;
    _gender = widget.initial.gender;
    _city = widget.initial.city;
    _socials.addAll(widget.initial.socials);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return only the content; container and title are provided by the reusable modal.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Âge', style: Theme.of(context).textTheme.titleMedium),
        RangeSlider(
          values: _age,
          min: 18,
          max: 80,
          divisions: 62,
          labels: RangeLabels(_age.start.round().toString(), _age.end.round().toString()),
          onChanged: (v) => setState(() => _age = v),
        ),
        const SizedBox(height: 8),
        Text('Sexe'),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Tous'),
              selected: _gender == null,
              onSelected: (_) => setState(() => _gender = null),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Femmes'),
              selected: _gender == 'female',
              onSelected: (_) => setState(() => _gender = 'female'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Hommes'),
              selected: _gender == 'male',
              onSelected: (_) => setState(() => _gender = 'male'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // City selection: use the real city from user profile if provided in initial
        if (_city != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ville'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Toutes les villes'),
                    selected: _city == null,
                    onSelected: (_) => setState(() => _city = null),
                  ),
                  ChoiceChip(
                    label: Text(_city!),
                    selected: _city != null,
                    onSelected: (_) => setState(() => _city = widget.initial.city),
                  ),
                ],
              ),
            ],
          )
        else
          const SizedBox.shrink(),
        const SizedBox(height: 12),
        Text('Réseaux sociaux'),
        Wrap(
          spacing: 8,
          children: ['Instagram', 'Snapchat', 'TikTok'].map((label) {
            final selected = _socials.contains(label.toLowerCase());
            return FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (v) => setState(() {
                if (v) {
                  _socials.add(label.toLowerCase());
                } else {
                  _socials.remove(label.toLowerCase());
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final res = DiscoveryFilter(
                  ageRange: _age,
                  gender: _gender,
                  city: _city,
                  socials: _socials,
                );
                Navigator.of(context).pop(res);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ],
    );
  }
}
