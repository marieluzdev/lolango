import 'package:flutter/material.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String cancelText = 'Annuler',
  String confirmText = 'Confirmer',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.errorLight)
                : null,
            child: Text(
              confirmText,
              style: destructive
                  ? const TextStyle(color: AppColors.errorLight)
                  : null,
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
