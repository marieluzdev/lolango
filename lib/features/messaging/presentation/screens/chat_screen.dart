import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:lolango_v2/features/profile/presentation/providers/profile_provider.dart';
import 'package:lolango_v2/features/messaging/domain/message_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lolango_v2/features/messaging/presentation/widgets/social_share_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagingRepositoryProvider).markAsRead(widget.conversationId);
      _setupRealtime();
    });
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('public:messages:conversation_id=eq.${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            ref.invalidate(messagesProvider(widget.conversationId));
            ref.read(messagingRepositoryProvider).markAsRead(widget.conversationId);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    ref.read(messagingRepositoryProvider).sendMessage(
      widget.conversationId,
      text,
    );

    ref.invalidate(messagesProvider(widget.conversationId));

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final conversations = ref.watch(conversationsProvider).valueOrNull ?? [];
    final conversation = conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );

    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final otherUser = conversation.otherUser.profile;
    
    // Get logged-in user's profile for their social networks
    final profileState = ref.watch(profileProvider);
    final mySocials = profileState.valueOrNull?.socials ?? {};

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 8),
          icon: Icon(LucideIcons.arrowLeft, color: textPrimary, size: 26),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () {
            context.push('/user-profile/${otherUser.id}', extra: otherUser.name);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: otherUser.photoUrl != null
                    ? CachedNetworkImageProvider(otherUser.photoUrl!)
                    : null,
                child: otherUser.photoUrl == null
                    ? const Icon(LucideIcons.user, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${otherUser.name}, ${otherUser.age}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CD964),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En ligne',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
        actions: [
          IconButton(
            icon: Icon(LucideIcons.ellipsisVertical, color: textPrimary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: borderColor),
        ),
      ),
      body: Column(
        children: [
          // ── Social links row ──
          if (mySocials.isNotEmpty)
            _SocialLinksRow(
              socials: mySocials, 
              isDark: isDark,
              onShare: (platform, username) {
                String url = '';
                if (platform.toLowerCase() == 'instagram') url = 'https://instagram.com/$username';
                else if (platform.toLowerCase() == 'snapchat') url = 'https://snapchat.com/add/$username';
                else if (platform.toLowerCase() == 'tiktok') url = 'https://tiktok.com/@$username';
                else if (platform.toLowerCase() == 'facebook') url = 'https://facebook.com/$username';
                else url = 'https://$platform.com/$username';

                ref.read(messagingRepositoryProvider).sendMessage(
                  widget.conversationId,
                  'J\'aimerais partager mon compte $platform avec toi : @$username',
                  type: 'social_share',
                  metadata: {
                    'platform': platform,
                    'username': username,
                    'url': url,
                  }
                );
              },
            ),

          // ── Messages list ──
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: reversedMessages.length,
                  itemBuilder: (context, index) {
                    final msg = reversedMessages[index];
                    final isMe = msg.senderId == currentUserId;

                    // Date separator
                    final bool showDateSep = _shouldShowDateSeparator(
                      reversedMessages, index,
                    );

                    return Column(
                      children: [
                        if (showDateSep)
                          _DateSeparator(date: msg.createdAt, isDark: isDark),
                        _buildMessageBubble(
                          msg,
                          isMe,
                          context,
                          isDark: isDark,
                          otherUserPhoto: otherUser.photoUrl,
                          reversedMessages: reversedMessages,
                          index: index,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),

          // ── Input area ──
          _InputBar(
            controller: _textController,
            isDark: isDark,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(List<MessageModel> reversedMessages, int index) {
    if (index == reversedMessages.length - 1) return true; 
    final current = reversedMessages[index];
    final next = reversedMessages[index + 1]; 
    final currentDay = DateUtils.dateOnly(current.createdAt);
    final nextDay = DateUtils.dateOnly(next.createdAt);
    return currentDay != nextDay;
  }

  Widget _buildMessageBubble(
    MessageModel msg,
    bool isMe,
    BuildContext context, {
    required bool isDark,
    required String? otherUserPhoto,
    required List<MessageModel> reversedMessages,
    required int index,
  }) {
    if (msg.type == 'social_share') {
      return SocialShareBubble(
        message: msg,
        isMe: isMe,
        otherUserPhoto: otherUserPhoto,
        showAvatar: !isMe && (index == 0 || reversedMessages[index - 1].senderId != msg.senderId),
      );
    }

    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // Determine if we should show avatar (only show for the last consecutive message from other)
    final isLastInGroup = index == 0 ||
        reversedMessages[index - 1].senderId != msg.senderId;

    final bgCol = isMe ? primary : surface;
    final txtCol = isMe ? Colors.black87 : textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: isLastInGroup
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: otherUserPhoto != null
                          ? CachedNetworkImageProvider(otherUserPhoto)
                          : null,
                      child: otherUserPhoto == null
                          ? const Icon(LucideIcons.user, size: 14, color: Colors.grey)
                          : null,
                    )
                  : const SizedBox(width: 28),
            ),

          // Bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.70,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgCol,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                  bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: isMe ? [] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(color: txtCol, fontSize: 15, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.Hm().format(msg.createdAt),
                        style: TextStyle(
                          color: txtCol.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.checkCheck,
                          size: 14,
                          color: msg.readAt != null
                              ? Colors.black87
                              : txtCol.withOpacity(0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Social links banner ──────────────────────────────────────────────────────

class _SocialLinksRow extends StatelessWidget {
  final Map<String, String> socials;
  final bool isDark;
  final Function(String platform, String username) onShare;

  const _SocialLinksRow({
    required this.socials, 
    required this.isDark,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: socials.entries.map((entry) {
          final platform = entry.key;
          final username = entry.value;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onShare(platform, username),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlatformIcon(platform: platform, size: 24, primary: primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _platformLabel(platform),
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.chevronRight, size: 16, color: textSecondary),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _platformLabel(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram': return 'Instagram';
      case 'snapchat': return 'Snapchat';
      case 'facebook': return 'Facebook';
      case 'tiktok': return 'TikTok';
      case 'twitter': return 'Twitter';
      default: return platform;
    }
  }
}

// ── Date separator ───────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const _DateSeparator({required this.date, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final now = DateTime.now();
    String label;
    if (DateUtils.dateOnly(date) == DateUtils.dateOnly(now)) {
      label = "Aujourd'hui";
    } else if (DateUtils.dateOnly(date) ==
        DateUtils.dateOnly(now.subtract(const Duration(days: 1)))) {
      label = 'Hier';
    } else {
      label = DateFormat('d MMMM', 'fr').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider(color: borderColor, thickness: 0.8)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: borderColor, thickness: 0.8)),
        ],
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inputBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF9F9F9);

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field container
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: TextStyle(color: textPrimary, fontSize: 15),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.sendHorizontal,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Platform icon helper ──────────────────────────────────────────────────────

class _PlatformIcon extends StatelessWidget {
  final String platform;
  final double size;
  final Color primary;

  const _PlatformIcon({required this.platform, required this.size, required this.primary});

  @override
  Widget build(BuildContext context) {
    if (platform.toLowerCase() == 'instagram') {
      return Image.asset('assets/icons/instagram.png', width: size, height: size);
    } else if (platform.toLowerCase() == 'snapchat') {
      return Image.asset('assets/icons/snapchat.png', width: size, height: size);
    } else if (platform.toLowerCase() == 'tiktok') {
      return Image.asset('assets/icons/tiktok.png', width: size, height: size);
    }
    
    // Fallback for others
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFF1877F2),
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.users, size: size * 0.6, color: Colors.white),
        );
      case 'twitter':
      case 'x':
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.messageSquare, size: size * 0.6, color: Colors.white),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
          child: Icon(LucideIcons.link, size: size * 0.6, color: Colors.black87),
        );
    }
  }
}
