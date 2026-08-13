create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null default '',
  username text not null unique,
  birth_date date,
  gender text check (gender in ('Homme', 'Femme')),
  discovery_preferences text[] not null default '{}',
  location_label text,
  latitude double precision,
  longitude double precision,
  bio text not null default '',
  fcm_token text,
  profile_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.interest_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  emoji text,
  created_at timestamptz not null default now()
);

create table if not exists public.interests (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.interest_categories(id) on delete cascade,
  name text not null,
  emoji text,
  created_at timestamptz not null default now(),
  unique (category_id, name)
);

create table if not exists public.profile_interests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  interest_id uuid not null references public.interests(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, interest_id)
);

create table if not exists public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  url text not null,
  is_primary boolean not null default false,
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profile_socials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('Instagram', 'Snapchat', 'TikTok', 'WhatsApp', 'Facebook')),
  username text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, platform)
);

create table if not exists public.discovery_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  preferred_gender text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists public.user_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  country text,
  city text,
  locality text,
  latitude double precision,
  longitude double precision,
  is_approximate boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create index if not exists idx_profiles_username on public.profiles(username);
create index if not exists idx_profiles_gender on public.profiles(gender);
create index if not exists idx_profiles_profile_completed on public.profiles(profile_completed);
create unique index if not exists idx_profile_photos_user_position on public.profile_photos(user_id, position);
create index if not exists idx_profile_photos_user on public.profile_photos(user_id);
create index if not exists idx_profile_socials_user on public.profile_socials(user_id);
create index if not exists idx_profile_interests_user on public.profile_interests(user_id);
create index if not exists idx_discovery_preferences_user on public.discovery_preferences(user_id);
create index if not exists idx_user_locations_user on public.user_locations(user_id);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user on public.notifications(user_id);

alter table public.profiles enable row level security;
alter table public.interest_categories enable row level security;
alter table public.interests enable row level security;
alter table public.profile_interests enable row level security;
alter table public.profile_photos enable row level security;
alter table public.profile_socials enable row level security;
alter table public.discovery_preferences enable row level security;
alter table public.user_locations enable row level security;

create policy "Profiles publics visibles" on public.profiles
for select using (true);

create policy "Users can insert own profile" on public.profiles
for insert with check (auth.uid() = id);

create policy "Users can update own profile" on public.profiles
for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "Users can delete own profile" on public.profiles
for delete using (auth.uid() = id);

create policy "Interests read public" on public.interests
for select using (true);

create policy "Categories read public" on public.interest_categories
for select using (true);

create policy "Users can view own interests" on public.profile_interests
for select using (auth.uid() = user_id);

create policy "Users can insert own interests" on public.profile_interests
for insert with check (auth.uid() = user_id);

create policy "Users can update own interests" on public.profile_interests
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can delete own interests" on public.profile_interests
for delete using (auth.uid() = user_id);

create policy "Users can manage own photos" on public.profile_photos
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can manage own socials" on public.profile_socials
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can manage own discovery preferences" on public.discovery_preferences
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users can manage own locations" on public.user_locations
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute procedure public.handle_updated_at();

create policy "No direct client access to notifications" on public.notifications
for all using (false) with check (false);

create trigger set_profile_photos_updated_at
before update on public.profile_photos
for each row execute procedure public.handle_updated_at();

create trigger set_profile_socials_updated_at
before update on public.profile_socials
for each row execute procedure public.handle_updated_at();

create trigger set_discovery_preferences_updated_at
before update on public.discovery_preferences
for each row execute procedure public.handle_updated_at();

create trigger set_user_locations_updated_at
before update on public.user_locations
for each row execute procedure public.handle_updated_at();
