import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
import 'package:lolango_v2/features/messaging/domain/message_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SocialShareBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String? otherUserPhoto;
  final bool showAvatar;

  const SocialShareBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserPhoto,
    this.showAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final primary = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final secondary = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final platform = message.metadata?['platform']?.toString() ?? 'inconnu';
    final username = message.metadata?['username']?.toString() ?? '';
    final url = message.metadata?['url']?.toString() ?? '';

    // Simple and clean card background
    final bubbleBg = surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: showAvatar
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: otherUserPhoto != null
                          ? CachedNetworkImageProvider(otherUserPhoto!)
                          : null,
                      child: otherUserPhoto == null
                          ? const Icon(LucideIcons.user, size: 14, color: Colors.grey)
                          : null,
                    )
                  : const SizedBox(width: 28),
            ),

          Container(
            width: MediaQuery.of(context).size.width * 0.70,
            decoration: BoxDecoration(
              color: bubbleBg,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe 
                                ? 'Mon compte ${platform.substring(0, 1).toUpperCase()}${platform.substring(1)}'
                                : 'Compte ${platform.substring(0, 1).toUpperCase()}${platform.substring(1)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _getSmallPlatformIcon(platform),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '@$username',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: textSecondary,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                if (url.isNotEmpty)
                  InkWell(
                    onTap: () => _launchURL(url),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border(top: BorderSide(color: borderColor)),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ).copyWith(
                          bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ouvrir',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            LucideIcons.arrowUpRight,
                            size: 16,
                            color: secondary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSmallPlatformIcon(String platform) {
    if (platform.toLowerCase() == 'instagram') {
      return Image.asset('assets/icons/instagram.png', width: 14, height: 14);
    } else if (platform.toLowerCase() == 'snapchat') {
      return Image.asset('assets/icons/snapchat.png', width: 14, height: 14);
    } else if (platform.toLowerCase() == 'tiktok') {
      return Image.asset('assets/icons/tiktok.png', width: 14, height: 14);
    }

    IconData icon;
    Color color;

    switch (platform.toLowerCase()) {
      case 'facebook': 
        icon = LucideIcons.users;
        color = const Color(0xFF1877F2);
        break;
      case 'twitter': 
      case 'x':
        icon = LucideIcons.messageSquare;
        color = Colors.black87;
        break;
      default: 
        icon = LucideIcons.link;
        color = Colors.grey;
    }

    return Icon(icon, size: 14, color: color);
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
