import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';
import 'package:lolango_v2/features/discovery/presentation/widgets/profile_card.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .fetchDetailedProfileById(widget.userId);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final title = widget.userName ?? _profile?['first_name'] as String? ?? 'Profil';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null || _profile!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.userX,
                          size: 48,
                          color: textPrimary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Profil introuvable.',
                        style: TextStyle(color: textPrimary),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _buildProfileCard(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _buildProfileCard() {
    final p = _profile!;
    final firstName = (p['first_name'] as String?) ?? 'Prénom';
    final city = p['location_label'] as String?;
    final bio = p['bio'] as String?;

    // Socials
    final socialsList =
        (p['socials'] as List<dynamic>? ?? <dynamic>[]);
    final Map<String, String> socialsMap = {};
    for (final item in socialsList) {
      if (item is Map<String, dynamic>) {
        final platform = item['platform'] as String?;
        final username = item['username'] as String?;
        if (platform != null &&
            username != null &&
            platform.isNotEmpty) {
          socialsMap[platform] = username;
        }
      }
    }

    // Interests
    final interests =
        (p['interests'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => e.toString())
            .toList();

    // Photos
    final photosList =
        p['photos'] as List<dynamic>? ?? <dynamic>[];
    final photoUrls = <String>[];
    for (final photo in photosList) {
      if (photo is Map<String, dynamic>) {
        final url = photo['url'] as String?;
        if (url != null && url.isNotEmpty) photoUrls.add(url);
      } else if (photo is String && photo.isNotEmpty) {
        photoUrls.add(photo);
      }
    }

    // Age
    int? age;
    final birthDateRaw = p['birth_date'];
    if (birthDateRaw is String && birthDateRaw.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(birthDateRaw);
        final now = DateTime.now();
        age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month &&
                now.day < birthDate.day)) {
          age -= 1;
        }
      } catch (_) {}
    }

    return ProfileCard(
      name: firstName,
      age: age,
      city: city,
      photoUrls: photoUrls,
      bio: bio,
      socials: socialsMap,
      interests: interests,
      showActionButtons: false,
    );
  }
}
