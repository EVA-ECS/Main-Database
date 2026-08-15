-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.user_profile (
  user_id uuid NOT NULL,
  username text NOT NULL UNIQUE,
  display_name text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT user_profile_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.user_public_key (
  key_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  purpose text NOT NULL CHECK (purpose = ANY (ARRAY['key_agreement'::text, 'signing'::text])),
  algorithm text NOT NULL,
  public_key bytea NOT NULL,
  fingerprint text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'revoked'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  revoked_at timestamp with time zone,
  CONSTRAINT user_public_key_pkey PRIMARY KEY (key_id),
  CONSTRAINT user_public_key_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(user_id)
);
CREATE TABLE public.chat_room (
  room_id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_type text NOT NULL CHECK (room_type = ANY (ARRAY['private'::text, 'group'::text])),
  name text,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  deleted_at timestamp with time zone,
  CONSTRAINT chat_room_pkey PRIMARY KEY (room_id),
  CONSTRAINT chat_room_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.user_profile(user_id)
);
CREATE TABLE public.room_member (
  membership_id uuid NOT NULL DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL,
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'left'::text])),
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  left_at timestamp with time zone,
  CONSTRAINT room_member_pkey PRIMARY KEY (membership_id),
  CONSTRAINT room_member_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_room(room_id),
  CONSTRAINT room_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profile(user_id)
);
CREATE TABLE public.message (
  message_id uuid NOT NULL,
  stored_seq bigint GENERATED ALWAYS AS IDENTITY NOT NULL UNIQUE,
  room_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  sender_signing_key_id uuid NOT NULL,
  target_type text NOT NULL CHECK (target_type = ANY (ARRAY['private'::text, 'group'::text])),
  target_id uuid NOT NULL,
  client_timestamp_ms bigint NOT NULL,
  iv bytea NOT NULL,
  ciphertext bytea NOT NULL,
  signature bytea NOT NULL,
  stored_at timestamp with time zone NOT NULL DEFAULT now(),
  delete_after timestamp with time zone NOT NULL DEFAULT (now() + '30 days'::interval),
  CONSTRAINT message_pkey PRIMARY KEY (message_id),
  CONSTRAINT message_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.chat_room(room_id),
  CONSTRAINT message_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_profile(user_id),
  CONSTRAINT message_sender_signing_key_id_sender_id_fkey FOREIGN KEY (sender_signing_key_id) REFERENCES public.user_public_key(key_id),
  CONSTRAINT message_sender_signing_key_id_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.user_public_key(user_id)
);
CREATE TABLE public.message_key_envelope (
  message_id uuid NOT NULL,
  recipient_user_id uuid NOT NULL,
  encrypted_key bytea NOT NULL,
  algorithm text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT message_key_envelope_pkey PRIMARY KEY (message_id, recipient_user_id),
  CONSTRAINT message_key_envelope_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.message(message_id),
  CONSTRAINT message_key_envelope_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.user_profile(user_id)
);
CREATE TABLE public.system_ack (
  ack_id uuid NOT NULL DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL,
  ack_type text NOT NULL CHECK (ack_type = ANY (ARRAY['server_ack'::text, 'delivery_ack'::text])),
  recipient_user_id uuid NOT NULL,
  occurred_at timestamp with time zone NOT NULL DEFAULT now(),
  delete_after timestamp with time zone NOT NULL DEFAULT (now() + '30 days'::interval),
  CONSTRAINT system_ack_pkey PRIMARY KEY (ack_id),
  CONSTRAINT system_ack_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.message(message_id),
  CONSTRAINT system_ack_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES public.user_profile(user_id)
);
