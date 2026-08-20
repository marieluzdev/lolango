# Plan d'Amélioration — Lolango v2

---

## 1. Filtre Localisation (Home & Découvrir)

### Problème actuel
Le `FilterModal` affiche "Ville" avec les options "Toutes les villes" / la ville de l'utilisateur, et possède des boutons "Annuler" et "Appliquer". Le filtre ne s'applique que quand on appuie sur "Appliquer".

### Solution
- Renommer "Ville" → **"Localisation"**
- Renommer les options :
  - "Toutes les villes" → **"Dans tout le pays"**
  - `_city!` → **"Dans ma ville (NomVille)"**
- **Par défaut** : "Dans ma ville" si la ville de l'utilisateur est disponible
- **Supprimer** les boutons "Annuler" et "Appliquer"
- **Application automatique** : chaque changement (âge, sexe, localisation, réseaux) met à jour le `discoveryFilterProvider` via un callback `onFilterChanged` passé au `FilterModal`

### Fichiers impactés
- `filter_modal.dart` — Refonte du widget (labels, suppression boutons, callback auto-apply)
- `home_screen.dart` — Passer `onFilterChanged` au lieu de récupérer le résultat du `pop()`
- `discovery_screen.dart` — Même adaptation
- `discovery_filter_init_provider.dart` — Initialiser avec la ville de l'utilisateur par défaut

---

## 2. Logique de réapparition des profils skippés

### Benchmark apps similaires
| App | Comportement |
|-----|-------------|
| Tinder | Réapparition après ~12h (gratuit), immédiat avec Rewind (payant) |
| Bumble | Réapparition après 24h |
| Hinge | Jamais (approche sélective) |
| Happn | Réapparition si croisement géographique |

### Recommandation : **Réapparition après 24h**
C'est le standard le plus courant pour les apps sociales. Les profils `pass` de moins de 24h sont exclus, ceux de plus de 24h réapparaissent. Les profils `like` ne réapparaissent jamais.

### Fichiers impactés
- `interaction_repository.dart` — Modifier `getInteractedProfileIds()` pour filtrer les `pass` datant de moins de 24h seulement (les `like` sont exclus pour toujours)

---

## 3. Séparation Skip Home vs Découvrir + Auto-refresh

### Problème actuel
- Home et Découvrir partagent `hiddenProfilesProvider` → un skip dans Home fait disparaître le profil dans Découvrir. C'est **le bon comportement** (standard de l'industrie).
- Le **vrai bug** : Découvrir ne réagit pas automatiquement — il faut pull-to-refresh manuellement.

### Solution
- `DiscoveryNotifier.build()` utilise `ref.read(hiddenProfilesProvider)` → il doit utiliser **`ref.watch()`** pour se reconstruire automatiquement
- La grille Découvrir se filtrera instantanément sans action de l'utilisateur

### Fichiers impactés
- `discovery_providers.dart` — `ref.read` → `ref.watch` pour `hiddenProfilesProvider`

---

## 4. Empty state "Aucun profil" dans Découvrir — Supprimer le bouton "Réinitialiser"

### Problème actuel
Le bouton "Réinitialiser" dans l'empty state de Découvrir reset les filtres, ce qui est déroutant si l'utilisateur a swipé tout le monde (le problème n'est pas les filtres).

### Solution
Différencier 2 cas :
1. **Filtres restrictifs** (sans filtres il y aurait des profils) → Message "Aucun profil avec ces filtres" + bouton "Modifier les filtres" (ouvre le FilterModal)
2. **Tous les profils vus** (filtres par défaut, liste vide) → Message "Tu as vu tous les profils disponibles. Reviens plus tard !" **sans bouton reset**

### Fichiers impactés
- `discovery_screen.dart` — Logique conditionnelle d'empty state

---

## 5. Bouton "Voir tout le monde" dans Home — Conditionnel

### Problème actuel
Le bouton "Voir tout le monde" s'affiche **toujours** dans l'empty state de Home, même quand les filtres sont déjà au défaut et que l'utilisateur a simplement swipé tout le monde.

### Solution
- Ajouter une méthode `_hasRestrictiveFilters(DiscoveryFilter)` qui vérifie si les filtres sont différents des valeurs par défaut (age 18-80, gender null, city null)
- **Si filtres restrictifs** → Afficher "Voir tout le monde" (reset filtres)
- **Si filtres par défaut** → Message "Plus de profils pour le moment. Reviens demain !" sans bouton

### Fichiers impactés
- `home_screen.dart` — Logique conditionnelle empty state

---

## 6. Gestion quand le filtre ne retourne aucun profil

### Comportement attendu
| Situation | Message | Bouton |
|-----------|---------|--------|
| Filtres modifiés + 0 profil | "Aucun profil avec ces filtres" | "Modifier les filtres" |
| Filtres défaut + 0 profil | "Aucun nouveau profil disponible. Reviens plus tard !" | Aucun |
| Filtres défaut + 0 profil (Home) | "Tu as swipé tous les profils disponibles !" | Aucun |

### Fichiers impactés
- `home_screen.dart` — Empty state conditionnel
- `discovery_screen.dart` — Empty state conditionnel

---

## 7. Notifications Push — Retard Android

### Cause
Le retard est dû aux restrictions Android (Doze mode, App Standby) et aux surcouches constructeur (Samsung, Xiaomi, Huawei). Il n'y a pas de solution 100% garantie côté code, mais on peut améliorer.

### Solution

#### Côté Flutter
- Dans `push_notification_service.dart` : mettre `importance: Importance.max` et `priority: Priority.max`
- Ajouter `fullScreenIntent: true` pour les matchs (notifications critiques)

#### Côté Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
```

#### Côté Firebase (Serveur Supabase Edge Function)
- S'assurer que les messages sont envoyés avec `"priority": "high"` dans le payload FCM
- Utiliser des **data messages** (pas `notification` messages) pour un meilleur contrôle côté app

> **Note** : Guider l'utilisateur à désactiver l'optimisation de batterie pour l'app dans les paramètres Android (surtout Samsung/Xiaomi).

### Fichiers impactés
- `push_notification_service.dart` — `Importance.max`, `Priority.max`, `fullScreenIntent`
- `AndroidManifest.xml` — Permissions

---

## 8. Privacy Modal non affiché à la première inscription

### Problème actuel
Le `hasSeenPrivacyModalProvider` vérifie `social_visibility != null` en BDD. À la fin de l'onboarding, `social_visibility` est `null`, donc le modal devrait s'afficher. Mais le **redirect** dans `app_router.dart` ne contient pas cette logique :

```dart
// Logique actuelle du redirect :
// 1. Non authentifié → /login
// 2. Profile non complété → /onboarding  
// 3. Profile complété + sur login/onboarding → /home
// MANQUE : Profile complété + privacy non vu → /privacy-setup
```

### Solution
Ajouter dans le redirect de `app_router.dart` :
```dart
// Après la vérification profileCompleted :
final privacySeen = ref.read(hasSeenPrivacyModalProvider);
if (profileCompleted && privacySeen.valueOrNull == false) {
  if (state.matchedLocation != '/privacy-setup') {
    return '/privacy-setup';
  }
}
```

### Fichiers impactés
- `app_router.dart` — Ajout de la logique de redirection vers `/privacy-setup`

---

## 9. Afficher uniquement la ville dans le profil (jamais la rue)

### Problème actuel
`ProfileModel.fromMap()` récupère la localisation depuis `location_label` qui peut contenir une adresse complète (rue, numéro, ville, pays). La méthode `_extractCity()` dans `profile_header.dart` coupe par virgule mais cela peut laisser le numéro de rue.

### Solution
- Prioriser `location_city` (champ dédié qui contient uniquement la ville) plutôt que `location_label`
- Format d'affichage : **"Ville"** dans le profil utilisateur, **"Ville, Pays"** dans la prévisualisation si le pays est disponible
- Jamais d'adresse, de rue, ou de code postal

### Fichiers impactés
- `profile_model.dart` — Prioriser `location_city` dans le mapping
- `profile_header.dart` — Simplifier `_extractCity()` 
- `profile_card.dart` — S'assurer que `widget.city` ne contient jamais la rue

---

## 10. Modal réseau social (Découvrir) + Skeletonizer + Chargement auto

### 10a. Bouton "Copier le pseudo" dans le modal réseau social

#### Problème actuel
Dans `discovery_screen.dart`, `_showSocialDetailModal()` affiche uniquement un `SizedBox(height: 16)` — le modal est complètement vide. Il manque le pseudo et le bouton de copie.

#### Solution
Compléter `_showSocialDetailModal()` pour afficher :
- Icône colorée du réseau social (même logique que `_SocialRow`)
- Pseudo `@username` en gros
- **Bouton "Copier le pseudo"** → `Clipboard.setData()` + SnackBar de confirmation
- Réutiliser la logique de `_showSocialCopySheet()` qui existe déjà dans `profile_card.dart`

### Fichiers impactés
- `discovery_screen.dart` — Compléter `_showSocialDetailModal()`

---

### 10b. Remplacer tous les spinners par Skeletonizer

#### Règle générale
- **`CircularProgressIndicator` (spinner)** → Uniquement dans `splash_screen.dart` et dans les **boutons** (lors d'une action en cours)
- **`AppLoading` (Skeletonizer)** → Pour tout chargement de **contenu** (listes, cartes, profils)

Le package `skeletonizer: ^2.1.3` est déjà installé. Le widget `AppLoading` existe dans `app_loading.dart`. Il faut juste l'utiliser.

#### Fichiers impactés
| Fichier | Changement |
|---------|-----------|
| `home_screen.dart` | `AppSpinner()` → Skeleton d'une `ProfileCard` factice |
| `discovery_screen.dart` | `AppSpinner()` → Skeleton de 4-6 cartes grille factices |
| `discovery_screen.dart` | Footer pagination `CircularProgressIndicator` → Skeleton 2 cartes |
| `profile_screen.dart` | `AppSpinner()` → Skeleton header + galerie + bio |
| `profile_preview_screen.dart` | `CircularProgressIndicator()` → `AppLoading` |
| `privacy_modal_screen.dart` | `CircularProgressIndicator()` → `AppLoading` |

---

### 10c. Chargement automatique sans pull-to-refresh

#### Problème
Les données ne se mettent pas à jour automatiquement quand on skip dans Home → les données Découvrir doivent être rechargées manuellement.

#### Solution
Dans `discovery_providers.dart`, le `DiscoveryNotifier.build()` :
```dart
// Actuel (ne réagit pas aux changements) :
final hiddenIds = ref.read(hiddenProfilesProvider);

// Corrigé (réagit automatiquement) :
final hiddenIds = ref.watch(hiddenProfilesProvider);
```

### Fichiers impactés
- `discovery_providers.dart` — `ref.read` → `ref.watch` pour `hiddenProfilesProvider`

---

## Résumé des fichiers impactés

| Fichier | Points | Priorité |
|---------|--------|----------|
| `discovery_providers.dart` | #3, #10c | 🔴 Haute |
| `filter_modal.dart` | #1 | 🔴 Haute |
| `home_screen.dart` | #1, #5, #6, #10b | 🔴 Haute |
| `discovery_screen.dart` | #1, #3, #4, #6, #10a, #10b | 🔴 Haute |
| `app_router.dart` | #8 | 🔴 Haute |
| `profile_screen.dart` | #10b | 🟡 Moyenne |
| `profile_preview_screen.dart` | #10b | 🟡 Moyenne |
| `privacy_modal_screen.dart` | #10b | 🟡 Moyenne |
| `profile_model.dart` | #9 | 🟡 Moyenne |
| `profile_header.dart` | #9 | 🟡 Moyenne |
| `profile_card.dart` | #9 | 🟡 Moyenne |
| `interaction_repository.dart` | #2 | 🟡 Moyenne |
| `push_notification_service.dart` | #7 | 🟢 Basse |
| `AndroidManifest.xml` | #7 | 🟢 Basse |

## Ordre d'implémentation recommandé

1. **#3 + #10c** — `discovery_providers.dart` : `ref.watch` (fix critique, 1 ligne)
2. **#1** — Filtre Localisation avec auto-apply (UX visible, très impactant)
3. **#8** — Privacy modal redirect dans `app_router.dart` (bug inscription)
4. **#10b** — Skeletonizer dans tous les écrans (polish UX)
5. **#10a** — Bouton copier pseudo dans Découvrir
6. **#9** — Ville seule dans le profil
7. **#4 + #5 + #6** — Empty states conditionnels (Home + Découvrir)
8. **#2** — Réapparition profils skippés après 24h
9. **#7** — Optimisation notifications push Android
