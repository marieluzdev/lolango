import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

/// Affiche un modal de confirmation réutilisable avec le même design que le modal options
Future<bool> showConfirmationModalBottomSheet({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = 'Annuler',
  String confirmText = 'Confirmer',
  bool destructive = false,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(sheetContext).padding.bottom + 16,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    icon: Icon(Icons.close, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(color: textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: destructive ? Colors.red : AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  return result ?? false;
}
