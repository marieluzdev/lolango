import 'package:flutter/material.dart';
import 'package:lolango_v2/core/constants/app_colors.dart';
/// Tile réutilisable pour une action dans un modal
class ModalActionTile extends StatelessWidget {
  const ModalActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
    this.isDangerous = false,
    this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  final bool isDangerous;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        backgroundColor ??
        (isDangerous
            ? (Theme.of(context).brightness == Brightness.dark ? AppColors.errorDark : AppColors.errorLight).withValues(alpha: 0.1)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)));
    final effectiveTextColor = isDangerous ? (Theme.of(context).brightness == Brightness.dark ? AppColors.errorDark : AppColors.errorLight) : textColor;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveTextColor, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: 16,
                fontWeight: isDangerous ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
