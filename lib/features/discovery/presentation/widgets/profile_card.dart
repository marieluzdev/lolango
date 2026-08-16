import 'package:flutter/material.dart';
import 'package:lolango_v2/core/widgets/reusable_modal_bottom_sheet.dart';
import 'package:lolango_v2/core/widgets/app_cached_image.dart';

// ---------------------------------------------------------------------------
// Helpers — design visuel par plateforme sociale
// ---------------------------------------------------------------------------

/// Retourne la décoration de fond (BoxDecoration) pour l'icône d'un réseau.
BoxDecoration _socialBgDecoration(String platform) {
  switch (platform.toLowerCase()) {
    case 'instagram':
      return const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    case 'snapchat':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFFC00),
      );
    case 'tiktok':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF010101),
      );
    case 'twitter':
    case 'x':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1DA1F2),
      );
    case 'facebook':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF1877F2),
      );
    case 'youtube':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFF0000),
      );
    case 'linkedin':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0A66C2),
      );
    case 'pinterest':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE60023),
      );
    case 'discord':
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF5865F2),
      );
    default:
      return const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF555555),
      );
  }
}

/// Retourne l'icône et la couleur d'icône pour un réseau social.
({IconData icon, Color iconColor}) _socialIconStyle(String platform) {
  switch (platform.toLowerCase()) {
    case 'instagram':
      return (icon: Icons.camera_alt, iconColor: Colors.white);
    case 'snapchat':
      return (icon: Icons.chat_bubble, iconColor: Colors.black);
    case 'tiktok':
      return (icon: Icons.music_note, iconColor: Colors.white);
    case 'twitter':
    case 'x':
      return (icon: Icons.alternate_email, iconColor: Colors.white);
    case 'facebook':
      return (icon: Icons.facebook, iconColor: Colors.white);
    case 'youtube':
      return (icon: Icons.play_arrow, iconColor: Colors.white);
    case 'linkedin':
      return (icon: Icons.work, iconColor: Colors.white);
    case 'pinterest':
      return (icon: Icons.push_pin, iconColor: Colors.white);
    case 'discord':
      return (icon: Icons.headset_mic, iconColor: Colors.white);
    default:
      return (icon: Icons.link, iconColor: Colors.white);
  }
}

// ---------------------------------------------------------------------------
// Affichage d'un badge de réseau social (icône circulaire)
// ---------------------------------------------------------------------------
class _SocialBadge extends StatelessWidget {
  const _SocialBadge({
    required this.platform,
    required this.username,
    required this.size,
    this.onTap,
  });

  final String platform;
  final String username;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _socialIconStyle(platform);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: _socialBgDecoration(platform),
        child: Icon(style.icon, color: style.iconColor, size: size * 0.48),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ProfileCard principale
// ---------------------------------------------------------------------------

class ProfileCard extends StatefulWidget {
  final String name;
  final int? age;
  final String? city;
  final String? country;

  /// Compatibilité ancienne — une seule photo. Si photoUrls est vide on l'utilise.
  final String? photoUrl;

  /// Liste complète des photos.
  final List<String>? photoUrls;

  final String? bio;
  final Map<String, String>? socials;
  final List<String>? interests;
  final VoidCallback? onPass;
  final VoidCallback? onConnect;
  final bool isGridMode;
  final bool showActionButtons;
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.name,
    this.age,
    this.city,
    this.country,
    this.photoUrl,
    this.photoUrls,
    this.bio,
    this.socials,
    this.interests,
    this.onPass,
    this.onConnect,
    this.isGridMode = false,
    this.showActionButtons = true,
    this.onTap,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Résout la liste effective de photos (compatibilité photoUrl unique).
  List<String> get _resolvedPhotoUrls {
    if (widget.photoUrls != null && widget.photoUrls!.isNotEmpty) {
      return widget.photoUrls!;
    }
    if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      return [widget.photoUrl!];
    }
    return [];
  }

  /// Nombre de photos (max 4 utilisées pour les onglets intermédiaires).
  int get _photoCount => _resolvedPhotoUrls.length;

  /// Onglets :
  ///   0 photos → 1 onglet (info seul)
  ///   1 photo  → 2 onglets (photo+info, détails)
  ///   2 photos → 3 onglets
  ///   3 photos → 4 onglets
  ///   ≥4       → 5 onglets (photos 1-4, puis détails)
  int get _tabCount {
    if (_photoCount == 0) return 1;
    if (_photoCount >= 4) return 5;
    return _photoCount + 1; // photos + 1 onglet détails
  }

  /// Photo utilisée pour un onglet donné (index 0 = onglet 1, index tabCount-1 = détails).
  String? _photoForTab(int tabIndex) {
    if (_photoCount == 0) return null;
    if (tabIndex == 0) return _resolvedPhotoUrls[0];
    if (tabIndex == _tabCount - 1)
      return _resolvedPhotoUrls[0]; // fond pour le dernier onglet
    // Onglets intermédiaires : photos 2, 3, 4
    final photoIndex = tabIndex; // tab 1 → photo index 1, tab 2 → index 2, etc.
    if (photoIndex < _resolvedPhotoUrls.length)
      return _resolvedPhotoUrls[photoIndex];
    return _resolvedPhotoUrls[0];
  }

  void _openSocialModal(
    BuildContext context,
    String platform,
    String username,
  ) {
    final theme = Theme.of(context);
    showReusableModalBottomSheet(
      context: context,
      title: platform,
      surface: theme.cardColor,
      textPrimary: theme.textTheme.bodyLarge?.color ?? Colors.black,
      children: const [SizedBox(height: 16)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGridMode) {
      return _buildGridCard(context);
    }
    return _buildSwipeCard(context);
  }

  // -------------------------------------------------------------------------
  // Carte grille (Discovery) — photo + nom/âge, pas d'onglets
  // -------------------------------------------------------------------------
  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final photos = _resolvedPhotoUrls;
    final displayName = widget.age != null
        ? '${widget.name}, ${widget.age}'
        : widget.name;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.12 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              photos.isNotEmpty
                  ? AppCachedImage(imageUrl: photos.first, fit: BoxFit.cover)
                  : _buildPlaceholder(theme),
              // Gradient bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withAlpha((0.55 * 255).round()),
                        Colors.black.withAlpha((0.90 * 255).round()),
                      ],
                      stops: const [0, 0.4, 0.7, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Carte swipable avec onglets PageView
  // -------------------------------------------------------------------------
  Widget _buildSwipeCard(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.15 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Pages
              PageView.builder(
                controller: _pageController,
                itemCount: _tabCount,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, tabIndex) {
                  final isLastTab = tabIndex == _tabCount - 1;
                  final isFirstTab = tabIndex == 0;

                  if (_tabCount == 1) {
                    // Pas de photo : onglet unique avec placeholder + infos
                    return _buildInfoTab(
                      context,
                      theme,
                      null,
                      showDetails: false,
                    );
                  }

                  if (isFirstTab) {
                    return _buildFirstTab(context, theme, _photoForTab(0));
                  }

                  if (isLastTab) {
                    return _buildDetailsTab(
                      context,
                      theme,
                      _photoForTab(tabIndex),
                    );
                  }

                  // Onglets photo intermédiaires
                  return _buildPhotoOnlyTab(theme, _photoForTab(tabIndex));
                },
              ),

              // Indicateur de dots
              if (_tabCount > 1)
                Positioned(
                  top: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_tabCount, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white.withAlpha((0.5 * 255).round()),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Onglet 1 : photo de fond + nom + âge + intérêts + réseaux + boutons
  // -------------------------------------------------------------------------
  Widget _buildFirstTab(
    BuildContext context,
    ThemeData theme,
    String? photoUrl,
  ) {
    final socials = widget.socials ?? {};
    final interests = widget.interests ?? [];
    final displayName = widget.age != null
        ? '${widget.name}, ${widget.age}'
        : widget.name;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo de fond
        photoUrl != null && photoUrl.isNotEmpty
            ? AppCachedImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : _buildPlaceholder(theme),

        // Gradient
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: MediaQuery.of(context).size.height * 0.30,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withAlpha((0.5 * 255).round()),
                  Colors.black.withAlpha((0.92 * 255).round()),
                ],
              ),
            ),
          ),
        ),

        // Contenu bas
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nom + âge
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),

                // Ville
                if (widget.city != null && widget.city!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.city!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Intérêts (3 max)
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: interests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha((0.18 * 255).round()),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withAlpha((0.35 * 255).round()),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Réseaux sociaux
                if (socials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: socials.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _SocialBadge(
                            platform: e.key,
                            username: e.value,
                            size: 44,
                            onTap: () =>
                                _openSocialModal(context, e.key, e.value),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                // Boutons passer / connecter
                if (widget.showActionButtons) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onPass,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white70,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.close, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onConnect,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFFFE3C72),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.favorite, size: 26),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Onglet photo intermédiaire — photo plein écran seule
  // -------------------------------------------------------------------------
  Widget _buildPhotoOnlyTab(ThemeData theme, String? photoUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        photoUrl != null && photoUrl.isNotEmpty
            ? AppCachedImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : _buildPlaceholder(theme),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Dernier onglet — photo 1 en fond foncé + description + pays + infos
  // -------------------------------------------------------------------------
  Widget _buildDetailsTab(
    BuildContext context,
    ThemeData theme,
    String? photoUrl,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo de fond
        photoUrl != null && photoUrl.isNotEmpty
            ? AppCachedImage(imageUrl: photoUrl, fit: BoxFit.cover)
            : _buildPlaceholder(theme),

        // Overlay sombre pour lisibilité
        Container(color: Colors.black.withAlpha((0.70 * 255).round())),

        // Contenu centré
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              // Localisation
              if (widget.city != null && widget.city!.isNotEmpty)
                _DetailRow(icon: Icons.location_on, text: widget.city!),

              if (widget.country != null && widget.country!.isNotEmpty)
                _DetailRow(icon: Icons.public, text: widget.country!),

              // Description / bio
              if (widget.bio != null && widget.bio!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'À propos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.bio!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],

              // Intérêts complets
              if (widget.interests != null && widget.interests!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Intérêts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.interests!.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.30 * 255).round()),
                        ),
                      ),
                      child: Text(
                        interest,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Onglet info seul (fallback quand aucune photo)
  // -------------------------------------------------------------------------
  Widget _buildInfoTab(
    BuildContext context,
    ThemeData theme,
    String? photoUrl, {
    required bool showDetails,
  }) {
    return _buildFirstTab(context, theme, photoUrl);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.dividerColor.withAlpha((0.08 * 255).round()),
      child: const Center(
        child: Icon(Icons.person, size: 72, color: Colors.white38),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget helper — ligne d'info dans l'onglet détails
// ---------------------------------------------------------------------------
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white60),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
