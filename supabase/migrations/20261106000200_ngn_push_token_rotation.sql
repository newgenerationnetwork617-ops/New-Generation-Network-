-- Allow a device installation to rotate FCM tokens without requiring
-- client-side SELECT access to the token table. Each fresh token is an insert;
-- stale tokens are removed by the trusted sender after FCM reports UNREGISTERED.
alter table public.ngn_push_tokens
  add column if not exists id uuid default gen_random_uuid();

update public.ngn_push_tokens set id = gen_random_uuid() where id is null;

alter table public.ngn_push_tokens
  alter column id set not null;

alter table public.ngn_push_tokens
  drop constraint if exists ngn_push_tokens_pkey;

alter table public.ngn_push_tokens
  add constraint ngn_push_tokens_pkey primary key (id);

create index if not exists ngn_push_tokens_installation_idx
  on public.ngn_push_tokens (installation_id);

-- Client roles can only add tokens. No client SELECT, UPDATE, or DELETE policy.
revoke all on table public.ngn_push_tokens from anon, authenticated;
grant insert on table public.ngn_push_tokens to anon, authenticated;

drop policy if exists ngn_push_tokens_client_update
  on public.ngn_push_tokens;
