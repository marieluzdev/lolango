Je veux implémenter un onboarding complet après la création du compte.

## 1. Redirection après inscription

Lorsqu'un utilisateur crée son compte pour la première fois, il ne doit **pas être redirigé directement vers Home**.

Le comportement doit être :

- Première création de compte → redirection vers l'onboarding.
- Onboarding terminé → sauvegarde de toutes les données dans Supabase → accès à l'application principale.
- Utilisateur déjà configuré → accès directement à l'application principale.

Il faut donc prévoir un moyen fiable de déterminer si le profil est déjà complété.

---

# 2. Navigation principale

Créer une navigation principale avec une **Bottom Navigation Bar** contenant exactement 4 onglets :

1. **Home**
2. **Découvrir**
3. **Match**
4. **Profil**

Utiliser **Lucide Icons** pour toutes les icônes.

La navigation doit être propre, minimaliste et cohérente avec le design général de Lolango.

La barre de navigation doit utiliser les couleurs existantes de `AppColors`.

Ne pas créer une nouvelle palette.

---

# 3. Onboarding

L'onboarding contient **10 écrans**.

Chaque écran doit avoir :

- un titre clair ;
- un court texte explicatif lorsque nécessaire ;
- une interface simple ;
- un indicateur de progression ;
- un bouton permettant de continuer ;
- une possibilité de revenir à l'écran précédent ;
- une validation adaptée au contenu de l'écran ;
- un design minimaliste, moderne et cohérent avec Lolango.

Utiliser **Skeletonizer** pour les états de chargement lorsque des données sont récupérées ou lorsqu'une opération asynchrone est en cours.

Utiliser **Lucide Icons** pour les icônes.

---

## Écran 1 — Ton prénom

Récupérer automatiquement le nom/prénom fourni par Google lors de l'inscription.

Titre :

**Comment veux-tu qu’on t’appelle ?**

Texte :

**Nous avons récupéré ton prénom depuis ton compte Google. Tu peux le modifier si tu veux.**

Afficher un champ contenant le nom récupéré depuis Google.

Le nom doit être modifiable par l'utilisateur.

Prévoir une validation afin que le champ ne soit pas vide.

Bouton :

**Continuer**

---

# Écran 2 — Ton nom d'utilisateur

Titre :

**Choisis ton nom d'utilisateur**

Texte :

**C’est le nom qui permettra aux autres de te retrouver sur Lolango.**

Afficher un champ avec le format :

`@nomutilisateur`

Le système doit vérifier en temps réel ou avec un léger délai si le nom d'utilisateur existe déjà dans Supabase.

États à gérer :

- disponible ;
- déjà utilisé ;
- vérification en cours ;
- format invalide.

Le nom d'utilisateur doit être unique dans la base de données.

Afficher un retour visuel clair :

**✓ Ce nom d'utilisateur est disponible**

ou :

**Ce nom d'utilisateur est déjà pris**

Le bouton Continuer doit être désactivé si le nom est invalide ou déjà utilisé.

---

# Écran 3 — Date de naissance

Titre :

**Quelle est ta date de naissance ?**

Texte :

**Ta date de naissance exacte n’est jamais affichée aux autres utilisateurs.**

Utiliser un sélecteur de date adapté au mobile.

Sauvegarder la date de naissance dans Supabase.

Prévoir une validation de l'âge selon les règles de l'application.

La date exacte ne doit jamais être affichée publiquement sur les profils.

L'app est reservée aux personnes majeures. (18 ans et plus).

---

# Écran 4 — Ton genre

Titre :

**Comment te définis-tu ?**

Texte :

**Choisis le genre qui te correspond.**

Options :

- Homme
- Femme

Présenter les choix sous forme de cartes ou boutons de sélection simples et élégants.

Un seul choix peut être sélectionné.

---

# Écran 5 — Qui souhaites-tu découvrir ?

Titre :

**Qui souhaites-tu découvrir ?**

Texte :

**Choisis les personnes que tu aimerais voir dans tes découvertes.**

Options :

- Hommes
- Femmes

Un ou plusieurs choix peuvent être sélectionnés selon la structure retenue pour le système de matching.

Cette information doit être enregistrée dans Supabase et utilisée plus tard pour le système de découverte et de matching.

---

# Écran 6 — Ta localisation

Titre :

**Où es-tu ?**

Texte :

**Nous affichons uniquement une zone approximative, jamais ton adresse exacte.**

Utiliser **OpenStreetMap** pour récupérer la localisation.

Exemple d'affichage :

**Dakar, Sénégal**

Ne jamais afficher l'adresse exacte de l'utilisateur aux autres utilisateurs.

La base de données doit permettre de conserver les informations nécessaires à la localisation et à la recherche géographique tout en respectant cette contrainte.

Prévoir :

- demande d'autorisation de localisation ;
- récupération de la position ;
- conversion en zone/localité ;
- affichage d'une localisation approximative ;
- gestion du refus d'autorisation ;
- état de chargement ;
- état d'erreur.

Utiliser Skeletonizer pendant la récupération des informations.

---

# Écran 7 — Tes centres d'intérêt

Titre :

**Qu’est-ce que tu aimes ?**

Texte :

**Choisis les activités, passions et sujets qui te ressemblent.**

L'utilisateur doit pouvoir sélectionner plusieurs centres d'intérêt.

Utiliser les catégories suivantes :

```dart
const _categories = [
  _InterestCategory(
    emoji: '🎨',
    name: 'Arts & Culture',
    subcategories: [
      _SubInterest(emoji: '🎵', label: 'Musique'),
      _SubInterest(emoji: '🎤', label: 'Chant'),
      _SubInterest(emoji: '💃', label: 'Danse'),
      _SubInterest(emoji: '🎬', label: 'Cinéma'),
      _SubInterest(emoji: '📺', label: 'Séries'),
      _SubInterest(emoji: '🎭', label: 'Théâtre'),
      _SubInterest(emoji: '📸', label: 'Photographie'),
      _SubInterest(emoji: '✏️', label: 'Dessin'),
      _SubInterest(emoji: '🖌️', label: 'Peinture'),
      _SubInterest(emoji: '📝', label: 'Écriture'),
      _SubInterest(emoji: '📖', label: 'Poésie'),
    ],
  ),
  _InterestCategory(
    emoji: '💻',
    name: 'Tech',
    subcategories: [
      _SubInterest(emoji: '👨‍💻', label: 'Programmation'),
      _SubInterest(emoji: '📱', label: 'Flutter'),
      _SubInterest(emoji: '🌐', label: 'Développement Web'),
      _SubInterest(emoji: '🤖', label: 'Intelligence artificielle'),
      _SubInterest(emoji: '🔐', label: 'Cybersécurité'),
      _SubInterest(emoji: '🎨', label: 'Design UI/UX'),
      _SubInterest(emoji: '🕹️', label: 'Jeux vidéo'),
      _SubInterest(emoji: '🦾', label: 'Robotique'),
    ],
  ),
  _InterestCategory(
    emoji: '📚',
    name: 'Études',
    subcategories: [
      _SubInterest(emoji: '📖', label: 'Lecture'),
      _SubInterest(emoji: '➗', label: 'Mathématiques'),
      _SubInterest(emoji: '🔬', label: 'Sciences'),
      _SubInterest(emoji: '📈', label: 'Économie'),
      _SubInterest(emoji: '💰', label: 'Finance'),
      _SubInterest(emoji: '📣', label: 'Marketing'),
      _SubInterest(emoji: '🚀', label: 'Entrepreneuriat'),
      _SubInterest(emoji: '🌍', label: 'Langues étrangères'),
    ],
  ),
  _InterestCategory(
    emoji: '⚽',
    name: 'Sport',
    subcategories: [
      _SubInterest(emoji: '⚽', label: 'Football'),
      _SubInterest(emoji: '🏀', label: 'Basketball'),
      _SubInterest(emoji: '🏐', label: 'Volleyball'),
      _SubInterest(emoji: '🎾', label: 'Tennis'),
      _SubInterest(emoji: '🏊', label: 'Natation'),
      _SubInterest(emoji: '🏃', label: 'Running'),
      _SubInterest(emoji: '🏋️', label: 'Salle de sport'),
      _SubInterest(emoji: '🥋', label: 'Arts martiaux'),
      _SubInterest(emoji: '🥾', label: 'Randonnée'),
      _SubInterest(emoji: '🚴', label: 'Cyclisme'),
    ],
  ),
  _InterestCategory(
    emoji: '✈️',
    name: 'Voyage & Lifestyle',
    subcategories: [
      _SubInterest(emoji: '✈️', label: 'Voyage'),
      _SubInterest(emoji: '🚗', label: 'Road trips'),
      _SubInterest(emoji: '🍽️', label: 'Découverte de restaurants'),
      _SubInterest(emoji: '☕', label: 'Café'),
      _SubInterest(emoji: '🍳', label: 'Cuisine'),
      _SubInterest(emoji: '🥐', label: 'Pâtisserie'),
      _SubInterest(emoji: '👗', label: 'Mode'),
      _SubInterest(emoji: '🛍️', label: 'Shopping'),
      _SubInterest(emoji: '🏡', label: 'Décoration'),
    ],
  ),
  _InterestCategory(
    emoji: '🎮',
    name: 'Divertissement',
    subcategories: [
      _SubInterest(emoji: '🎮', label: 'Gaming'),
      _SubInterest(emoji: '🌸', label: 'Anime & Manga'),
      _SubInterest(emoji: '♟️', label: 'Échecs'),
      _SubInterest(emoji: '🎲', label: 'Jeux de société'),
      _SubInterest(emoji: '🧠', label: 'Quiz'),
      _SubInterest(emoji: '📡', label: 'Streaming'),
    ],
  ),
  _InterestCategory(
    emoji: '🤝',
    name: 'Vie sociale',
    subcategories: [
      _SubInterest(emoji: '👋', label: 'Faire de nouvelles rencontres'),
      _SubInterest(emoji: '🎉', label: 'Sorties entre amis'),
      _SubInterest(emoji: '🥳', label: 'Soirées'),
      _SubInterest(emoji: '❤️', label: 'Bénévolat'),
      _SubInterest(emoji: '💼', label: 'Networking'),
      _SubInterest(emoji: '🗣️', label: 'Débats'),
    ],
  ),
  _InterestCategory(
    emoji: '🔥',
    name: 'Ambition',
    subcategories: [
      _SubInterest(emoji: '💡', label: 'Startups'),
      _SubInterest(emoji: '🖥️', label: 'Freelance'),
      _SubInterest(emoji: '📲', label: 'Création de contenu'),
      _SubInterest(emoji: '📊', label: 'Investissement'),
      _SubInterest(emoji: '📉', label: 'Trading'),
      _SubInterest(emoji: '📈', label: 'Développement personnel'),
      _SubInterest(emoji: '⏰', label: 'Productivité'),
    ],
  ),
  _InterestCategory(
    emoji: '🌿',
    name: 'Nature',
    subcategories: [
      _SubInterest(emoji: '🌱', label: 'Jardinage'),
      _SubInterest(emoji: '🐶', label: 'Animaux'),
      _SubInterest(emoji: '♻️', label: 'Écologie'),
      _SubInterest(emoji: '⛺', label: 'Camping'),
      _SubInterest(emoji: '🎣', label: 'Pêche'),
    ],
  ),
  _InterestCategory(
    emoji: '🧘',
    name: 'Bien-être',
    subcategories: [
      _SubInterest(emoji: '🧘', label: 'Méditation'),
      _SubInterest(emoji: '🧘‍♀️', label: 'Yoga'),
      _SubInterest(emoji: '🕊️', label: 'Spiritualité'),
      _SubInterest(emoji: '🥗', label: 'Nutrition'),
    ],
  ),
];
```

L'interface doit permettre de naviguer facilement entre les catégories et de sélectionner les sous-centres d'intérêt.

Afficher clairement les éléments sélectionnés.

---

# Écran 8 — Ta photo de profil

Titre :

**Ajoute une photo qui te représente 📸**

Texte :

**Une photo principale est nécessaire pour créer ton profil.**

Pour le MVP :

- 1 photo principale obligatoire ;
- jusqu'à 3 photos supplémentaires ;
- donc maximum 4 photos.

Permettre :

- sélectionner une photo ;
- remplacer une photo ;
- supprimer une photo ;
- définir la photo principale.

Utiliser `image_picker`.

Les images doivent être envoyées vers **Supabase Storage**.

Les URLs des photos doivent ensuite être enregistrées dans la base de données.

Afficher un état de chargement avec Skeletonizer ou un indicateur adapté pendant l'upload.

---

# Écran 9 — Tes réseaux sociaux

Titre :

**Sur quels réseaux peut-on te retrouver ?**

Texte :

**Ajoute tes réseaux sociaux si tu souhaites les partager avec les autres.**

Réseaux disponibles :

- Snapchat
- Instagram
- TikTok
- WhatsApp
- Facebook

Pour chaque réseau, permettre de renseigner un username.

Exemples :

**Instagram**

`@vrai`

**Snapchat**

`@vrai.snap`

**TikTok**

`@vrai`

Les réseaux sociaux doivent être optionnels.

Ne pas obliger l'utilisateur à renseigner tous les réseaux.

Les informations doivent être sauvegardées proprement dans Supabase.

---

# Écran 10 — Ta bio

Titre :

**Parle un peu de toi**

Texte :

**Présente-toi en quelques mots et donne envie de découvrir ton univers.**

Champ multiligne.

Exemple :

> Passionné de musique, football et voyages 🌍

Limiter la bio à environ **150 caractères**.

Afficher un compteur de caractères.

Le bouton de validation finale doit enregistrer toutes les données de l'onboarding.

---

# 4. Sauvegarde finale de l'onboarding

À la fin de l'écran 10, toutes les données collectées doivent être sauvegardées dans Supabase.

Les données doivent notamment comprendre :

- prénom ;
- nom d'utilisateur ;
- date de naissance ;
- genre ;
- préférences de découverte ;
- localisation ;
- centres d'intérêt ;
- photos ;
- réseaux sociaux ;
- bio ;
- statut de profil complété ;
- dates de création et de modification.

Le système doit éviter les profils partiellement créés ou incohérents.

Prévoir une structure permettant de reprendre l'onboarding si l'utilisateur quitte l'application avant la fin.

Une fois toutes les données sauvegardées avec succès :

**Profil complété → accès à l'application principale → Home.**

---

# 5. Base de données Supabase

Créer **tous les fichiers SQL nécessaires** pour mettre en place cette fonctionnalité.

Je veux une structure propre et évolutive.

Prévoir notamment les tables nécessaires pour :

- profils utilisateurs ;
- centres d'intérêt ;
- catégories de centres d'intérêt ;
- relations entre profils et centres d'intérêt ;
- photos de profil ;
- réseaux sociaux ;
- préférences de découverte ;
- localisation ;
- autres données nécessaires au fonctionnement de l'onboarding.

Créer également :

- les contraintes ;
- les index ;
- les clés étrangères ;
- les valeurs par défaut ;
- les timestamps ;
- les contraintes d'unicité nécessaires, notamment pour le username.

Le username doit être unique.

La structure doit être adaptée à PostgreSQL/Supabase.

---

# 6. Row Level Security

Configurer correctement les **RLS (Row Level Security)** sur toutes les tables concernées.

Les utilisateurs doivent pouvoir :

- consulter les informations publiques nécessaires ;
- modifier leurs propres informations ;
- supprimer leurs propres données ;
- gérer leurs propres photos ;
- gérer leurs propres réseaux sociaux ;
- gérer leurs propres centres d'intérêt ;
- gérer leurs propres préférences.

Un utilisateur ne doit jamais pouvoir modifier les données privées d'un autre utilisateur.

Les informations sensibles, notamment la date de naissance exacte et les données de localisation précises, ne doivent pas être exposées publiquement.

Créer toutes les policies SQL nécessaires.

---

# 7. Profil

Créer un écran **Profil** cohérent avec le design de Lolango.

Disposition générale :

### Header

Afficher :

- photo principale ;
- prénom ;
- username ;
- informations principales ;
- bouton paramètres avec une icône Lucide.

Le profil doit être visuellement propre et ne pas ressembler à un tableau de données.

### Section bio

Afficher la bio de l'utilisateur.

### Section centres d'intérêt

Afficher les centres d'intérêt sous forme de tags/chips simples.

Les catégories ne doivent pas prendre trop de place.

### Section réseaux sociaux

Afficher uniquement les réseaux sociaux renseignés.

Utiliser les icônes correspondantes lorsque disponibles avec Lucide.

### Galerie

Afficher les photos supplémentaires sous forme de grille élégante.

### Informations principales

Afficher uniquement les informations pertinentes pour les autres utilisateurs.

La date de naissance exacte ne doit pas être affichée.

Afficher éventuellement l'âge calculé à partir de la date de naissance si cette information est prévue dans le profil public.

La localisation doit rester approximative.

---

# 8. Modification du profil

Depuis Profil, l'utilisateur doit pouvoir modifier ses informations.

Permettre de modifier :

- prénom ;
- username ;
- date de naissance ;
- genre ;
- préférences de découverte ;
- localisation ;
- centres d'intérêt ;
- photos ;
- réseaux sociaux ;
- bio.

Le changement de username doit refaire la vérification d'unicité.

Les données doivent être mises à jour dans Supabase.

---

# 9. Paramètres

Depuis Profil, ajouter une page **Paramètres**.

La page doit être organisée en sections simples.

## Apparence

Ajouter :

**Mode sombre**

Avec un switch permettant de basculer entre :

- mode clair ;
- mode sombre.

Le changement doit être réellement fonctionnel et utiliser les deux thèmes déjà définis dans `AppColors`.

Ne pas créer de nouvelles couleurs.

## Compte

Ajouter :

**Se déconnecter**

Le bouton doit réellement effectuer la déconnexion Supabase puis rediriger vers l'écran approprié.

Ajouter :

**Supprimer mon compte**

La suppression doit demander une confirmation avant toute action.

Prévoir un dialogue de confirmation clair indiquant que la suppression est définitive.

La suppression doit supprimer proprement les données liées au compte selon la structure de la base de données.

---

# 10. Design

Le design doit être :

- minimaliste ;
- moderne ;
- propre ;
- élégant ;
- orienté application sociale/rencontre ;
- facile à utiliser ;
- sans néons ;
- sans dégradés excessifs ;
- sans esthétique "AI generated" ;
- sans surcharge visuelle.

Utiliser principalement :

- espaces blancs ;
- cartes sobres ;
- bordures légères ;
- coins légèrement arrondis ;
- typographie claire ;
- icônes Lucide ;
- couleurs de `AppColors`.

La couleur principale doit rester le jaune Lolango :

`#FFE44D`

Le noir doux doit être utilisé comme couleur secondaire.

Ne créer **aucune nouvelle palette de couleurs**.

Utiliser exactement la classe existante :

```dart
import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // LIGHT THEME
  // ============================================================

  static const Color primaryLight = Color(0xFFFFE44D);
  static const Color secondaryLight = Color(0xFF242424);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F5);

  static const Color textPrimaryLight = Color(0xFF1F1F1F);
  static const Color textSecondaryLight = Color(0xFF555555);
  static const Color textTertiaryLight = Color(0xFF8A8A8A);

  static const Color borderLight = Color(0xFFE8E8E5);

  static const Color successLight = Color(0xFF3FA56A);
  static const Color errorLight = Color(0xFFD9534F);

  static const Color navbarLight = Color(0xFFF7F7F5);

  static const Color counterBackgroundLight = Color(0xFF242424);
  static const Color counterTextLight = Color(0xFFFFFFFF);

  // ============================================================
  // DARK THEME
  // ============================================================

  static const Color primaryDark = Color(0xFFFFE44D);
  static const Color secondaryDark = Color(0xFFE8E8E8);

  static const Color backgroundDark = Color(0xFF111111);
  static const Color surfaceDark = Color(0xFF1C1C1C);

  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFC7C7C7);
  static const Color textTertiaryDark = Color(0xFF929292);

  static const Color borderDark = Color(0xFF2A2A2A);

  static const Color successDark = Color(0xFF5CC784);
  static const Color errorDark = Color(0xFFF26A67);

  static const Color navbarDark = Color(0xFF191919);

  static const Color counterBackgroundDark = Color(0xFFFFE44D);
  static const Color counterTextDark = Color(0xFF1F1F1F);
}
```

---

# 11. Architecture Flutter

Respect une architecture propre et cohérente avec le projet existant.

Séparer correctement :

- data ;
- domain ;
- presentation ;
- models ;
- repositories ;
- services ;
- viewmodels/providers ;
- widgets ;
- screens.

Utiliser **Riverpod** pour la gestion d'état si elle est déjà utilisée dans le projet.

Utiliser **GoRouter** pour la navigation si elle est déjà utilisée dans le projet.

Ne pas mettre toute la logique dans les widgets.

Les opérations Supabase doivent être isolées dans les repositories/services appropriés.

---

# 12. États de chargement et erreurs

Toutes les opérations asynchrones doivent gérer :

- loading ;
- success ;
- error ;
- retry lorsque pertinent.

Utiliser **Skeletonizer** pour les chargements de contenu lorsque cela améliore l'expérience utilisateur.

Gérer proprement les erreurs Supabase.

Afficher des messages utilisateur compréhensibles et non les erreurs techniques brutes.

---

# 13. Résultat attendu

Je veux l'implémentation complète et propre de :

- la navigation Home / Découvrir / Match / Profil ;
- les 10 écrans d'onboarding ;
- la récupération du nom Google ;
- la vérification d'unicité du username ;
- la sélection de la date de naissance ;
- le genre ;
- les préférences de découverte ;
- la localisation OpenStreetMap ;
- les centres d'intérêt ;
- les photos ;
- les réseaux sociaux ;
- la bio ;
- la sauvegarde Supabase ;
- la reprise d'un onboarding incomplet ;
- la détection d'un profil déjà configuré ;
- les tables SQL ;
- les relations SQL ;
- les index ;
- les contraintes ;
- les RLS ;
- les policies ;
- le stockage des photos ;
- le profil ;
- la modification du profil ;
- les paramètres ;
- le mode clair/sombre ;
- la déconnexion ;
- la suppression de compte ;
- les états Skeletonizer ;
- les états d'erreur ;
- l'utilisation de Lucide Icons ;
- l'utilisation exclusive de la palette `AppColors` fournie.

L'ensemble doit rester simple, cohérent et réellement fonctionnel, sans ajouter de fonctionnalités qui ne sont pas demandées.
