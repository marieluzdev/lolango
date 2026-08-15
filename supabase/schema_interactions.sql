-- Table interactions
create table if not exists public.interactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  target_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('like', 'pass')),
  created_at timestamptz not null default now(),
  unique (user_id, target_id)
);

-- Table matches
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user1_id uuid not null references auth.users(id) on delete cascade,
  user2_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Index
create index if not exists idx_interactions_user on public.interactions(user_id);
create index if not exists idx_interactions_target on public.interactions(target_id);
create index if not exists idx_matches_user1 on public.matches(user1_id);
create index if not exists idx_matches_user2 on public.matches(user2_id);

-- RLS Interactions & Matches
alter table public.interactions enable row level security;
alter table public.matches enable row level security;

-- Policies interactions
drop policy if exists "Users can read own interactions" on public.interactions;
create policy "Users can read own interactions" on public.interactions
for select using (auth.uid() = user_id);

drop policy if exists "Users can read interactions targeting them" on public.interactions;
create policy "Users can read interactions targeting them" on public.interactions
for select using (auth.uid() = target_id);

drop policy if exists "Users can insert own interactions" on public.interactions;
create policy "Users can insert own interactions" on public.interactions
for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own interactions" on public.interactions;
create policy "Users can update own interactions" on public.interactions
for update using (auth.uid() = user_id);

-- Policies matches
drop policy if exists "Users can read own matches" on public.matches;
create policy "Users can read own matches" on public.matches
for select using (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "Users can insert matches" on public.matches;
create policy "Users can insert matches" on public.matches
for insert with check (auth.uid() = user1_id or auth.uid() = user2_id);

-- Fix policy notifications to allow insert from client (for now)
drop policy if exists "No direct client access to notifications" on public.notifications;

create policy "Users can insert notifications" on public.notifications
for insert with check (true); 

-- Optionally, fix profile_interests so users can see each other's interests
drop policy if exists "Users can view own interests" on public.profile_interests;
create policy "Interests are public" on public.profile_interests
for select using (true);
