# Database Model

This model shows the relational structure currently implemented in Supabase.

```mermaid
erDiagram
    AUTH_USERS ||--|| USER_PROFILE : "owns profile"
    USER_PROFILE ||--o{ USER_PUBLIC_KEY : "has keys"
    USER_PROFILE ||--o{ CHAT_ROOM : "creates"
    CHAT_ROOM ||--o{ ROOM_MEMBER : "has members"
    USER_PROFILE ||--o{ ROOM_MEMBER : "joins"
    CHAT_ROOM ||--o{ MESSAGE : "contains"
    USER_PROFILE ||--o{ MESSAGE : "sends"
    USER_PUBLIC_KEY ||--o{ MESSAGE : "signs"
    MESSAGE ||--o{ MESSAGE_KEY_ENVELOPE : "has key envelopes"
    USER_PROFILE ||--o{ MESSAGE_KEY_ENVELOPE : "receives key"
    MESSAGE ||--o{ SYSTEM_ACK : "has acknowledgements"
    USER_PROFILE ||--o{ SYSTEM_ACK : "receives acknowledgement"

    AUTH_USERS {
        uuid id PK
    }

    USER_PROFILE {
        uuid user_id PK, FK
        text username UK
        text display_name
        timestamptz created_at
        timestamptz deleted_at
    }

    USER_PUBLIC_KEY {
        uuid key_id PK
        uuid user_id FK
        text purpose
        text algorithm
        bytea public_key
        text fingerprint UK
        text status
        timestamptz created_at
        timestamptz revoked_at
    }

    CHAT_ROOM {
        uuid room_id PK
        text room_type
        text name
        uuid created_by FK
        timestamptz created_at
        timestamptz deleted_at
    }

    ROOM_MEMBER {
        uuid membership_id PK
        uuid room_id FK
        uuid user_id FK
        text status
        timestamptz joined_at
        timestamptz left_at
    }

    MESSAGE {
        uuid message_id PK
        bigint stored_seq UK
        uuid room_id FK
        uuid sender_id FK
        uuid sender_signing_key_id FK
        text target_type
        uuid target_id
        bigint client_timestamp_ms
        bytea iv
        bytea ciphertext
        bytea signature
        timestamptz stored_at
        timestamptz delete_after
    }

    MESSAGE_KEY_ENVELOPE {
        uuid message_id PK, FK
        uuid recipient_user_id PK, FK
        bytea encrypted_key
        text algorithm
        timestamptz created_at
    }

    SYSTEM_ACK {
        uuid ack_id PK
        uuid message_id FK
        text ack_type
        uuid recipient_user_id FK
        timestamptz occurred_at
        timestamptz delete_after
    }
```

Notes:

- Supabase Auth stores identities in `auth.users`.
- Message content and per-recipient keys are stored separately.
- There is no central room key.
- `system_ack` contains only server and delivery acknowledgements; there is no read acknowledgement.
- Messages and acknowledgements have a default retention period of 30 days.
- RLS policies are documented in [`../supabase/rls_policies.sql`](../supabase/rls_policies.sql).
