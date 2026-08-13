# Supabase Edge Function : send-push

Cette fonction Supabase écoute les webhooks d'insertion sur la table `notifications` et envoie une notification push via l'API FCM v1.

## Fichiers

- `index.ts` : code principal de la fonction.
- `deno.json` : configuration Deno pour la compilation.
- `import_map.json` : import map pour les dépendances externes.

## Variables d'environnement requises

- `SUPABASE_URL` : URL du projet Supabase.
- `SUPABASE_SERVICE_ROLE_KEY` : clé service role Supabase.
- `FIREBASE_SERVICE_ACCOUNT` : contenu JSON du compte de service Google.

## Installation et déploiement

1. Dans le répertoire root du projet Supabase :

```bash
cd supabase/functions/send-push
supabase functions deploy send-push
```

2. Configurer les secrets :

```bash
supabase secrets set \
  SUPABASE_URL="https://xxxxx.supabase.co" \
  SUPABASE_SERVICE_ROLE_KEY="<service-role-key>" \
  FIREBASE_SERVICE_ACCOUNT="$(cat /path/to/service-account.json | jq -Rs .)"
```

> Attention : ne pas committer le JSON de compte de service dans Git.

## Webhook Supabase

Configurer un webhook ou un trigger de base de données pour appeler l'URL de la fonction sur `INSERT` dans `notifications`.

### Payload attendu du webhook

Le payload doit contenir :

```json
{
  "type": "INSERT",
  "table": "notifications",
  "schema": "public",
  "record": {
    "id": "...",
    "user_id": "...",
    "title": "...",
    "body": "...",
    "data": {"key": "value"}
  }
}
```

## Test manuel

Pour tester la chaîne complète sans besoin d'un trigger chat existant, insère une notification directement dans la table :

```sql
insert into public.notifications (user_id, title, body, data)
values (
  '<user_id>',
  'Test push Lolango',
  'Cette notification teste l''envoi FCM via Supabase',
  '{"test":"manual"}'::jsonb
);
```

Tu peux aussi utiliser le script prêt à l'emploi qui sélectionne automatiquement un utilisateur ayant un `fcm_token` :

```bash
psql -f supabase/test_push_notification.sql
```

> Si le script affiche `Aucun utilisateur avec fcm_token trouvé`, cela signifie que l'app n'a pas encore enregistré de token dans `public.profiles`. Connecte-toi à l'app sur un appareil ou un émulateur, autorise les notifications, puis réessaie.

> Vérifie d'abord que `profiles.fcm_token` contient un token valide pour l'utilisateur ciblé.

## Test depuis l'application

Tu peux envoyer un push de test depuis l'application en ouvrant l'écran Paramètres et en appuyant sur "Tester les notifications".

Cette action appelle la fonction RPC Supabase `send_test_notification`, qui insère une notification dans `public.notifications` pour l'utilisateur connecté.

## Fonction RPC Supabase

Un script est fourni pour créer la fonction SQL :

```bash
psql -f supabase/send_test_notification.sql
```

La fonction SQL est :

```sql
create or replace function public.send_test_notification(
  title text,
  body text
)
returns text
language plpgsql
security definer
as $$
begin
  insert into public.notifications (user_id, title, body, data)
  values (
    auth.uid(),
    title,
    body,
    jsonb_build_object('test', 'rpc')
  );

  return 'ok';
end;
$$;
```

## Test local

```bash
deno task run --unstable --import-map=import_map.json index.ts
```

ou bien :

```bash
supabase functions serve send-push
```
