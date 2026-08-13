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
                    _PhotoBentoGrid(
                      photoUrls: photoUrls,
                      surface: surface,
                      border: border,
                      textSecondary: textSecondary,
                      primary: primary,
                      onAddPhoto: () => context.push('/profile-edit'),
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
                        color: surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border),
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
                            (interest) => _InterestChip(
                              label: interest,
                              icon: _interestIcon(interest),
                              color: surface,
                              border: border,
                              textColor: textPrimary,
                            ),
                          ),
                          if (hasMoreInterests)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showAllInterests = true),
                              child: _InterestChip(
                                label: 'Voir plus',
                                icon: null,
                                color: Colors.transparent,
                                border: Colors.transparent,
                                textColor: secondary,
                                bold: true,
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
                      ...socials.map((social) {
                        final map = social as Map<String, dynamic>;
                        final platform = map['platform'] as String? ?? '';
                        final socialUsername = map['username'] as String? ?? '';
                        if (platform.isEmpty || socialUsername.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final style = _socialStyle(platform);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: style.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  style.icon,
                                  color: style.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      platform,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
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
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.arrowRight,
                                  size: 16,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

// ==================================================
// GALERIE PHOTOS EN MOSAÏQUE "BENTO"
// 1 grande photo (principale) à gauche + 3 petites empilées à droite.
// Les slots vides deviennent des cartes "+".
// ==================================================
class _PhotoBentoGrid extends StatelessWidget {
  const _PhotoBentoGrid({
    required this.photoUrls,
    required this.surface,
    required this.border,
    required this.textSecondary,
    required this.primary,
    required this.onAddPhoto,
  });

  final List<String> photoUrls;
  final Color surface;
  final Color border;
  final Color textSecondary;
  final Color primary;
  final VoidCallback onAddPhoto;

  static const double _height = 236;
  static const double _gap = 10;
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final slots = List<String?>.generate(
      4,
      (i) => i < photoUrls.length ? photoUrls[i] : null,
    );

    return SizedBox(
      height: _height,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _BentoTile(
              url: slots[0],
              radius: _radius,
              surface: surface,
              border: border,
              textSecondary: textSecondary,
              isPrimaryBadge: slots[0] != null,
              primaryColor: primary,
              onAdd: onAddPhoto,
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _BentoTile(
                    url: slots[1],
                    radius: _radius,
                    surface: surface,
                    border: border,
                    textSecondary: textSecondary,
                    onAdd: onAddPhoto,
                    compact: true,
                  ),
                ),
                const SizedBox(height: _gap),
                Expanded(
                  child: _BentoTile(
                    url: slots[2],
                    radius: _radius,
                    surface: surface,
                    border: border,
                    textSecondary: textSecondary,
                    onAdd: onAddPhoto,
                    compact: true,
                  ),
                ),
                const SizedBox(height: _gap),
                Expanded(
                  child: _BentoTile(
                    url: slots[3],
                    radius: _radius,
                    surface: surface,
                    border: border,
                    textSecondary: textSecondary,
                    onAdd: onAddPhoto,
                    compact: true,
                    extraCount: photoUrls.length > 4
                        ? photoUrls.length - 4
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoTile extends StatelessWidget {
  const _BentoTile({
    required this.url,
    required this.radius,
    required this.surface,
    required this.border,
    required this.textSecondary,
    required this.onAdd,
    this.isPrimaryBadge = false,
    this.primaryColor,
    this.compact = false,
    this.extraCount,
  });

  final String? url;
  final double radius;
  final Color surface;
  final Color border;
  final Color textSecondary;
  final VoidCallback onAdd;
  final bool isPrimaryBadge;
  final Color? primaryColor;
  final bool compact;
  final int? extraCount;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _AddPhotoCard(
        radius: radius,
        surface: surface,
        border: border,
        textSecondary: textSecondary,
        onTap: onAdd,
        compact: compact,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: surface,
              child: Icon(LucideIcons.imageOff, color: textSecondary),
            ),
          ),
          if (isPrimaryBadge)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (primaryColor ?? Colors.amber).withValues(alpha: 0.93),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Photo principale',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (extraCount != null && extraCount! > 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({
    required this.radius,
    required this.surface,
    required this.border,
    required this.textSecondary,
    required this.onTap,
    this.compact = false,
  });

  final double radius;
  final Color surface;
  final Color border;
  final Color textSecondary;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: DottedBorderBox(
        radius: radius,
        color: border,
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: Icon(
              LucideIcons.plus,
              color: textSecondary,
              size: compact ? 18 : 26,
            ),
          ),
        ),
      ),
    );
  }
}

// Petit conteneur avec bordure en pointillés (sans dépendance externe).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.radius,
    required this.color,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(radius: radius, color: color),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 5, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(
    Path source, {
    required double dashLength,
    required double gapLength,
  }) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final next = (distance + length).clamp(0, metric.length).toDouble();
        if (draw) {
          dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
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
