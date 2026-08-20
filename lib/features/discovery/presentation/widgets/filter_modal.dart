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
  final String? userCity;
  final ValueChanged<DiscoveryFilter>? onFilterChanged;

  const FilterModal({
    super.key,
    required this.initial,
    this.userCity,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    // Return only the content; container and title are provided by the reusable modal.
    return Column(
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterButton(
              label: 'Tous',
              isSelected: _gender == null,
              onTap: () {
                setState(() => _gender = null);
                _notifyChanged();
              },
              textPrimary: textPrimary,
              surface: surface,
              border: border,
              primary: primary,
            ),
            _buildFilterButton(
              label: 'Femmes',
              isSelected: _gender == 'female',
              onTap: () {
                setState(() => _gender = 'female');
                _notifyChanged();
              },
              textPrimary: textPrimary,
              surface: surface,
              border: border,
              primary: primary,
            ),
            _buildFilterButton(
              label: 'Hommes',
              isSelected: _gender == 'male',
              onTap: () {
                setState(() => _gender = 'male');
                _notifyChanged();
              },
              textPrimary: textPrimary,
              surface: surface,
              border: border,
              primary: primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // City selection: use the real city from user profile if provided in initial
        if (widget.userCity != null && widget.userCity!.trim().isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Localisation'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFilterButton(
                    label: 'Dans tout le pays',
                    isSelected: _city == null,
                    onTap: () {
                      setState(() => _city = null);
                      _notifyChanged();
                    },
                    textPrimary: textPrimary,
                    surface: surface,
                    border: border,
                    primary: primary,
                  ),
                  _buildFilterButton(
                    label: 'Dans ma ville',
                    isSelected: _city != null,
                    onTap: () {
                      setState(() => _city = widget.userCity);
                      _notifyChanged();
                    },
                    textPrimary: textPrimary,
                    surface: surface,
                    border: border,
                    primary: primary,
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
          runSpacing: 8,
          children: ['Instagram', 'Snapchat', 'TikTok'].map((label) {
            final selected = _socials.contains(label.toLowerCase());
            return _buildFilterButton(
              label: label,
              isSelected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    _socials.remove(label.toLowerCase());
                  } else {
                    _socials.add(label.toLowerCase());
                  }
                });
                _notifyChanged();
              },
              textPrimary: textPrimary,
              surface: surface,
              border: border,
              primary: primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color surface,
    required Color border,
    required Color primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primary : surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
