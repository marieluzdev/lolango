# 🚀 Guide Complet : Notifications Push (Firebase + Supabase + Flutter)

Ce guide est écrit pour les débutants. Il explique étape par étape comment configurer de zéro un système de notifications push sur une application Flutter, en utilisant Supabase comme serveur (backend) et Firebase comme service d'envoi.

## 🧠 Comment ça marche ? (La théorie)

Quand tu veux envoyer une notification push, voici le chemin que ça prend :
1. Ton application **Flutter** demande à **Firebase** un "Token FCM" (une plaque d'immatriculation unique pour le téléphone).
2. L'application sauvegarde ce token dans ta base de données **Supabase** (dans la table `profiles`).
3. Quand un événement se produit (ex: on insère une ligne dans la table `notifications`), un **Trigger SQL** (un déclencheur automatique) se réveille.
4. Ce Trigger appelle une **Edge Function** (un petit bout de code serveur) chez Supabase.
5. L'Edge Function utilise une **Clé Secrète Firebase** pour s'authentifier, et demande à Firebase d'envoyer la notification au "Token FCM" concerné.

---

## 🛠️ Étape 1 : Côté Firebase (Obtenir la clé secrète)

Supabase a besoin d'une autorisation spéciale (un fichier JSON) pour pouvoir ordonner à Firebase d'envoyer des notifications.

1. Va sur la [Console Firebase](https://console.firebase.google.com).
2. Ouvre ton projet.
3. Clique sur la **roue crantée (Paramètres)** en haut à gauche ⚙️ -> **Paramètres du projet**.
4. Va dans l'onglet **Comptes de service** (Service accounts).
5. En bas de la page, clique sur le bouton bleu **Générer une nouvelle clé privée**.
6. Un fichier `.json` va se télécharger sur ton ordinateur (souvent appelé `nom-du-projet-firebase-adminsdk-xxx.json`).
7. **TRÈS IMPORTANT** : Mets ce fichier à la racine de ton projet et nomme-le `firebase-admin.json`.
8. Ajoute **absolument** la ligne `firebase-admin.json` dans ton fichier `.gitignore` pour ne jamais envoyer ce fichier secret sur Github !

---

## 🛠️ Étape 2 : Côté Supabase (Donner la clé secrète à l'Edge Function)

Maintenant qu'on a le fichier secret de Firebase, il faut le donner de façon sécurisée à Supabase.

1. Ouvre un terminal (PowerShell) dans le dossier de ton projet.
2. Si tu n'as pas Supabase CLI installé, installe-le et connecte-toi :
   ```bash
   npm install -g supabase
   npx supabase login
   ```
3. Lie ton projet local à ton vrai projet Supabase en ligne (remplace par ton vrai Project Ref) :
   ```bash
   npx supabase link --project-ref ton_project_ref
   ```
4. Envoie le contenu du fichier JSON dans les "Secrets" de Supabase de manière sécurisée :
   *(Attention sous Windows, utiliser un fichier temporaire .env évite les bugs de guillemets)*
   ```powershell
   # Créer un fichier temporaire avec le bon format
   $content = Get-Content -Raw firebase-admin.json; $content = $content -replace "'", "''"; Set-Content -Path secrets.env -Value ("FIREBASE_SERVICE_ACCOUNT='" + $content + "'")
   
   # Envoyer le secret à Supabase
   npx supabase secrets set --env-file secrets.env
   
   # Supprimer le fichier temporaire
   Remove-Item secrets.env
   ```

---

## 🛠️ Étape 3 : Créer et déployer l'Edge Function

L'Edge function est le code serveur qui va envoyer l'ordre à Firebase.

1. Crée la fonction locale (si ce n'est pas déjà fait) :
   ```bash
   npx supabase functions new send-push
   ```
2. Remplis le fichier `supabase/functions/send-push/index.ts` avec le code TypeScript (voir le code actuel de ton projet). **Important :** Utilise les imports `npm:` et pas `https://esm.sh/` pour éviter les bugs de déploiement (erreur *Module not found*).
   ```typescript
   import { createClient } from 'npm:@supabase/supabase-js@2.39.3';
   import { JWT } from 'npm:google-auth-library@9.6.3';
   ```
3. Déploie la fonction sur les serveurs de Supabase :
   ```bash
   npx supabase functions deploy send-push --no-verify-jwt
   ```

---

## 🛠️ Étape 4 : Le SQL (Créer le Trigger / "Webhook")

C'est ici qu'on a eu le plus de problèmes : l'interface visuelle "Webhooks" du Dashboard Supabase est souvent buggée (elle cherche un vieux module appelé `supabase_functions` qui n'existe plus).
**La méthode la plus sûre est de ne PAS utiliser l'interface graphique de Supabase, mais d'exécuter un script SQL dans le "SQL Editor".**

1. Ouvre le **SQL Editor** dans ton dashboard Supabase.
2. Colle ce script exact (il crée la table, active le module réseau `pg_net`, crée la fonction, et attache le Trigger) :

```sql
-- 1. On supprime la table si elle existe pour nettoyer les vieux triggers cassés
DROP TABLE IF EXISTS public.notifications CASCADE;

-- 2. On recrée la table proprement
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  body text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 3. On active l'extension réseau (OBLIGATOIRE)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 4. On crée la fonction qui va appeler notre Edge Function
CREATE OR REPLACE FUNCTION public.send_push_on_notification()
RETURNS trigger AS $$
DECLARE
  request_id bigint;
BEGIN
  SELECT net.http_post(
      -- ATTENTION: Remplace "onypmnscmhrxzclbjtqh" par TON vrai project ID
      url := 'https://onypmnscmhrxzclbjtqh.supabase.co/functions/v1/send-push',
      
      -- ATTENTION: Remplace VOTRE_CLE_SECRET_ICI par ta "Secret Key" (Project Settings -> API)
      -- Garde bien le mot "Bearer " suivi d'un espace avant la clé !
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer VOTRE_CLE_SECRET_ICI"}'::jsonb,
      
      body := jsonb_build_object(
        'type', TG_OP,
        'table', TG_TABLE_NAME,
        'schema', TG_TABLE_SCHEMA,
        'record', row_to_json(NEW)
      )
  ) INTO request_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. On attache le trigger à la table
CREATE TRIGGER on_notification_inserted_trigger
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.send_push_on_notification();
```

3. Clique sur **"Run and enable RLS"** pour l'exécuter et sécuriser la table.

---

## 🛠️ Étape 5 : Test final !

Tout est prêt ! 
Dans ton application Flutter :
1. Assure-toi que l'utilisateur est connecté et que son `fcm_token` est bien enregistré dans la table `profiles`.
2. Insère une nouvelle ligne dans la table `notifications` (via le code Flutter ou manuellement dans Supabase).
3. La notification doit apparaître instantanément sur le téléphone !

Si ça ne marche pas, **ne touche plus au SQL ni aux Webhooks**. Va dans ton dashboard Supabase -> **Edge Functions** -> clique sur `send-push` -> onglet **Logs** pour voir ce qui bloque (souvent un problème d'authentification ou de format JSON envoyé par le terminal).
