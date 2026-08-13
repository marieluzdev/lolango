import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 64,
              color: textPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenue sur Home',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
