# Supabase onboarding

Ce dossier contient les scripts SQL nécessaires au bon fonctionnement de l’onboarding Lolango.

## Fichiers

- `schema_onboarding.sql` : tables, index, contraintes, RLS et triggers
- `seed_interests.sql` : catégories et centres d’intérêt initiaux

## Ordre de lancement

1. Exécuter `schema_onboarding.sql`
2. Exécuter `seed_interests.sql`

## Règles importantes

- le `username` doit être unique
- la date de naissance ne doit être visible que par l’utilisateur lui-même
- les données de localisation doivent rester approximatives
- seul l’utilisateur concerné peut modifier ses données
