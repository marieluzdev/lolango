import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';

const _kInterestSuggestions = [
  'Sport', 'Musique', 'Cinéma', 'Voyage', 'Cuisine', 'Lecture', 'Gaming',
  'Art', 'Danse', 'Nature', 'Photo', 'Mode', 'Fitness', 'Yoga',
  'Randonnée', 'Surf', 'Ski', 'Tennis', 'Football', 'Basket', 'Running',
  'Vélo', 'Escalade', 'Natation', 'Technologie', 'Entrepreneuriat',
  'Finance', 'Design', 'Animation', 'Séries', 'Podcasts', 'DIY',
  'Jardinage', 'Animaux', 'Bénévolat',
];

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final List<TextEditingController> _socialControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  List<String> _interests = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadProfile);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    for (final controller in _socialControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
    if (!mounted) return;

    _firstNameController.text = (profile['first_name'] as String?) ?? '';
    _usernameController.text = ((profile['username'] as String?) ?? '').replaceFirst('@', '');
    _bioController.text = (profile['bio'] as String?) ?? '';

    final socials = profile['socials'] as List<dynamic>? ?? const <dynamic>[];
    final map = <String, String>{};
    for (final item in socials) {
      if (item is Map<String, dynamic>) {
        final platform = item['platform'] as String? ?? '';
        final username = item['username'] as String? ?? '';
        if (platform.isNotEmpty) {
          map[platform] = username;
        }
      }
    }

    const platforms = ['Instagram', 'Snapchat', 'TikTok'];
    for (var index = 0; index < _socialControllers.length; index++) {
      _socialControllers[index].text = map[platforms[index]] ?? '';
    }

    final interests = profile['interests'] as List<dynamic>? ?? const <dynamic>[];
    _interests = interests.whereType<String>().toList();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_interests.contains(interest)) {
        _interests.remove(interest);
      } else if (_interests.length < 10) {
        _interests.add(interest);
      }
    });
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (firstName.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom et le pseudo sont requis.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.upsertProfile({
        'first_name': firstName,
        'username': username.startsWith('@') ? username : '@$username',
        'bio': bio,
      });

      final socialMap = <String, String>{};
      const platforms = ['Instagram', 'Snapchat', 'TikTok'];
      for (var index = 0; index < _socialControllers.length; index++) {
        final value = _socialControllers[index].text.trim();
        if (value.isNotEmpty) {
          socialMap[platforms[index]] = value;
        }
      }

      await repo.upsertSocials(socialMap);
      await repo.upsertInterests(_interests);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour.')),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de sauvegarder le profil.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Modifier le profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Pseudo',
                  prefixText: '@',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                minLines: 4,
                maxLines: 6,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Centres d\'intérêt',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_interests.length}/10',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Choisis jusqu\'à 10 centres d\'intérêt',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kInterestSuggestions.map((interest) {
                  final selected = _interests.contains(interest);
                  return GestureDetector(
                    onTap: () => _toggleInterest(interest),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? primary : border,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: selected ? Colors.black : textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              Text(
                'Réseaux',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildSocialField('Instagram', LucideIcons.camera, _socialControllers[0], textPrimary, textSecondary, border),
                    Divider(height: 1, thickness: 1, color: border, indent: 16, endIndent: 16),
                    _buildSocialField('Snapchat', LucideIcons.messageCircle, _socialControllers[1], textPrimary, textSecondary, border),
                    Divider(height: 1, thickness: 1, color: border, indent: 16, endIndent: 16),
                    _buildSocialField('TikTok', LucideIcons.music, _socialControllers[2], textPrimary, textSecondary, border, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(LucideIcons.save, color: Colors.black),
                  label: Text(
                    _isSaving ? 'Enregistrement...' : 'Enregistrer',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Les informations sont sauvegardées dans Supabase.',
                style: TextStyle(color: textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialField(
    String label, 
    IconData icon, 
    TextEditingController controller, 
    Color textPrimary, 
    Color textSecondary, 
    Color border, 
    {bool isLast = false}
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: textPrimary),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
