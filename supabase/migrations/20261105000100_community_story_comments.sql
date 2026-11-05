-- Story comments are public replies attached to a story, not private messages.
create table if not exists public.community_story_comments (
  id uuid primary key default gen_random_uuid(),
  story_id uuid not null references public.community_stories(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  constraint community_story_comments_body_length
    check (char_length(btrim(body)) between 1 and 500)
);

create index if not exists community_story_comments_story_created_idx
  on public.community_story_comments (story_id, created_at asc);
create index if not exists community_story_comments_author_idx
  on public.community_story_comments (author_id);

alter table public.community_story_comments enable row level security;
revoke all on table public.community_story_comments from anon, authenticated;
grant select, insert, delete on table public.community_story_comments to authenticated;

create policy community_story_comments_read_active_or_owner
  on public.community_story_comments
  for select to authenticated
  using (
    exists (
      select 1
      from public.community_stories s
      where s.id = community_story_comments.story_id
        and (
          s.expires_at > now()
          or s.author_id = (select auth.uid())
          or (select public.is_admin())
        )
    )
  );

create policy community_story_comments_insert_member
  on public.community_story_comments
  for insert to authenticated
  with check (
    author_id = (select auth.uid())
    and coalesce(((select auth.jwt()) ->> 'is_anonymous')::boolean, false) = false
    and exists (
      select 1
      from public.community_stories s
      join public.profiles p on p.id = (select auth.uid())
      where s.id = community_story_comments.story_id
        and s.expires_at > now()
        and s.author_id <> (select auth.uid())
        and p.is_muted = false
        and p.is_banned = false
    )
  );

create policy community_story_comments_delete_author_owner_admin
  on public.community_story_comments
  for delete to authenticated
  using (
    author_id = (select auth.uid())
    or exists (
      select 1
      from public.community_stories s
      where s.id = community_story_comments.story_id
        and (
          s.author_id = (select auth.uid())
          or (select public.is_admin())
        )
    )
  );
