-- Vérifie les utilisateurs ayant un token FCM enregistré.
-- Si le résultat est vide, l'app n'a pas encore stocké le token dans profiles.fcm_token.

select
  id,
  username,
  fcm_token,
  created_at,
  updated_at
from public.profiles
where fcm_token is not null
order by updated_at desc
limit 100;

select count(*) as profiles_with_fcm_token
from public.profiles
where fcm_token is not null;
