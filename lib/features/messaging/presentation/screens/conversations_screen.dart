import 'dart:math' as math;

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
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  bool _isSearchVisible = false;

  late final AnimationController _searchAnimController;
  late final Animation<double> _searchOpacity;
  late final Animation<Offset> _searchSlide;

  @override
  void initState() {
    super.initState();
    _searchAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _searchOpacity = CurvedAnimation(
      parent: _searchAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _searchSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _searchAnimController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _searchAnimController.forward();
      } else {
        _searchAnimController.reverse();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final counterBg = isDark ? AppColors.counterBackgroundDark : AppColors.counterBackgroundLight;

    final conversationsAsync = ref.watch(conversationsProvider);
    final conversationsCount = conversationsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12, top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                                color: counterBg,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  // ── Bouton toggle recherche ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: _toggleSearch,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Icon(
                            _isSearchVisible
                                ? LucideIcons.x
                                : LucideIcons.search,
                            key: ValueKey(_isSearchVisible),
                            color: textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ── Liste conversations ──────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () =>
                        ref.read(conversationsProvider.notifier).refresh(),
                    child: conversationsAsync.when(
                      data: (conversations) {
                        final filtered = conversations.where((c) {
                          return c.otherUser.profile.name
                              .toLowerCase()
                              .contains(_searchQuery);
                        }).toList();

                        if (filtered.isEmpty) {
                          return CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AppEmptyState(
                                  icon: LucideIcons.messageCircle,
                                  title: _searchQuery.isNotEmpty
                                      ? 'Aucun résultat'
                                      : 'Aucun message',
                                  description: _searchQuery.isNotEmpty
                                      ? 'Aucune conversation ne correspond à ta recherche.'
                                      : 'Tes conversations apparaîtront ici.',
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom:
                                MediaQuery.of(context).padding.bottom + 80,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            return _ConversationTile(conversation: conv);
                          },
                        );
                      },
                      // ── Skeleton ──────────────────────────────────────
                      loading: () => ListView.separated(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom:
                              MediaQuery.of(context).padding.bottom + 80,
                        ),
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 6,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, __) =>
                            const _ConversationSkeletonTile(),
                      ),
                      error: (e, _) => AppErrorState(
                        message: 'Impossible de charger les messages.',
                        onRetry: () =>
                            ref.read(conversationsProvider.notifier).refresh(),
                      ),
                    ),
                  ),

                  // ── Search bar animée en bas ─────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    child: SlideTransition(
                      position: _searchSlide,
                      child: FadeTransition(
                        opacity: _searchOpacity,
                        child: IgnorePointer(
                          ignoring: !_isSearchVisible,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
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
}

// ── Skeleton tile ────────────────────────────────────────────────────────────

class _ConversationSkeletonTile extends StatefulWidget {
  const _ConversationSkeletonTile();

  @override
  State<_ConversationSkeletonTile> createState() =>
      _ConversationSkeletonTileState();
}

class _ConversationSkeletonTileState extends State<_ConversationSkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final shimmerBase =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);
    final shimmerHighlight =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              _ShimmerBox(
                width: 56,
                height: 56,
                borderRadius: 28,
                controller: _shimmerController,
                base: shimmerBase,
                highlight: shimmerHighlight,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShimmerBox(
                          width: 120,
                          height: 14,
                          borderRadius: 7,
                          controller: _shimmerController,
                          base: shimmerBase,
                          highlight: shimmerHighlight,
                        ),
                        _ShimmerBox(
                          width: 36,
                          height: 11,
                          borderRadius: 6,
                          controller: _shimmerController,
                          base: shimmerBase,
                          highlight: shimmerHighlight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ShimmerBox(
                      width: double.infinity,
                      height: 11,
                      borderRadius: 6,
                      controller: _shimmerController,
                      base: shimmerBase,
                      highlight: shimmerHighlight,
                    ),
                    const SizedBox(height: 6),
                    _ShimmerBox(
                      width: 80,
                      height: 11,
                      borderRadius: 6,
                      controller: _shimmerController,
                      base: shimmerBase,
                      highlight: shimmerHighlight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final AnimationController controller;
  final Color base;
  final Color highlight;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.controller,
    required this.base,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final shimmerValue = math.sin(controller.value * math.pi);
        final color = Color.lerp(base, highlight, shimmerValue)!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final counterBg = isDark ? AppColors.counterBackgroundDark : AppColors.counterBackgroundLight;
    final counterText = isDark ? AppColors.counterTextDark : AppColors.counterTextLight;

    final otherUser = conversation.otherUser.profile;
    final lastMsg = conversation.lastMessage;

    String timeStr = '';
    if (lastMsg != null) {
      final now = DateTime.now();
      final date = lastMsg.createdAt;
      if (now.difference(date).inDays == 0 && now.day == date.day) {
        timeStr = DateFormat.Hm().format(date);
      } else if (now.difference(date).inDays < 7) {
        timeStr = DateFormat.E('fr').format(date);
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
                    ? AppCachedImage(
                        imageUrl: otherUser.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade300,
                        child:
                            const Icon(LucideIcons.user, color: Colors.grey),
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
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? counterBg
                                : textSecondary,
                            fontSize: 12,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
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
                              ? (lastMsg.type == 'social_share'
                                  ? '🔗 A partagé un réseau'
                                  : lastMsg.content)
                              : 'Nouvelle conversation !',
                          style: TextStyle(
                            color: conversation.unreadCount > 0
                                ? textPrimary
                                : textSecondary,
                            fontSize: 14,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                            color: counterBg,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: TextStyle(
                              color: counterText,
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
