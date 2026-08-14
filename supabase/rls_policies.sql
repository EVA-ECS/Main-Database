-- Current RLS configuration from the Supabase WebUI.
-- This file documents the production policies and is not an automatic migration.

ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_public_key ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_room ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_key_envelope ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_ack ENABLE ROW LEVEL SECURITY;

CREATE POLICY profile_read
ON public.user_profile
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY public_key_read
ON public.user_public_key
FOR SELECT
TO authenticated
USING (status = 'active');

CREATE POLICY room_read
ON public.chat_room
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.room_member rm
    WHERE rm.room_id = chat_room.room_id
      AND rm.user_id = auth.uid()
      AND rm.status = 'active'
  )
);

CREATE POLICY membership_read
ON public.room_member
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY message_read
ON public.message
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.room_member rm
    WHERE rm.room_id = message.room_id
      AND rm.user_id = auth.uid()
      AND rm.status = 'active'
  )
);

CREATE POLICY message_key_read
ON public.message_key_envelope
FOR SELECT
TO authenticated
USING (auth.uid() = recipient_user_id);

CREATE POLICY ack_read
ON public.system_ack
FOR SELECT
TO authenticated
USING (auth.uid() = recipient_user_id);
