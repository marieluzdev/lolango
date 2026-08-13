import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/data/profile_repository.dart';

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
                decoration: InputDecoration(
                  labelText: 'Bio',
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: border),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Réseaux',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (int index = 0; index < _socialControllers.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _socialControllers[index],
                    decoration: InputDecoration(
                      labelText: ['Instagram', 'Snapchat', 'TikTok'][index],
                      filled: true,
                      fillColor: surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: border),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
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
}
