-- Holy Word [NGN] community message editing support.
-- Run this migration in the Supabase SQL Editor before using Edit message.

ALTER TABLE public.community_messages
  ADD COLUMN IF NOT EXISTS edited_at timestamptz;

-- Restrict the update grant to the two fields the edit feature actually changes.
GRANT UPDATE (body, edited_at) ON TABLE public.community_messages TO authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'community_messages'
      AND policyname = 'community_messages_update_own'
  ) THEN
    CREATE POLICY community_messages_update_own
      ON public.community_messages
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = author_id)
      WITH CHECK (auth.uid() = author_id);
  END IF;
END
$$;
