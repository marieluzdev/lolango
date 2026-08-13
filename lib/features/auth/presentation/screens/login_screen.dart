

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_account_bottom_sheet.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final viewModel = ref.read(authViewModelProvider.notifier);

      final googleAccount = await viewModel.authenticateWithGoogle();

      if (googleAccount == null || !mounted) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final confirmed = await GoogleAccountBottomSheet.show(
        context,
        account: googleAccount,
      );

      if (confirmed != true) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final firstName = viewModel.getGoogleFirstName(googleAccount);
      await viewModel.completeSignInWithGoogle(googleAccount);

      if (mounted) {
        final safeFirstName = firstName.trim();
        final route = safeFirstName.isEmpty
            ? '/onboarding'
            : '/onboarding?firstName=${Uri.encodeComponent(safeFirstName)}';
        context.go(route);
      }

      // Pas besoin de remettre _isLoading à false :
      // la navigation vers l'écran suivant va détruire ce widget.
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ============================================================
            // IMAGE
            // ============================================================
            Expanded(
              flex: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/login.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),

                  // Fondu vers le background en bas de l'image
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            backgroundColor.withValues(alpha: 0.0),
                            backgroundColor.withValues(alpha: 0.85),
                            backgroundColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // CONTENU
            // ============================================================
            Expanded(
              flex: 38,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),

                      // ==================================================
                      // TITRE
                      // ==================================================
                      Text(
                        'Bienvenue sur Lolango',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.7,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // DESCRIPTION
                      // ==================================================
                      Text(
                        'Découvrez de nouveaux profils et faites des '
                        'rencontres authentiques.\n\n'
                        'Connectez-vous, échangez vos passions et '
                        'partagez vos réseaux en toute sécurité.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==================================================
                      // BOUTON GOOGLE
                      // ==================================================
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: surface,
                            foregroundColor: textPrimary,
                            disabledBackgroundColor: surface,
                            disabledForegroundColor: textPrimary.withValues(
                              alpha: 0.5,
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      primary,
                                    ),
                                  ),
                                )
                              else
                                Image.asset(
                                  'assets/icons/google.png',
                                  width: 22,
                                  height: 22,
                                ),

                              const SizedBox(width: 12),

                              Text(
                                _isLoading
                                    ? 'Connexion en cours…'
                                    : 'Continuer avec Google',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ==================================================
                      // ERREUR
                      // ==================================================
                      if (authState.hasError) ...[
                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: errorColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authState.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: errorColor, fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
