# Tasks - Onboarding Lolango

## État général

- [x] 1. Analyse du projet et du flux d’auth existant
- [x] 2. Mise en place de l’architecture onboarding + repository
- [x] 3. Implémentation du router et de la redirection selon le profil
- [x] 4. Création du flux d’onboarding (10 écrans + validation)
- [x] 5. Ajout du navigation principale (Home / Découvrir / Match / Profil)
- [x] 6. Profil, paramètres, thème sombre, déconnexion et suppression
- [x] 7. Ajout des scripts SQL / RLS Supabase
- [x] 8. Vérification Flutter et correction des erreurs

## Historique

- [2026-08-12] Analyse du contexte terminée : auth existant, router GoRouter, thème AppColors, structure feature-based déjà présente.
- [2026-08-12] Implémentation du flux d’onboarding et de la navigation principale terminée.
- [2026-08-12] Vérification Flutter en cours / corrections appliquées sur le provider de profil et les routes.
- [2026-08-12] Scripts SQL et RLS Supabase ajoutés dans le dossier `supabase/`.
- [2026-08-12] Correction du schéma SQL : suppression des clauses `WITH CHECK` sur les politiques SELECT/DELETE invalides sous PostgreSQL.
- [2026-08-12] Implémentation du flux de photo réelle via `image_picker` + upload Supabase Storage.
- [2026-08-12] Ajout des liens sociaux dans le parcours onboarding + édition de profil.
- [2026-08-12] Création de l’écran d’édition profil avec sauvegarde Supabase.
- [2026-08-12] Finalisation du profil enrichi et nettoyage des warnings de compilation principaux.
- [2026-08-12] Correction du payload final d’onboarding : les colonnes `photos`, `social_links` et `selected_interests` ne sont plus envoyées vers `profiles`, et les données sont now réparties entre `profile_photos`, `profile_socials` et `profile_interests`.

## Tâches liées au MVP complet

- [x] Validation stricte des écrans d’onboarding (prénom, username, âge, bio, interêts / localisation)
- [x] Upload photo réel vers Supabase Storage
- [x] Social links et user profile editing
- [x] Écran de profil plus détaillé et cohérent avec la spec
- [x] Vérification Flutter du projet sur la configuration actuelle

## Notifications FCM via Supabase

- [x] Phase 1 : Initialisation Firebase et enregistrement du handler FCM
- [x] Phase 2 : Récupération du token FCM et enregistrement dans `profiles.fcm_token`
- [x] Phase 3 : Extension du schéma Supabase avec `profiles.fcm_token` et table `notifications`
- [x] Phase 4 : Implémentation de l’Edge Function Supabase / webhook de notification

## Notes d’implémentation

- Le service Flutter récupère le token FCM et le stocke dans `profiles.fcm_token` à chaque connexion et quand le token est rafraîchi.
- Le schéma Supabase ajoute `fcm_token` et une table `notifications` pour déclencher l’envoi.
- L’Edge Function `supabase/functions/send-push/index.ts` lit l’INSERT sur `notifications`, récupère le `fcm_token` du destinataire et appelle l’API FCM v1 avec un access token Google OAuth2.
- Prévoir l’ajout des secrets Supabase : `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_URL`, `FIREBASE_SERVICE_ACCOUNT`.
