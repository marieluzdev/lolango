# Refactoring Lolango — Bonnes pratiques Flutter modernes

Plan d'implémentation complet pour appliquer les 60 points de bonnes pratiques au projet Lolango. Chaque phase est ordonnée par dépendance logique : on construit les fondations (core) avant de refactorer les features.

---

## Diagnostic de l'existant

L'audit du code actuel révèle les problèmes suivants, classés par criticité :

### Critique

| # | Problème | Fichier(s) | Points concernés |
|---|----------|-----------|-----------------|
| 1 | `Map<String, dynamic>` partout au lieu de modèles typés | `profile_repository.dart`, `profile_screen.dart` | §31 |
| 2 | `Supabase.instance.client` utilisé directement (hors `supabaseProvider`) | `profile_repository.dart:6`, `interaction_providers.dart:7`, `discovery_providers.dart:11` | §21 |
| 3 | Errors silently swallowed (`catch (_) { return false/[]/null }`) | `profile_repository.dart`, `discovery_repository.dart` | §12, §13 |
| 4 | Aucun empty state, error state ou loading skeleton sur la plupart des écrans | Discovery, Home, Profile | §14, §15, §16, §17 |
| 5 | `print()` partout au lieu de logging structuré | `discovery_repository.dart`, `onboarding_repository.dart` | §30 |
| 6 | `Image.network` au lieu de `CachedNetworkImage` | `profile_screen.dart` | §8, §20 |
| 7 | Logique métier dupliquée (filtre onboarding) dans Home ET Discovery | `home_screen.dart:62-91`, `discovery_screen.dart:28-57` | §4 |
| 8 | Aucune pagination — `SELECT *` de toute la table `profiles` | `discovery_repository.dart:13` | §10, §54 |
| 9 | Pas de debounce sur le check username | `onboarding_repository.dart:12` | §11 |
| 10 | Pas de protection double-clic sur les actions (like, pass, save) | Home, Discovery, Match | §24 |

### Important

| # | Problème | Points concernés |
|---|----------|-----------------|
| 11 | God Widget : `ProfileScreen` = 933 lignes | §50 |
| 12 | Couleurs `isDark ? X : Y` manuellement dans chaque widget au lieu d'utiliser `Theme.of(context)` | §34 |
| 13 | `analysis_options.yaml` minimal, pas de règles strictes | §44 |
| 14 | Pas de widgets réutilisables (button, text field, chip, avatar, etc.) | §5, §51 |
| 15 | Dossiers `shared/`, `core/services/`, `core/utils/`, `core/cache/` vides | §1 |
| 16 | `ProfileModel` n'est pas un modèle Freezed malgré freezed dans le projet | §31 |
| 17 | Aucun test | §43 |

---

## Phases d'implémentation

### Phase 1 — Core : Fondations et infrastructure

> **IMPORTANT** : Toutes les features dépendent de cette phase. Elle doit être terminée avant de toucher aux features.

---

#### [MODIFY] `analysis_options.yaml`
Ajouter des règles de lint strictes mais pragmatiques : `prefer_const_constructors`, `prefer_const_declarations`, `avoid_print`, `prefer_final_locals`, `require_trailing_commas`, etc.

---

#### [NEW] `lib/core/errors/failures.dart`
Créer une hiérarchie d'erreurs applicatives propre :
- `Failure` (sealed class) avec `NetworkFailure`, `ServerFailure`, `AuthFailure`, `CacheFailure`, `UnexpectedFailure`
- Chaque failure contient un `message` utilisateur-friendly et le `originalError` optionnel
- Factory `Failure.from(dynamic e)` pour mapper les exceptions Supabase/réseau

#### [MODIFY] `lib/core/errors/app_exception.dart`
Enrichir le mapping existant pour couvrir plus de cas (AuthException, TimeoutException, etc.)

---

#### [NEW] `lib/core/utils/logger.dart`
Créer un logger centralisé :
- Niveaux : debug, info, warning, error
- Prefix par feature/module
- Désactivation en production via `kReleaseMode`
- Remplacement de tous les `print()` / `debugPrint()` ad-hoc

---

#### [NEW] `lib/core/utils/debouncer.dart`
Classe `Debouncer` réutilisable avec Timer.

---

#### [NEW] `lib/core/extensions/`
- `build_context_extensions.dart` : accès raccourcis au thème, couleurs, taille écran
- `async_value_extensions.dart` : helpers pour `AsyncValue` (widget builders)

---

#### [NEW] `lib/core/widgets/` — Composants réutilisables

| Fichier | Rôle |
|---------|------|
| `app_button.dart` | Bouton primaire/secondaire/outline avec état loading, protection double-clic |
| `app_text_field.dart` | Champ texte stylisé cohérent |
| `app_avatar.dart` | Avatar avec CachedNetworkImage, fallback initiale, placeholder |
| `app_empty_state.dart` | Composant icône + titre + description + action optionnelle |
| `app_error_state.dart` | Composant erreur avec bouton réessayer |
| `app_loading.dart` | Skeletonizer wrapper / shimmer loading |
| `app_chip.dart` | Chip stylisée cohérente |
| `app_cached_image.dart` | Wrapper autour de CachedNetworkImage avec placeholder/error/fallback |
| `app_section_header.dart` | Titre de section avec action optionnelle |

#### Widgets existants conservés
Les fichiers existants dans `core/widgets/` (`confirmation_modal_bottom_sheet.dart`, `reusable_modal_bottom_sheet.dart`, etc.) sont conservés et éventuellement mis à jour pour utiliser les nouvelles extensions de thème.

---

#### [MODIFY] `lib/core/constants/app_colors.dart`
Conserver tel quel (source de vérité). Optionnellement ajouter des `AppSpacing` et `AppRadius` constants.

#### [NEW] `lib/core/constants/app_spacing.dart`
Constantes d'espacement et de rayon de bordure réutilisables.

#### [MODIFY] `lib/core/theme/app_theme.dart`
Enrichir le thème pour intégrer les styles de boutons, champs, chips, etc. directement dans le `ThemeData`, afin que les widgets enfants les héritent sans `isDark ? X : Y`.

---

#### [MODIFY] `lib/core/supabase/supabase_client.dart`
Conserver tel quel, mais s'assurer que **tous** les repositories/providers utilisent `supabaseProvider` au lieu de `Supabase.instance.client`.

---

### Phase 2 — Data : Repositories et modèles

---

#### [MODIFY] `lib/features/discovery/domain/profile_model.dart`
Déplacer vers `lib/core/models/profile_model.dart` (modèle partagé entre discovery, match, profile).
Convertir en Freezed si le bénéfice est net (immutabilité, copyWith, equality), sinon garder un modèle Dart classique propre avec `fromJson`/`toJson`.

#### [NEW] `lib/core/models/detailed_profile_model.dart`
Modèle typé pour remplacer tous les `Map<String, dynamic>` retournés par `fetchDetailedProfile()`. Contient : profil de base + photos + socials + interests.

---

#### [MODIFY] `lib/features/profile/data/profile_repository.dart`
- Utiliser `ref.watch(supabaseProvider)` au lieu de `Supabase.instance.client`
- Retourner des modèles typés au lieu de `Map<String, dynamic>`
- Propager les erreurs via `AppException` / `Failure` au lieu de `catch (_) { return null }`
- Sélectionner uniquement les colonnes nécessaires
- Paralléliser les requêtes indépendantes avec `Future.wait`
- Factoriser le code dupliqué (`fetchDetailedProfile` et `fetchDetailedProfileById` partagent ~80% de logique)

#### [MODIFY] `lib/features/discovery/data/discovery_repository.dart`
- Utiliser `supabaseProvider`
- Remplacer `print()` par le logger
- Ajouter pagination (limit/offset ou cursor)
- Sélectionner uniquement les colonnes nécessaires
- Propager les erreurs au lieu de `catch { return [] }`
- Paralléliser les requêtes photos/socials/interests avec `Future.wait`

#### [MODIFY] `lib/features/match/data/interaction_repository.dart`
- Utiliser `supabaseProvider`
- Remplacer `debugPrint` par le logger
- Propager les erreurs
- Éviter de créer un `DiscoveryRepository` inline

#### [MODIFY] `lib/features/onboarding/data/onboarding_repository.dart`
- Remplacer `print()` par le logger
- Propager les erreurs proprement

---

### Phase 3 — Providers : Riverpod propre

---

#### [MODIFY] `lib/features/discovery/presentation/providers/discovery_providers.dart`
- Utiliser `supabaseProvider` dans le repository provider
- Remonter l'initialisation du filtre (logique onboarding) dans un provider dédié au lieu de la dupliquer dans Home et Discovery

#### [MODIFY] `lib/features/match/presentation/providers/interaction_providers.dart`
- Utiliser `supabaseProvider`

#### [NEW] `lib/features/profile/presentation/providers/profile_provider.dart`
- Provider `AsyncNotifier` pour le profil détaillé de l'utilisateur courant
- Gère loading/data/error
- Cache le profil en mémoire
- Expose `refreshProfile()` et `updateProfile()`
- Remplace les appels directs à `profileRepository.fetchDetailedProfile()` dans les widgets

#### [NEW] `lib/features/discovery/presentation/providers/discovery_filter_init_provider.dart`
Provider unique pour l'initialisation du filtre depuis les préférences onboarding (supprime la duplication Home/Discovery).

---

### Phase 4 — Présentation : UI, états, widgets

---

#### [MODIFY] `lib/features/profile/presentation/screens/profile_screen.dart` — **Décomposition du God Widget**
Décomposer en :
- `ProfileScreen` (orchestrateur, 100-150 lignes max)
- `ProfileHeader` (avatar, nom, username, infos)
- `ProfileBioSection` (bio avec guillemets)
- `ProfileInterestsSection` (chips avec voir plus)
- `ProfileSocialsSection` (réseaux sociaux)
- `ProfilePhotoGallery` (garder le widget existant, l'extraire dans un fichier séparé)

Chaque section utilise le `profileProvider` et gère ses propres états loading/error/data.
Utiliser `CachedNetworkImage` pour l'avatar et les photos.
Utiliser `Theme.of(context)` via les extensions au lieu du pattern `isDark ? X : Y`.

#### [MODIFY] `lib/features/discovery/presentation/screens/discovery_screen.dart`
- Ajouter les états loading (skeleton), error (AppErrorState), empty (AppEmptyState)
- Supprimer la logique d'init du filtre dupliquée
- Utiliser les widgets réutilisables
- Ajouter `RefreshIndicator`

#### [MODIFY] `lib/features/home/presentation/screens/home_screen.dart`
- Ajouter les états loading/error/empty
- Supprimer la logique d'init du filtre dupliquée
- Protection double-clic sur les swipes

#### [MODIFY] `lib/features/match/presentation/screens/match_screen.dart`
- Remplacer `CircularProgressIndicator` par des skeletons
- Remplacer le texte d'erreur brut par `AppErrorState`
- Remplacer les empty states textuels par `AppEmptyState` avec icône/description/action
- Ajouter `RefreshIndicator`

#### [MODIFY] `lib/features/auth/presentation/screens/login_screen.dart`
- Utiliser les extensions de thème au lieu de `isDark ? X : Y`
- Utiliser `AppButton` réutilisable

#### [MODIFY] `lib/features/auth/presentation/screens/splash_screen.dart`
- Améliorer le design (logo Lolango, fond coloré au lieu d'un simple spinner)

#### [MODIFY] `lib/features/profile/presentation/screens/settings_screen.dart`
- Ajouter loading state sur la suppression de compte
- Ajouter gestion d'erreur sur la déconnexion/suppression
- Protection double-clic

#### [MODIFY] `lib/features/main/presentation/screens/main_shell.dart`
- Cleanup des subscriptions Realtime dans `dispose()` (déjà fait ✓)
- Utiliser les constantes de thème

---

### Phase 5 — Performance et cache

---

- **Cache Riverpod** : les providers `allProfilesProvider` et `currentUserProfileProvider` conservent déjà leurs données en cache mémoire. S'assurer qu'ils ne sont pas invalides inutilement.
- **CachedNetworkImage** : remplacer tous les `Image.network` par `AppCachedImage` wrapper.
- **Pagination** : implémenter un `PaginatedNotifier` pour discovery (limit 20, load more on scroll).
- **Debounce** : ajouter debounce sur la vérification username dans l'onboarding.
- **Rebuilds** : utiliser `ref.watch(provider.select(...))` dans les sections qui ne dépendent que d'un sous-ensemble de l'état.

---

### Phase 6 — Qualité et polish

---

- **`dart format .`** sur tout le projet
- **`flutter analyze`** — corriger tous les warnings
- **`const`** partout où possible
- **Remplacer tous les `print`** par le logger
- **Supprimer le code mort** et les imports inutilisés
- **Nettoyage** : supprimer le dossier `lib/shared/` (vide) et `lib/core/services/` (vide), `lib/core/cache/` (vide)

---

### Phase 7 — Tests (fondations)

---

#### [NEW] `test/core/errors/failure_test.dart`
Tests unitaires pour le mapping des erreurs.

#### [NEW] `test/core/utils/debouncer_test.dart`
Tests unitaires pour le debouncer.

#### [NEW] `test/features/profile/data/profile_repository_test.dart`
Tests unitaires pour le repository profil (mock Supabase).

#### [NEW] `test/core/widgets/app_empty_state_test.dart`
Widget test pour le composant empty state.

#### [NEW] `test/core/widgets/app_error_state_test.dart`
Widget test pour le composant error state.

---

## Questions ouvertes

### Freezed pour les modèles ?
Le projet a déjà Freezed en dépendance mais `ProfileModel` est un PODO classique. Faut-il convertir les modèles en Freezed (immutabilité automatique, copyWith, equality, union types) ou garder des classes Dart classiques avec `fromJson`/`toJson` pour rester simple ?

### Scope de la pagination ?
La pagination est mentionnée au point §10. Faut-il implémenter un vrai infinite scroll avec chargement progressif dès cette première passe, ou poser les fondations (repository paginé) et garder un chargement initial de N profils avec un bouton "charger plus" ?

### Tests : jusqu'où aller dans cette itération ?
Les tests sont au point §43. Faut-il poser les fondations (quelques tests unitaires critiques + tests widgets de base) ou viser une couverture plus complète (tests d'intégration sur les flux auth → onboarding → home) ?

---

## Fichiers impactés (résumé)

| Action | Chemin |
|--------|--------|
| MODIFY | `analysis_options.yaml` |
| NEW | `lib/core/errors/failures.dart` |
| MODIFY | `lib/core/errors/app_exception.dart` |
| NEW | `lib/core/utils/logger.dart` |
| NEW | `lib/core/utils/debouncer.dart` |
| NEW | `lib/core/extensions/build_context_extensions.dart` |
| NEW | `lib/core/extensions/async_value_extensions.dart` |
| NEW | `lib/core/constants/app_spacing.dart` |
| NEW | `lib/core/widgets/app_button.dart` |
| NEW | `lib/core/widgets/app_text_field.dart` |
| NEW | `lib/core/widgets/app_avatar.dart` |
| NEW | `lib/core/widgets/app_empty_state.dart` |
| NEW | `lib/core/widgets/app_error_state.dart` |
| NEW | `lib/core/widgets/app_loading.dart` |
| NEW | `lib/core/widgets/app_chip.dart` |
| NEW | `lib/core/widgets/app_cached_image.dart` |
| NEW | `lib/core/widgets/app_section_header.dart` |
| MODIFY | `lib/core/theme/app_theme.dart` |
| MODIFY | `lib/core/constants/app_colors.dart` (mineur) |
| MOVE | `lib/features/discovery/domain/profile_model.dart` → `lib/core/models/profile_model.dart` |
| NEW | `lib/core/models/detailed_profile_model.dart` |
| MODIFY | `lib/features/profile/data/profile_repository.dart` |
| MODIFY | `lib/features/discovery/data/discovery_repository.dart` |
| MODIFY | `lib/features/match/data/interaction_repository.dart` |
| MODIFY | `lib/features/onboarding/data/onboarding_repository.dart` |
| MODIFY | `lib/features/discovery/presentation/providers/discovery_providers.dart` |
| MODIFY | `lib/features/match/presentation/providers/interaction_providers.dart` |
| NEW | `lib/features/profile/presentation/providers/profile_provider.dart` |
| MODIFY | `lib/features/profile/presentation/screens/profile_screen.dart` |
| NEW | `lib/features/profile/presentation/widgets/profile_header.dart` |
| NEW | `lib/features/profile/presentation/widgets/profile_bio_section.dart` |
| NEW | `lib/features/profile/presentation/widgets/profile_interests_section.dart` |
| NEW | `lib/features/profile/presentation/widgets/profile_socials_section.dart` |
| MODIFY | `lib/features/discovery/presentation/screens/discovery_screen.dart` |
| MODIFY | `lib/features/home/presentation/screens/home_screen.dart` |
| MODIFY | `lib/features/match/presentation/screens/match_screen.dart` |
| MODIFY | `lib/features/auth/presentation/screens/login_screen.dart` |
| MODIFY | `lib/features/auth/presentation/screens/splash_screen.dart` |
| MODIFY | `lib/features/profile/presentation/screens/settings_screen.dart` |
| DELETE | `lib/shared/` (répertoires vides) |
| DELETE | `lib/core/services/` (vide) |
| DELETE | `lib/core/cache/` (vide) |
| DELETE | `lib/core/utils/` (vide, remplacé par nouveaux fichiers) |
| NEW | Tests unitaires et widget tests |

---

## Vérification

### Automated
```bash
flutter analyze
dart format . --set-exit-if-changed
flutter test
```

### Manual
- Flux complet : Login → Onboarding → Home → Discovery → Match → Profile → Settings
- Vérifier loading/empty/error sur chaque écran
- Vérifier offline (mode avion)
- Vérifier double-clic
- Vérifier dark/light mode cohérent
