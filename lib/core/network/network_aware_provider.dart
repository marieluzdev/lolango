import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lolango_v2/core/network/connectivity_provider.dart';
import 'package:lolango_v2/core/utils/logger.dart';
import 'package:lolango_v2/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:lolango_v2/features/match/presentation/providers/interaction_providers.dart';

/// Provider qui surveille la connectivité réseau.
///
/// Dès que la connexion revient (après avoir été perdue), il invalide
/// automatiquement les providers de données clés pour déclencher leur rechargement.
///
/// À activer une seule fois via `ref.watch(networkAwareProvider)` dans le
/// widget racine de la session (ex: [MainShellScreen]).
final networkAwareProvider = Provider<void>((ref) {
  ref.listen<bool>(isConnectedProvider, (previous, current) {
    AppLogger.d('[NETWORK] Connectivity changed: previous=$previous, current=$current');

    if (previous == false && current == true) {
      // La connexion vient de revenir
      AppLogger.d('[NETWORK] Connection restored! Auto-refreshing providers…');
      ref.invalidate(pendingLikesProvider);
      ref.invalidate(matchesProvider);
      ref.invalidate(interactedProfilesProvider);
      ref.invalidate(discoveryNotifierProvider);
    } else if (current == false) {
      AppLogger.d('[NETWORK] Connection lost.');
    }
  });
});
