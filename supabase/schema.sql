-- Reference schema for the simplified Supabase chat database.
-- This file documents the current structure and is not an automatic migration.

create table public.profiles (
  id uuid primary key references auth.users(id),
  username text not null unique,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  is_group boolean not null default false,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.room_members (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id),
  primary key (room_id, user_id)
);

create table public.messages (
  id uuid primary key,
  room_id uuid not null references public.rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  content text not null check (length(btrim(content)) > 0),
  created_at timestamptz not null default now()
);

comment on table public.profiles is
  'Public chat profiles linked to Supabase Auth. Stores username and avatar URL, but no passwords.';

comment on table public.rooms is
  'Stores private and group chat rooms. is_group determines the room type.';

comment on table public.room_members is
  'Connects users with chat rooms. Each user can be a member of a room only once.';

comment on table public.messages is
  'Stores readable chat messages. Only room members may read or send messages.';

-- These helpers avoid recursive RLS checks on rooms and room_members.
create or replace function public.is_room_member(check_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.room_members
    where room_id = check_room_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.is_room_creator(check_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.rooms
    where id = check_room_id
      and created_by = auth.uid()
  );
$$;

-- New Supabase Auth users automatically receive a simple chat profile.
create or replace function public.create_profile_after_signup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, 'user_' || left(new.id::text, 8))
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists create_profile_after_signup on auth.users;

create trigger create_profile_after_signup
  after insert on auth.users
  for each row execute function public.create_profile_after_signup();
