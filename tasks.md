# Tasks — Lolango v2

> Plan de référence : [plan_amelioration.md](./plan_amelioration.md)

---

## 🔴 Priorité Haute

### Fix auto-refresh Découvrir (#3 + #10c)
- [x] `discovery_providers.dart` — Remplacer `ref.read(hiddenProfilesProvider)` par `ref.watch(hiddenProfilesProvider)` dans `DiscoveryNotifier.build()`

### Filtre Localisation avec auto-apply (#1)
- [x] `filter_modal.dart` — Renommer "Ville" → "Localisation"
- [x] `filter_modal.dart` — Renommer "Toutes les villes" → "Dans tout le pays"
- [x] `filter_modal.dart` — Renommer chip ville → "Dans ma ville (NomVille)"
- [x] `filter_modal.dart` — Valeur par défaut = "Dans ma ville" si ville disponible
- [x] `filter_modal.dart` — Supprimer boutons "Annuler" et "Appliquer"
- [x] `filter_modal.dart` — Ajouter callback `onFilterChanged(DiscoveryFilter)` pour auto-apply
- [x] `home_screen.dart` — Adapter l'ouverture du FilterModal pour utiliser `onFilterChanged`
- [x] `discovery_screen.dart` — Adapter l'ouverture du FilterModal pour utiliser `onFilterChanged`
- [x] `discovery_filter_init_provider.dart` — Initialiser filtre avec ville par défaut

### Privacy Modal au premier login (#8)
- [x] `app_router.dart` — Ajouter logique de redirect vers `/privacy-setup` si `hasSeenPrivacyModal == false` et profil complété

---

## 🟡 Priorité Moyenne

### Skeletonizer — Remplacer les spinners de contenu (#10b)
- [x] `home_screen.dart` — `AppSpinner()` → Skeleton ProfileCard factice via `AppLoading`
- [x] `discovery_screen.dart` — `AppSpinner()` → Skeleton grille 4-6 cartes via `AppLoading`
- [x] `discovery_screen.dart` — Footer pagination `CircularProgressIndicator` → Skeleton 2 cartes
- [x] `profile_screen.dart` — `AppSpinner()` → Skeleton header + galerie + bio
- [x] `profile_preview_screen.dart` — `CircularProgressIndicator()` → `AppLoading`
- [x] `privacy_modal_screen.dart` — `CircularProgressIndicator()` → `AppLoading`

### Bouton "Copier le pseudo" dans Découvrir (#10a)
- [x] `discovery_screen.dart` — Compléter `_showSocialDetailModal()` avec icône réseau, pseudo, et bouton Copier
- [x] `discovery_screen.dart` — Utiliser `Clipboard.setData()` + SnackBar de confirmation

### Empty states conditionnels — Home (#5 + #6)
- [x] `home_screen.dart` — Ajouter méthode `_hasRestrictiveFilters(DiscoveryFilter)` (ajoutée via extension `isRestrictive`)
- [x] `home_screen.dart` — Si filtres restrictifs : afficher bouton "Voir tout le monde"
- [x] `home_screen.dart` — Si filtres par défaut : message "Reviens plus tard" sans bouton

### Empty states conditionnels — Découvrir (#4 + #6)
- [x] `discovery_screen.dart` — Différencier "filtres trop restrictifs" vs "tout swipé"
- [x] `discovery_screen.dart` — Si filtres restrictifs : bouton "Modifier les filtres" (ouvre FilterModal / ou réinitialise)
- [x] `discovery_screen.dart` — Si tout swipé : message sans bouton reset

---

## 🟢 Priorité Basse

### Réapparition profils skippés après 24h (#2)
- [x] `interaction_repository.dart` — `getInteractedProfileIds()` : exclut les `pass` < 24h, exclut toujours les `like`

### Optimisation notifications push Android (#7)
- [x] `push_notification_service.dart` — `Importance.high` → `Importance.max`, `Priority.high` → `Priority.max`
- [x] `push_notification_service.dart` — `fullScreenIntent: true` ajouté pour les matchs
- [x] `AndroidManifest.xml` — Permissions ajoutées : `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `RECEIVE_BOOT_COMPLETED`
- [x] Supabase Edge Function `send-push/index.ts` — `"priority": "HIGH"` déjà présent dans le payload FCM

---

## ✅ Terminé

*(Déplacer les tâches ici une fois implémentées)*
