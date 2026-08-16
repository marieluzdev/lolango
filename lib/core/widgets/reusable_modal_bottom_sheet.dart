import 'package:flutter/material.dart';

/// Widget réutilisable pour un modal bottom sheet personnalisé
/// Utilisé pour les options, confirmations et autres modales avec le même design
class ReusableModalBottomSheet extends StatelessWidget {
  const ReusableModalBottomSheet({
    super.key,
    required this.context,
    required this.title,
    required this.surface,
    required this.textPrimary,
    required this.children,
    this.onClose,
  });

  final BuildContext context;
  final String title;
  final Color surface;
  final Color textPrimary;
  final List<Widget> children;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  icon: Icon(Icons.close, color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Affiche un modal bottom sheet réutilisable
Future<T?> showReusableModalBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Color surface,
  required Color textPrimary,
  required List<Widget> children,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return ReusableModalBottomSheet(
        context: sheetContext,
        title: title,
        surface: surface,
        textPrimary: textPrimary,
        onClose: onClose,
        children: children,
      );
    },
  );
}
