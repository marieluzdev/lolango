import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppErrorState extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  /// Si renseigné, un countdown s'affiche et `onRetry` est appelé automatiquement
  /// après [autoRetrySeconds] secondes.
  final int? autoRetrySeconds;

  const AppErrorState({
    super.key,
    this.title = 'Oups, une erreur est survenue',
    required this.message,
    required this.onRetry,
    this.autoRetrySeconds,
  });

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoRetrySeconds != null && widget.autoRetrySeconds! > 0) {
      _remaining = widget.autoRetrySeconds!;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        timer.cancel();
        widget.onRetry();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
              child: Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: isDark ? AppColors.errorDark : AppColors.errorLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            AppButton(
              onPressed: widget.onRetry,
              icon: LucideIcons.refreshCw,
              label: _remaining > 0 ? 'Réessayer (${_remaining}s)' : 'Réessayer',
              type: AppButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }
}

