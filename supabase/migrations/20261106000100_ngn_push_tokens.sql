-- Stores FCM registration tokens for public NGN app installations.
-- Tokens are write-only to app clients; only trusted server-side code should read
-- them and send Firebase Cloud Messaging requests.
create table if not exists public.ngn_push_tokens (
  installation_id uuid primary key,
  device_token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'other')),
  updated_at timestamptz not null default now(),
  constraint ngn_push_tokens_token_length
    check (char_length(device_token) between 20 and 4096)
);

create index if not exists ngn_push_tokens_updated_at_idx
  on public.ngn_push_tokens (updated_at desc);

alter table public.ngn_push_tokens enable row level security;

revoke all on table public.ngn_push_tokens from anon, authenticated;
grant insert, update on table public.ngn_push_tokens to anon, authenticated;

drop policy if exists ngn_push_tokens_client_insert
  on public.ngn_push_tokens;
create policy ngn_push_tokens_client_insert
  on public.ngn_push_tokens
  for insert to anon, authenticated
  with check (
    installation_id is not null
    and char_length(device_token) between 20 and 4096
  );

drop policy if exists ngn_push_tokens_client_update
  on public.ngn_push_tokens;
create policy ngn_push_tokens_client_update
  on public.ngn_push_tokens
  for update to anon, authenticated
  using (true)
  with check (
    installation_id is not null
    and char_length(device_token) between 20 and 4096
  );

-- Intentionally no SELECT or DELETE policy for app clients. FCM tokens must
-- never be exposed through public client queries.
