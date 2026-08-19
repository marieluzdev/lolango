# 🔐 Modal de Confidentialité des Réseaux Sociaux

Après l'onboarding, avant d'accéder à Home, un modal plein écran s'affiche une seule fois pour permettre à l'utilisateur de choisir **qui peut voir ses réseaux sociaux**. Ce choix est persisté en base et appliqué partout dans l'app (cartes, profils, modals). L'utilisateur peut copier les réseaux sociaux visibles.

---

## User Review Required

> [!IMPORTANT]
> **Nouvelle colonne Supabase requise** : `social_visibility` de type `text` dans la table `profiles`, avec valeur par défaut `'after_match'`. Tu devras ajouter cette colonne manuellement dans le dashboard Supabase avant de tester.

> [!IMPORTANT]
> **Option 2 — "Choisir quels réseaux montrer"** : Cette option implique un sélecteur par réseau (Instagram ✅, Snapchat ❌, TikTok ✅). La valeur `selective` sera stockée dans `social_visibility`, et un champ JSONB `visible_socials` (liste de noms de plateformes visibles) sera ajouté à `profiles`. **Es-tu d'accord avec cette approche, ou préfères-tu une table séparée `profile_social_visibility` ?**

---

## Open Questions

> [!IMPORTANT]
> **Copie des réseaux** : Quand l'utilisateur appuie sur un badge social dans la carte de découverte (ou le profil), un bottom sheet s'ouvre avec le nom d'utilisateur et un bouton **Copier**. C'est bien ce comportement attendu ?

> [!NOTE]
> **Première fois seulement** : Le flag `has_seen_privacy_modal` (colonne `boolean` dans `profiles`, default `false`) garantit que le modal ne s'affiche qu'une fois. Le flag passe à `true` dès que l'utilisateur valide son choix.

---

## Proposed Changes

### 1. Base de données Supabase (Manuel)

Deux nouvelles colonnes à ajouter dans la table `profiles` :

| Colonne | Type | Default | Description |
|---------|------|---------|-------------|
| `social_visibility` | `text` | `'after_match'` | Mode de visibilité : `after_match`, `selective`, `always` |
| `visible_socials` | `jsonb` | `null` | Liste des plateformes visibles (utilisé uniquement si `selective`) — ex: `["Instagram", "TikTok"]` |
| `has_seen_privacy_modal` | `boolean` | `false` | Flag pour ne montrer le modal qu'une fois |

---

### 2. Feature `social_access` — Écran de confidentialité

#### [NEW] [`social_visibility_model.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/social_access/domain/social_visibility_model.dart)

- Enum `SocialVisibility` avec 3 valeurs : `afterMatch`, `selective`, `always`
- Méthodes `toDbString()` / `fromDbString()` pour conversion DB
- Labels et descriptions en français pour chaque option

---

#### [NEW] [`social_visibility_provider.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/social_access/providers/social_visibility_provider.dart)

- `socialVisibilityProvider` — `StateNotifierProvider` qui charge/sauvegarde le choix de visibilité
- `hasSeenPrivacyModalProvider` — `FutureProvider<bool>` qui check le flag `has_seen_privacy_modal` en base
- Méthode `saveVisibility(SocialVisibility mode, List<String>? visiblePlatforms)` → upsert dans `profiles`
- Méthode `markPrivacyModalSeen()` → met `has_seen_privacy_modal = true`

---

#### [NEW] [`privacy_modal_screen.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/social_access/presentation/screens/privacy_modal_screen.dart)

Écran plein écran (pas un dialog) affiché comme route intermédiaire `/privacy-setup` (modal suspendu comme les autres modals) :

**Structure UI** :
```
┌─────────────────────────────────────┐
│                                     │
│   🔐 Qui peut voir tes réseaux ?   │
│                                     │
│   Tes réseaux sont cachés par       │
│   défaut. Tu gardes le contrôle     │
│   sur les personnes qui peuvent     │
│   les voir.                         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🔒 Après match        ✔    │    │
│  │ Tes réseaux deviennent      │    │
│  │ visibles uniquement quand   │    │
│  │ vous vous êtes mutuellement │    │
│  │ likés.                      │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ✋ Choisir                  │    │
│  │ Sélectionne quels réseaux   │    │
│  │ tu veux montrer.            │    │
│  └─────────────────────────────┘    │
│  (si sélectionné : checkboxes      │
│   Instagram / Snapchat / TikTok)   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🌐 Visible                  │    │
│  │ Tes réseaux apparaissent    │    │
│  │ directement sur ta carte.   │    │
│  └─────────────────────────────┘    │
│                                     │
│   Tu peux modifier ce choix à      │
│   tout moment dans Paramètres.     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │       Confirmer             │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

- Style cohérent avec l'onboarding (mêmes couleurs AppColors, mêmes rayons, mêmes polices)
- Cartes sélectionnables animées identiques à l'étape genre de l'onboarding
- Option 1 (`after_match`) **sélectionnée par défaut**
- Si option 2 (`selective`) sélectionnée → affiche la liste des réseaux de l'utilisateur avec des toggles/checkboxes
- Bouton "Confirmer" → sauvegarde en DB + redirige vers `/home`

---

### 3. Routing — Ajout de la route `/privacy-setup`

#### [MODIFY] [`app_router.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/core/routing/app_router.dart)

- Ajouter la route `GoRoute(path: '/privacy-setup', ...)`
- Modifier le `redirect` : quand `profileCompleted == true` ET `has_seen_privacy_modal == false` → rediriger vers `/privacy-setup` au lieu de `/home`
- Ajouter `hasSeenPrivacyModalProvider` au `_RouterRefreshNotifier` pour écouter les changements

**Logique de redirect mise à jour** :
```
profileCompleted && !hasSeenPrivacyModal → /privacy-setup
profileCompleted && hasSeenPrivacyModal  → /home
!profileCompleted                        → /onboarding
```

---

### 4. Filtrage de la visibilité des réseaux sociaux

#### [MODIFY] [`profile_card.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/discovery/presentation/widgets/profile_card.dart)

- Ajout d'un callback `onCopySocial` déclenché quand l'utilisateur tape sur un badge social
- Modification du `_openSocialModal` pour afficher le username + un **bouton "Copier"** qui utilise `Clipboard.setData()` et un SnackBar de confirmation
- Ajouter la logique de filtrage en amont : un nouveau paramètre optionnel `socialVisibility` et `isMatched` pour déterminer si les réseaux doivent être affichés

Les conditions d'affichage :
| Visibility | isMatched | Résultat |
|-----------|-----------|---------|
| `always` | - | ✅ Tous les réseaux visibles |
| `after_match` | `false` | ❌ Réseaux cachés |
| `after_match` | `true` | ✅ Réseaux visibles |
| `selective` | - | ✅ Seulement les réseaux choisis (filtrés via `visibleSocials`) |

---

#### [MODIFY] [`home_screen.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/home/presentation/screens/home_screen.dart)

- Passer les paramètres de visibilité au `ProfileCard` (le target profile a son propre `social_visibility`)
- Le filtrage se fait côté données : dans le `DetailedProfileModel`, on filtre les socials selon les réglages du **profil cible** (pas de l'utilisateur actuel)

---

#### [MODIFY] [`discovery_screen.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/discovery/presentation/screens/discovery_screen.dart)

- Même logique que `home_screen.dart` : passer les infos de visibilité au `ProfileCard`

---

#### [MODIFY] [`user_profile_screen.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/profile/presentation/screens/user_profile_screen.dart)

- Vérifier si le profil affiché a un match avec l'utilisateur courant
- Filtrer les réseaux selon `social_visibility` du profil cible

---

### 5. Données — Enrichissement des modèles

#### [MODIFY] [`profile_model.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/core/models/profile_model.dart)

- Ajouter champs `socialVisibility` (String?) et `visibleSocials` (List\<String\>?)
- Parser depuis la map dans `fromMap()`

---

#### [MODIFY] [`detailed_profile_model.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/core/models/detailed_profile_model.dart)

- Exposer `socialVisibility` et `visibleSocials` depuis le `profile` sous-jacent
- Ajouter helper `filteredSocials(bool isMatched)` qui retourne les socials filtrés selon la politique de visibilité

---

### 6. Repository — Chargement/sauvegarde de la visibilité

#### [MODIFY] [`profile_repository.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/profile/data/profile_repository.dart)

- Ajouter `fetchSocialVisibility()` → retourne le `social_visibility` de l'utilisateur courant
- Ajouter `updateSocialVisibility(String mode, List<String>? visiblePlatforms)` → upsert dans `profiles`
- Ajouter `hasSeenPrivacyModal()` → retourne le flag `has_seen_privacy_modal`
- Ajouter `markPrivacyModalSeen()` → met le flag à `true`

---

### 7. Paramètres — Modifier le choix de visibilité

#### [MODIFY] [`settings_screen.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/profile/presentation/screens/settings_screen.dart)

- Ajouter une section **"Confidentialité des réseaux"** avec un `ListTile` qui ouvre un bottom sheet ou navigue vers un écran similaire au modal de confidentialité (réutilisation du même widget)
- Affiche le mode actuel (ex: "🔒 Après match") et permet de le changer

---

### 8. Copie des réseaux sociaux — Bottom sheet enrichi

#### [MODIFY] [`profile_card.dart`](file:///c:/Users/monsi/Documents/MobileApp/Lovoo/lolango/lib/features/discovery/presentation/widgets/profile_card.dart) — `_openSocialModal`

Le bottom sheet qui s'ouvre quand on tape sur un badge social sera enrichi :

```
┌──────────────────────────────┐
│  Instagram                 ✕ │
│                              │
│  @john_doe                   │
│                              │
│  ┌────────────────────────┐  │
│  │  📋 Copier le pseudo   │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

- Affiche le nom de la plateforme + le username
- Bouton "Copier le pseudo" → `Clipboard.setData(ClipboardData(text: username))`
- SnackBar "Pseudo copié !"

---

## Fichiers concernés — Résumé

| Action | Fichier |
|--------|---------|
| **NEW** | `lib/features/social_access/domain/social_visibility_model.dart` |
| **NEW** | `lib/features/social_access/providers/social_visibility_provider.dart` |
| **NEW** | `lib/features/social_access/presentation/screens/privacy_modal_screen.dart` |
| MODIFY | `lib/core/routing/app_router.dart` |
| MODIFY | `lib/core/models/profile_model.dart` |
| MODIFY | `lib/core/models/detailed_profile_model.dart` |
| MODIFY | `lib/features/profile/data/profile_repository.dart` |
| MODIFY | `lib/features/profile/presentation/screens/settings_screen.dart` |
| MODIFY | `lib/features/discovery/presentation/widgets/profile_card.dart` |
| MODIFY | `lib/features/home/presentation/screens/home_screen.dart` |
| MODIFY | `lib/features/discovery/presentation/screens/discovery_screen.dart` |
| MODIFY | `lib/features/profile/presentation/screens/user_profile_screen.dart` |

---

## Verification Plan

### Automated Tests
- `flutter analyze` — vérifier aucune erreur de compilation
- `flutter run` — tester le flux complet

### Manual Verification
1. **Nouvel utilisateur** : Onboarding → Modal de confidentialité → Home (le modal ne s'affiche qu'une fois)
2. **Utilisateur existant** : Si `has_seen_privacy_modal = false` → redirigé vers le modal
3. **Option "Après match"** : Les réseaux sont cachés sur les cartes de découverte, visibles uniquement sur les profils matchés
4. **Option "Choisir"** : Seulement les réseaux sélectionnés sont visibles
5. **Option "Visible"** : Tous les réseaux visibles sur la carte
6. **Copie** : Taper un badge social → bottom sheet → bouton "Copier" → vérifier le presse-papier
7. **Paramètres** : Modifier le choix de visibilité → vérifier que le changement est immédiat
