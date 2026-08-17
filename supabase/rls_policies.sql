-- RLS reference for the simplified Supabase chat database.
-- The policies use the signed-in user's auth.uid().

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_members enable row level security;
alter table public.messages enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.rooms from anon, authenticated;
revoke all on table public.room_members from anon, authenticated;
revoke all on table public.messages from anon, authenticated;

grant select, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.rooms to authenticated;
grant select, insert, delete on table public.room_members to authenticated;
grant select, insert on table public.messages to authenticated;

revoke all on function public.is_room_member(uuid) from public;
revoke all on function public.is_room_creator(uuid) from public;
grant execute on function public.is_room_member(uuid) to authenticated;
grant execute on function public.is_room_creator(uuid) to authenticated;

drop policy if exists profiles_read on public.profiles;
create policy profiles_read
on public.profiles for select
to authenticated
using (true);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists rooms_read on public.rooms;
create policy rooms_read
on public.rooms for select
to authenticated
using (
  created_by = auth.uid()
  or public.is_room_member(id)
);

drop policy if exists rooms_insert_own on public.rooms;
create policy rooms_insert_own
on public.rooms for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists rooms_update_created on public.rooms;
create policy rooms_update_created
on public.rooms for update
to authenticated
using (created_by = auth.uid())
with check (created_by = auth.uid());

drop policy if exists rooms_delete_created on public.rooms;
create policy rooms_delete_created
on public.rooms for delete
to authenticated
using (created_by = auth.uid());

drop policy if exists room_members_read on public.room_members;
create policy room_members_read
on public.room_members for select
to authenticated
using (
  public.is_room_creator(room_id)
  or public.is_room_member(room_id)
);

drop policy if exists room_members_insert_creator on public.room_members;
create policy room_members_insert_creator
on public.room_members for insert
to authenticated
with check (public.is_room_creator(room_id));

drop policy if exists room_members_delete_creator_or_self on public.room_members;
create policy room_members_delete_creator_or_self
on public.room_members for delete
to authenticated
using (
  public.is_room_creator(room_id)
  or user_id = auth.uid()
);

drop policy if exists messages_read on public.messages;
create policy messages_read
on public.messages for select
to authenticated
using (public.is_room_member(room_id));

drop policy if exists messages_insert_own on public.messages;
create policy messages_insert_own
on public.messages for insert
to authenticated
with check (
  sender_id = auth.uid()
  and public.is_room_member(room_id)
);

-- Avatar files are public, but users can change files only in their own folder.
drop policy if exists avatars_read_public on storage.objects;
create policy avatars_read_public
on storage.objects for select
to public
using (bucket_id = 'avatars');

drop policy if exists avatars_insert_own on storage.objects;
create policy avatars_insert_own
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and name like auth.uid()::text || '/%'
);

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and name like auth.uid()::text || '/%'
)
with check (
  bucket_id = 'avatars'
  and name like auth.uid()::text || '/%'
);

drop policy if exists avatars_delete_own on storage.objects;
create policy avatars_delete_own
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and name like auth.uid()::text || '/%'
);
