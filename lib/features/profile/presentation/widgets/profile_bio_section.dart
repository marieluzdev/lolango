import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class ProfileBioSection extends StatelessWidget {
  final String bio;

  const ProfileBioSection({super.key, required this.bio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondary = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bio',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            bio,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
