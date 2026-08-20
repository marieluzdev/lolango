import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../viewmodels/auth_viewmodel.dart';
import '../widgets/google_account_bottom_sheet.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/app_button.dart';
import 'package:lolango_v2/core/routing/app_router.dart';

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
      ref.read(pendingFirstNameProvider.notifier).state = firstName;
      
      await viewModel.completeSignInWithGoogle(googleAccount);

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
                      AppButton(
                        label: 'Continuer avec Google',
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        isLoading: _isLoading,
                        isFullWidth: true,
                        type: AppButtonType.outline,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        prefixWidget: Image.asset(
                          'assets/icons/google.png',
                          width: 22,
                          height: 22,
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
