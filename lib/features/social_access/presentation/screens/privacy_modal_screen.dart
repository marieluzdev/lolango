import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/social_access/domain/social_visibility_model.dart';
import 'package:lolango_v2/features/social_access/providers/social_visibility_provider.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrivacyModalScreen extends ConsumerStatefulWidget {
  const PrivacyModalScreen({super.key});

  @override
  ConsumerState<PrivacyModalScreen> createState() => _PrivacyModalScreenState();
}

class _PrivacyModalScreenState extends ConsumerState<PrivacyModalScreen> {
  SocialVisibility _selectedMode = SocialVisibility.afterMatch;
  Set<String> _selectedPlatforms = {};
  List<String> _userPlatforms = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserPlatforms();
  }

  Future<void> _loadUserPlatforms() async {
    final profile = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
    if (profile != null) {
      _userPlatforms = profile.socials.keys.toList();
      _selectedPlatforms = _userPlatforms.toSet();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final notifier = ref.read(socialVisibilityProvider.notifier);
      await notifier.saveVisibility(
        _selectedMode,
        _selectedMode == SocialVisibility.selective ? _selectedPlatforms.toList() : [],
      );
      await notifier.markPrivacyModalSeen();
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondary = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    return Scaffold(
      backgroundColor: Colors.black54, // Semi-transparent backdrop
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: _isLoading
                  ? const SizedBox(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔐 Qui peut voir tes réseaux ?',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tes réseaux sont cachés par défaut.\nTu gardes le contrôle sur les personnes qui peuvent les voir.',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Option 1
                        _buildOptionCard(
                          mode: SocialVisibility.afterMatch,
                          icon: LucideIcons.lock,
                          surface: surface,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primary: primary,
                        ),
                        
                        // Option 2
                        _buildOptionCard(
                          mode: SocialVisibility.selective,
                          icon: LucideIcons.hand,
                          surface: surface,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primary: primary,
                        ),
                        
                        if (_selectedMode == SocialVisibility.selective && _userPlatforms.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                            child: Column(
                              children: _userPlatforms.map((platform) {
                                final isSelected = _selectedPlatforms.contains(platform);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedPlatforms.add(platform);
                                      } else {
                                        _selectedPlatforms.remove(platform);
                                      }
                                    });
                                  },
                                  title: Text(platform, style: TextStyle(color: textPrimary)),
                                  activeColor: primary,
                                  checkColor: Colors.black,
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              }).toList(),
                            ),
                          ),
                          
                        // Option 3
                        _buildOptionCard(
                          mode: SocialVisibility.always,
                          icon: LucideIcons.globe,
                          surface: surface,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          primary: primary,
                        ),
                        
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Tu pourras modifier ce choix à tout moment dans Paramètres.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _handleConfirm,
                            style: FilledButton.styleFrom(
                              backgroundColor: secondary,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Confirmer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required SocialVisibility mode,
    required IconData icon,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color primary,
  }) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? primary : textPrimary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        mode.label,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (mode == SocialVisibility.afterMatch) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Défaut',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                color: primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
