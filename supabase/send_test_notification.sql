-- Fonction RPC pour envoyer une notification candidate depuis l'application.
-- Appelée depuis Supabase via supabase.rpc('send_test_notification', ...)

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
