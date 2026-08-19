import re

with open('lib/features/profile/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_idx = content.find('    return Scaffold(')
end_idx = content.find('}\n\n/// Ouvre un bottom sheet')

if start_idx == -1 or end_idx == -1:
    print("Could not find start or end index")
    exit(1)

new_body = """    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Paramètres',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Apparence', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.palette,
                  title: 'Thème',
                  textPrimary: textPrimary,
                  trailing: Switch(
                    value: themeMode == ThemeMode.dark,
                    activeThumbColor: AppColors.primaryLight,
                    onChanged: (value) async {
                      await ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
                _buildTile(
                  icon: LucideIcons.globe,
                  title: 'Langue',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Compte', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  textPrimary: textPrimary,
                  onTap: () async {
                    try {
                      await ref.read(pushNotificationServiceProvider).refreshToken();
                      await ref.read(profileRepositoryProvider).sendTestNotification();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification de test envoyée.')));
                    } catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Échec de l\'envoi : $error')));
                    }
                  },
                ),
                _buildTile(
                  icon: LucideIcons.mapPin,
                  title: 'Lieu',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.lock,
                  title: 'Confidentialité des réseaux',
                  textPrimary: textPrimary,
                  onTap: () async {
                    final p = await ref.read(profileRepositoryProvider).fetchDetailedProfile();
                    final userPlatforms = p?.socials.keys.toList() ?? [];
                    if (context.mounted) {
                      _showPrivacySettingsSheet(context, ref, textPrimary, textSecondary, userPlatforms);
                    }
                  },
                ),
                _buildTile(
                  icon: LucideIcons.users,
                  title: 'Mes communautés',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.ban,
                  title: 'Utilisateurs bloqués',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.trash2,
                  title: 'Supprimer mon compte',
                  textPrimary: AppColors.errorLight,
                  showDivider: false,
                  onTap: deleteAccount,
                ),
              ], surface),

              _buildSectionTitle('Sécurité', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.phone,
                  title: 'Appeler la police',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.shield,
                  title: 'Directives de sécurité',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Partenariat', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.badgeCheck,
                  title: 'Devenir partenaire',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Légal', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.folder,
                  title: 'Politique de confidentialité',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.fileText,
                  title: 'Conditions d\'utilisation',
                  textPrimary: textPrimary,
                  showDivider: false,
                ),
              ], surface),

              _buildSectionTitle('Support', textPrimary),
              _buildGroup([
                _buildTile(
                  icon: LucideIcons.helpCircle,
                  title: 'Centre d\'aide',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.send,
                  title: 'Nous contacter',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.messageCircle,
                  title: 'Faire une suggestion',
                  textPrimary: textPrimary,
                ),
                _buildTile(
                  icon: LucideIcons.wrench,
                  title: 'Dépannage de connexion',
                  textPrimary: textPrimary,
                  showDivider: false,
                  onTap: () async {
                    try {
                      final localToken = await ref.read(pushNotificationServiceProvider).refreshToken();
                      final storedToken = await ref.read(profileRepositoryProvider).fetchStoredFcmToken();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Local: ${localToken ?? 'aucun token'}\\nStocké: ${storedToken ?? 'aucun token'}'), duration: const Duration(seconds: 5)));
                      }
                    } catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur token FCM : $error')));
                    }
                  },
                ),
              ], surface),

              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: signOut,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE), // very light red
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(LucideIcons.logOut, size: 20),
                  label: const Text(
                    'Déconnexion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
      child: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children, Color surface) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required Color textPrimary,
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: textPrimary, size: 22),
          title: Text(
            title,
            style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: trailing ?? Icon(LucideIcons.chevronRight, color: textPrimary.withOpacity(0.4), size: 18),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(height: 1, indent: 56, endIndent: 16, color: textPrimary.withOpacity(0.1)),
      ],
    );
  }
"""

new_content = content[:start_idx] + new_body + content[end_idx:]

with open('lib/features/profile/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done replacing settings_screen.dart")
