import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class AppLoading extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const AppLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Skeletonizer(
      enabled: enabled,
      effect: ShimmerEffect(
        baseColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        highlightColor: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
      child: child,
    );
  }
}

// A simple loading indicator if skeletonizer is not applicable
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          isDark ? AppColors.primaryDark : AppColors.primaryLight,
        ),
      ),
    );
  }
}
