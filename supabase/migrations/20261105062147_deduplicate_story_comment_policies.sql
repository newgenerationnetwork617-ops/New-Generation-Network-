-- Keep one least-privilege policy per action for story comments.
drop policy if exists community_story_comments_insert_active_member
  on public.community_story_comments;
drop policy if exists community_story_comments_delete_author_story_owner_admin
  on public.community_story_comments;
drop policy if exists community_story_comments_read_active_story
  on public.community_story_comments;
