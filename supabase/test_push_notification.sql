-- Test manuel pour vérifier la chaîne push notification.
-- Si la table `public.notifications` n'existe pas, elle sera créée.
-- Si la colonne `fcm_token` manque dans `public.profiles`, elle sera ajoutée.
-- Le script choisit automatiquement un utilisateur ayant un `fcm_token` non nul.

alter table if exists public.profiles add column if not exists fcm_token text;

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

DO $$
DECLARE
  target_user uuid;
BEGIN
  SELECT id
  INTO target_user
  FROM public.profiles
  WHERE fcm_token IS NOT NULL
  LIMIT 1;

  IF target_user IS NULL THEN
    RAISE NOTICE 'Aucun utilisateur avec fcm_token trouvé dans public.profiles. Connecte l''app sur un device et autorise les notifications pour enregistrer le token.';
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, data)
  VALUES (
    target_user,
    'Test push Lolango',
    'Cette notification teste l''envoi FCM via Supabase',
    '{"test":"manual"}'::jsonb
  );

  RAISE NOTICE 'Notification test insérée pour l''utilisateur %.', target_user;
END;
$$;
