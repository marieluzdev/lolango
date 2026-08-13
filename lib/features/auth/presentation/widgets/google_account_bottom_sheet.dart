import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

/// Bottom modal affichant l'adresse mail du compte Google sélectionné,
/// pour confirmation avant de finaliser la connexion Supabase.
class GoogleAccountBottomSheet extends StatelessWidget {
  final GoogleSignInAccount account;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const GoogleAccountBottomSheet({
    super.key,
    required this.account,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required GoogleSignInAccount account,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => GoogleAccountBottomSheet(
        account: account,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Container(
      color: surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 32,
                backgroundColor: primary.withValues(alpha: 0.15),
                backgroundImage: account.photoUrl != null
                    ? NetworkImage(account.photoUrl!)
                    : null,
                child: account.photoUrl == null
                    ? Text(
                        (account.displayName?.isNotEmpty ?? false)
                            ? account.displayName![0].toUpperCase()
                            : account.email[0].toUpperCase(),
                        style: TextStyle(fontSize: 24, color: primary),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                account.displayName ?? account.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                account.email,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuer avec ce compte'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: textSecondary),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
