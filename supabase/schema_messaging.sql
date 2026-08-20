-- Table conversations
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  match_id uuid unique not null references public.matches(id) on delete cascade,
  user1_id uuid not null references auth.users(id) on delete cascade,
  user2_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Table messages
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  type text not null default 'text' check (type in ('text', 'social_share')),
  metadata jsonb default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

-- Index
create index if not exists idx_conversations_user1 on public.conversations(user1_id);
create index if not exists idx_conversations_user2 on public.conversations(user2_id);
create index if not exists idx_conversations_match on public.conversations(match_id);
create index if not exists idx_messages_conversation on public.messages(conversation_id);
create index if not exists idx_messages_sender on public.messages(sender_id);

-- RLS
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

-- Policies Conversations
drop policy if exists "Users can read own conversations" on public.conversations;
create policy "Users can read own conversations" on public.conversations
for select using (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "Users can insert conversations" on public.conversations;
create policy "Users can insert conversations" on public.conversations
for insert with check (auth.uid() = user1_id or auth.uid() = user2_id);

drop policy if exists "Users can update own conversations" on public.conversations;
create policy "Users can update own conversations" on public.conversations
for update using (auth.uid() = user1_id or auth.uid() = user2_id);

-- Policies Messages
drop policy if exists "Users can read messages in their conversations" on public.messages;
create policy "Users can read messages in their conversations" on public.messages
for select using (
  exists (
    select 1 from public.conversations c 
    where c.id = messages.conversation_id 
    and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
  )
);

drop policy if exists "Users can insert messages in their conversations" on public.messages;
create policy "Users can insert messages in their conversations" on public.messages
for insert with check (
  auth.uid() = sender_id and 
  exists (
    select 1 from public.conversations c 
    where c.id = conversation_id 
    and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
  )
);

drop policy if exists "Users can update their received messages (to mark as read)" on public.messages;
create policy "Users can update their received messages" on public.messages
for update using (
  auth.uid() != sender_id and 
  exists (
    select 1 from public.conversations c 
    where c.id = conversation_id 
    and (c.user1_id = auth.uid() or c.user2_id = auth.uid())
  )
);

-- Trigger updated_at pour conversations
create trigger set_conversations_updated_at
before update on public.conversations
for each row execute procedure public.handle_updated_at();

-- Enable Realtime
alter publication supabase_realtime add table public.conversations;
alter publication supabase_realtime add table public.messages;
