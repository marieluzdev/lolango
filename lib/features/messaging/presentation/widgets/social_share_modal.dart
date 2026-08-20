import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lolango_v2/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class SocialShareModal extends ConsumerWidget {
  final String conversationId;

  const SocialShareModal({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    final profileState = ref.watch(profileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Partager un réseau',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            profileState.when(
              data: (profileOpt) {
                if (profileOpt == null || profileOpt.socials == null || profileOpt.socials!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Tu n\'as pas ajouté de réseaux sociaux dans ton profil.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final socials = profileOpt.socials!;
                // Ici on pourrait filtrer avec SocialVisibility, mais comme c'est
                // pour envoyer explicitement, on peut tout lui proposer.

                return Column(
                  children: socials.entries.map((e) {
                    final platform = e.key;
                    final username = e.value;
                    return ListTile(
                      leading: Icon(_getPlatformIcon(platform)),
                      title: Text('@$username'),
                      subtitle: Text(platform, style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(LucideIcons.sendHorizontal),
                      onTap: () {
                        // Construire l'URL
                        String url = '';
                        if (platform.toLowerCase() == 'instagram') url = 'https://instagram.com/$username';
                        else if (platform.toLowerCase() == 'facebook') url = 'https://facebook.com/$username';
                        
                        ref.read(messagingRepositoryProvider).sendMessage(
                          conversationId,
                          'J\'aimerais partager mon compte $platform avec toi : @$username',
                          type: 'social_share',
                          metadata: {
                            'platform': platform,
                            'username': username,
                            'url': url,
                          }
                        );
                        context.pop();
                      },
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return LucideIcons.camera;
      case 'facebook': return LucideIcons.users;
      case 'twitter': return LucideIcons.messageSquare;
      default: return LucideIcons.link;
    }
  }
}
