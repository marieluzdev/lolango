import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class ProfileInterestsSection extends StatefulWidget {
  final List<String> interests;

  const ProfileInterestsSection({
    super.key,
    required this.interests,
  });

  @override
  State<ProfileInterestsSection> createState() => _ProfileInterestsSectionState();
}

class _ProfileInterestsSectionState extends State<ProfileInterestsSection> {
  bool _showAllInterests = false;
  static const int _interestsCollapsedLimit = 6;

  @override
  Widget build(BuildContext context) {
    if (widget.interests.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final secondary = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    final visibleInterests = _showAllInterests
        ? widget.interests
        : widget.interests.take(_interestsCollapsedLimit).toList();
    final hasMoreInterests =
        !_showAllInterests && widget.interests.length > _interestsCollapsedLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Centres d'intérêt",
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...visibleInterests.map(
              (interest) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (hasMoreInterests)
              GestureDetector(
                onTap: () => setState(() => _showAllInterests = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Voir plus',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
