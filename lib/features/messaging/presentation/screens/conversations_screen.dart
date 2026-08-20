import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/core/widgets/app_cached_image.dart';
import 'package:lolango_v2/core/widgets/app_empty_state.dart';
import 'package:lolango_v2/core/widgets/app_error_state.dart';
import 'package:lolango_v2/core/widgets/search_bar_widget.dart';
import 'package:lolango_v2/features/messaging/domain/conversation_model.dart';
import 'package:lolango_v2/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    final conversationsAsync = ref.watch(conversationsProvider);
    final conversationsCount = conversationsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              // Dynamic info text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    conversationsCount == 1
                        ? '1 conversation'
                        : '$conversationsCount conversations',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async => ref.invalidate(conversationsProvider),
                      child: conversationsAsync.when(
                        data: (conversations) {
                          final filtered = conversations.where((c) {
                            return c.otherUser.profile.name.toLowerCase().contains(_searchQuery);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const CustomScrollView(
                              physics: AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverFillRemaining(
                                  child: AppEmptyState(
                                    icon: LucideIcons.messageCircle,
                                    title: 'Aucun message',
                                    description: 'Tes conversations apparaîtront ici.',
                                  ),
                                ),
                              ],
                            );
                          }

                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80), // Espace pour la barre de recherche
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final conv = filtered[index];
                              return _ConversationTile(conversation: conv);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => AppErrorState(
                          message: 'Impossible de charger les messages.',
                          onRetry: () => ref.invalidate(conversationsProvider),
                        ),
                      ),
                    ),
                    // ── Barre de recherche fixe en bas au centre ──
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SearchBarWidget(
                          hint: 'Rechercher une conversation...',
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    
    final otherUser = conversation.otherUser.profile;
    final lastMsg = conversation.lastMessage;
    
    String timeStr = '';
    if (lastMsg != null) {
      final now = DateTime.now();
      final date = lastMsg.createdAt;
      if (now.difference(date).inDays == 0 && now.day == date.day) {
        timeStr = DateFormat.Hm().format(date);
      } else if (now.difference(date).inDays < 7) {
        timeStr = DateFormat.E('fr').format(date); // ex: Lun
      } else {
        timeStr = DateFormat.Md('fr').format(date);
      }
    }

    return GestureDetector(
      onTap: () {
        context.push('/chat/${conversation.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: otherUser.photoUrl != null
                    ? AppCachedImage(imageUrl: otherUser.photoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(LucideIcons.user, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        otherUser.name,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: conversation.unreadCount > 0 ? primary : textSecondary,
                            fontSize: 12,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg != null 
                              ? (lastMsg.type == 'social_share' ? '🔗 A partagé un réseau' : lastMsg.content)
                              : 'Nouvelle conversation !',
                          style: TextStyle(
                            color: conversation.unreadCount > 0 ? textPrimary : textSecondary,
                            fontSize: 14,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
