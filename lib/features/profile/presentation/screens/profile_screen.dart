import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/modal_action_tile.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _showAllInterests = false;

  static const int _interestsCollapsedLimit = 6;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .fetchDetailedProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  void _showOptionsSheet({
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required String profileUrl,
  }) {
    showReusableModalBottomSheet(
      context: context,
      title: 'Options',
      surface: surface,
      textPrimary: textPrimary,
      children: [
        ModalActionTile(
          icon: LucideIcons.settings,
          label: 'Paramètres',
          textColor: textPrimary,
          onTap: () {
            Navigator.of(context).pop();
            context.push('/settings');
          },
        ),
        const SizedBox(height: 12),
        ModalActionTile(
          icon: LucideIcons.link,
          label: 'Copier le lien du profil',
          textColor: textPrimary,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: profileUrl));
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Lien copié.')));
            }
          },
        ),
      ],
    );
  }

  // Icône associée à un centre d'intérêt (mots-clés → icône Lucide).
  IconData _interestIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('théâtre') || l.contains('theatre'))
      return LucideIcons.drama;
    if (l.contains('musique')) return LucideIcons.music;
    if (l.contains('flutter') || l.contains('code') || l.contains('dev')) {
      return LucideIcons.codeXml;
    }
    if (l.contains('lecture') || l.contains('livre'))
      return LucideIcons.bookOpen;
    if (l.contains('marketing')) return LucideIcons.megaphone;
    if (l.contains('science')) return LucideIcons.flaskConical;
    if (l.contains('sport') || l.contains('fitness'))
      return LucideIcons.dumbbell;
    if (l.contains('voyage')) return LucideIcons.plane;
    if (l.contains('cuisine') || l.contains('food'))
      return LucideIcons.utensils;
    if (l.contains('cinéma') || l.contains('film'))
      return LucideIcons.clapperboard;
    if (l.contains('photo')) return LucideIcons.camera;
    if (l.contains('jeu') || l.contains('gaming')) return LucideIcons.gamepad2;
    return LucideIcons.sparkles;
  }

  // Couleur / icône simple par plateforme sociale.
  // NB: lucide_icons_flutter ne fournit pas de logos de marque (Instagram,
  // Snapchat, TikTok...), donc on utilise des icônes génériques + la couleur
  // de marque pour les distinguer visuellement.
  ({Color color, IconData icon}) _socialStyle(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return (color: const Color(0xFFE1306C), icon: LucideIcons.camera);
      case 'snapchat':
        return (
          color: const Color(0xFFF7C600),
          icon: LucideIcons.messageCircle,
        );
      case 'tiktok':
        return (color: const Color(0xFF000000), icon: LucideIcons.music);
      default:
        return (color: const Color(0xFF999999), icon: LucideIcons.link);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondary = isDark
        ? AppColors.secondaryDark
        : AppColors.secondaryLight;

    final firstName = (_profile?['first_name'] as String?) ?? 'Ton profil';
    final username = (_profile?['username'] as String?) ?? '@username';
    final bio =
        (_profile?['bio'] as String?) ?? 'Ajoute une bio pour te présenter.';
    final location =
        (_profile?['location_label'] as String?) ??
        'Localisation non renseignée';
    final gender = (_profile?['gender'] as String?) ?? 'Non renseigné';
    final socials =
        (_profile?['socials'] as List<dynamic>? ?? const <dynamic>[]);
    final interests =
        (_profile?['interests'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => e.toString())
            .toList();
    final photos = (_profile?['photos'] as List<dynamic>? ?? const <dynamic>[]);
    final profileUrl =
        'https://lolango.app/u/${username.replaceFirst('@', '')}';

    final photoUrls = <String>[];
    for (final photo in photos) {
      if (photo is Map<String, dynamic>) {
        final url = photo['url'] as String?;
        if (url != null && url.isNotEmpty) photoUrls.add(url);
      } else if (photo is String && photo.isNotEmpty) {
        photoUrls.add(photo);
      }
    }
    final primaryPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;

    int? age;
    final birthDateRaw = _profile?['birth_date'];
    if (birthDateRaw is String && birthDateRaw.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateRaw);
        final now = DateTime.now();
        age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age -= 1;
        }
      } catch (_) {
        age = null;
      }
    }

    final visibleInterests = _showAllInterests
        ? interests
        : interests.take(_interestsCollapsedLimit).toList();
    final hasMoreInterests =
        !_showAllInterests && interests.length > _interestsCollapsedLimit;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // EN-TÊTE FIXE : "Mon profil" + bouton Options
            // ==================================================
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              decoration: BoxDecoration(
                color: background,
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mon profil',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showOptionsSheet(
                      surface: surface,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      profileUrl: profileUrl,
                    ),
                    icon: Icon(LucideIcons.menu, color: textPrimary),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENU DÉFILANT
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // AVATAR + NOM + INFOS (localisation | genre | âge)
                    // ==================================================
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(48),
                            child:
                                primaryPhotoUrl != null &&
                                    primaryPhotoUrl.isNotEmpty
                                ? Image.network(
                                    primaryPhotoUrl,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _AvatarInitial(
                                          letter: firstName.isNotEmpty
                                              ? firstName[0].toUpperCase()
                                              : 'L',
                                        ),
                                  )
                                : _AvatarInitial(
                                    letter: firstName.isNotEmpty
                                        ? firstName[0].toUpperCase()
                                        : 'L',
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            firstName,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            username,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Ligne infos avec icônes séparées par des "|"
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (location.isNotEmpty &&
                                  location != 'Localisation non renseignée')
                                _InfoPill(
                                  icon: LucideIcons.mapPin,
                                  label: location,
                                  color: textSecondary,
                                ),
                              if (gender != 'Non renseigné') ...[
                                _InfoDivider(color: border),
                                _InfoPill(
                                  icon: LucideIcons.user,
                                  label: gender,
                                  color: textSecondary,
                                ),
                              ],
                              if (age != null) ...[
                                _InfoDivider(color: border),
                                _InfoPill(
                                  icon: LucideIcons.cake,
                                  label: '$age ans',
                                  color: textSecondary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ==================================================
                    // BOUTON MODIFIER LE PROFIL (outline, façon capture)
                    // ==================================================
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/profile-edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textPrimary,
                          side: BorderSide(color: border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text(
                          'Modifier le profil',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // PHOTOS — GALERIE EN MOSAÏQUE "BENTO"
                    // 1 grande photo principale + 3 petites à côté.
                    // Les emplacements vides sont comblés par une carte "+".
                    // ==================================================
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text(
                          'Photos',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (photoUrls.length > 4)
                          GestureDetector(
                            onTap: () => context.push('/profile-photos'),
                            child: Text(
                              'Voir tout',
                              style: TextStyle(
                                color: secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _PhotoGallery(
                      photoUrls: photoUrls,
                      surface: surface,
                      border: border,
                      primary: primary,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onAddPhoto: () => context.push('/profile-photos'),
                      onTapPhoto: (_) => context.push('/profile-photos'),
                      isDark: isDark,
                    ),

                    // ==================================================
                    // BIO — avec guillemets décoratifs (façon capture)
                    // ==================================================
                    const SizedBox(height: 24),
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
                      padding: const EdgeInsets.fromLTRB(20, 22, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: -6,
                            top: -14,
                            child: Text(
                              '\u201C',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                color: secondary.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
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
                      ),
                    ),

                    // ==================================================
                    // CENTRES D'INTÉRÊT — chips avec icônes + "Voir plus"
                    // ==================================================
                    if (interests.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        "Centres d'intérêt",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...visibleInterests.map(
                            (interest) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (hasMoreInterests)
                            GestureDetector(
                              onTap: () => setState(() => _showAllInterests = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Text(
                                  'Voir plus',
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    // ==================================================
                    // RÉSEAUX SOCIAUX — ligne avec bouton flèche circulaire
                    // ==================================================
                    if (socials.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Réseaux sociaux',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: List.generate(socials.length, (index) {
                            final map = socials[index] as Map<String, dynamic>;
                            final platform = map['platform'] as String? ?? '';
                            final socialUsername = map['username'] as String? ?? '';
                            if (platform.isEmpty || socialUsername.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final style = _socialStyle(platform);
                            final isLast = index == socials.length - 1;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: style.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(style.icon, color: style.color, size: 14),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              platform,
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              socialUsername,
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.chevronRight, size: 18, color: textSecondary),
                                    ],
                                  ),
                                ),
                                if (!isLast)
                                  Divider(height: 1, thickness: 1, color: border, indent: 56),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> photoUrls;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onTapPhoto;
  final bool isDark;

  const _PhotoGallery({
    required this.photoUrls,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.onAddPhoto,
    required this.onTapPhoto,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const double galleryHeight = 264;
    const double gap = 8;

    if (photoUrls.isEmpty) {
      return _AddPhotoTile(
        surface: surface,
        border: border,
        primary: primary,
        height: 140,
        onTap: onAddPhoto,
        isDark: isDark,
      );
    }

    final hasSecondPhoto = photoUrls.length > 1;

    return SizedBox(
      height: galleryHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _PhotoTile(
              url: photoUrls[0],
              border: border,
              surface: surface,
              badgeLabel: 'Photo principale',
              badgeSurface: surface,
              badgeText: textPrimary,
              onTap: () => onTapPhoto(0),
            ),
          ),
          const SizedBox(width: gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _AddPhotoTile(
                    surface: surface,
                    border: border,
                    primary: primary,
                    onTap: onAddPhoto,
                    isDark: isDark,
                  ),
                ),
                if (hasSecondPhoto) ...[
                  const SizedBox(height: gap),
                  Expanded(
                    child: _PhotoTile(
                      url: photoUrls[1],
                      border: border,
                      surface: surface,
                      onTap: () => onTapPhoto(1),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final Color border;
  final Color surface;
  final String? badgeLabel;
  final Color? badgeSurface;
  final Color? badgeText;
  final VoidCallback onTap;

  const _PhotoTile({
    required this.url,
    required this.border,
    required this.surface,
    required this.onTap,
    this.badgeLabel,
    this.badgeSurface,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1),
              ),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: surface,
                  child: Icon(LucideIcons.imageOff, color: border),
                ),
              ),
            ),
            if (badgeLabel != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
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

class _AddPhotoTile extends StatelessWidget {
  final Color surface;
  final Color border;
  final Color primary;
  final double? height;
  final VoidCallback onTap;
  final bool isDark;

  const _AddPhotoTile({
    required this.surface,
    required this.border,
    required this.primary,
    required this.onTap,
    this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 22, color: iconColor),
            const SizedBox(height: 6),
            Text(
              'Ajouter\nune photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryLight,
            fontSize: 34,
          ),
        ),
      ),
    );
  }
}

// Icône + label pour la ligne d'infos (localisation / genre / âge).
class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 14, color: color);
  }
}

// Chip pour un centre d'intérêt, avec icône optionnelle.
class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.border,
    required this.textColor,
    this.bold = false,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color border;
  final Color textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
