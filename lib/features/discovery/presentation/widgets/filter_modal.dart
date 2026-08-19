import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

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

  bool get isRestrictive {
    if (city != null && city!.trim().isNotEmpty) return true;
    if (gender != null) return true;
    if (socials.isNotEmpty) return true;
    if (ageRange.start > 18 || ageRange.end < 80) return true;
    return false;
  }
}

class FilterModal extends StatefulWidget {
  final DiscoveryFilter initial;
  final ValueChanged<DiscoveryFilter>? onFilterChanged;

  const FilterModal({
    super.key,
    required this.initial,
    this.onFilterChanged,
  });

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

  void _notifyChanged() {
    if (widget.onFilterChanged != null) {
      widget.onFilterChanged!(DiscoveryFilter(
        ageRange: _age,
        gender: _gender,
        city: _city,
        socials: _socials,
      ));
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Style partagé pour les chips
  ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: const Color(0xFFF0F0EE),
        selectedColor: AppColors.primaryLight, // jaune opaque
        disabledColor: const Color(0xFFF0F0EE),
        labelStyle: const TextStyle(
          color: Color(0xFF1F1F1F),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondarySelectedColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: Color(0xFFE0E0DE)),
        showCheckmark: false,
      );

  @override
  Widget build(BuildContext context) {
    // Return only the content; container and title are provided by the reusable modal.
    return ChipTheme(
      data: _chipTheme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Âge', style: Theme.of(context).textTheme.titleMedium),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryLight,
              thumbColor: AppColors.primaryLight,
              overlayColor: AppColors.primaryLight.withValues(alpha: 0.15),
              inactiveTrackColor: const Color(0xFFE0E0DE),
            ),
            child: RangeSlider(
              values: _age,
              min: 18,
              max: 80,
              divisions: 62,
              labels: RangeLabels(
                _age.start.round().toString(),
                _age.end.round().toString(),
              ),
              onChanged: (v) {
                setState(() => _age = v);
                _notifyChanged();
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('Sexe'),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Tous'),
                selected: _gender == null,
                onSelected: (_) {
                  setState(() => _gender = null);
                  _notifyChanged();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Femmes'),
                selected: _gender == 'female',
                onSelected: (_) {
                  setState(() => _gender = 'female');
                  _notifyChanged();
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Hommes'),
                selected: _gender == 'male',
                onSelected: (_) {
                  setState(() => _gender = 'male');
                  _notifyChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // City selection: use the real city from user profile if provided in initial
          if (widget.initial.city != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Localisation'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Dans tout le pays'),
                      selected: _city == null,
                      onSelected: (_) {
                        setState(() => _city = null);
                        _notifyChanged();
                      },
                    ),
                    ChoiceChip(
                      label: Text('Dans ma ville (${widget.initial.city})'),
                      selected: _city != null,
                      onSelected: (_) {
                        setState(() => _city = widget.initial.city);
                        _notifyChanged();
                      },
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 12),
          const Text('Réseaux sociaux'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Instagram', 'Snapchat', 'TikTok'].map((label) {
              final selected = _socials.contains(label.toLowerCase());
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _socials.add(label.toLowerCase());
                    } else {
                      _socials.remove(label.toLowerCase());
                    }
                  });
                  _notifyChanged();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
