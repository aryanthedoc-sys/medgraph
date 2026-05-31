-- MedGraph Profile System Migration
-- Run this in Supabase SQL Editor

-- Blocks table
CREATE TABLE IF NOT EXISTS blocks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  blocker_id uuid REFERENCES users(id) ON DELETE CASCADE,
  blocked_id uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamp DEFAULT now(),
  UNIQUE(blocker_id, blocked_id)
);
ALTER TABLE blocks DISABLE ROW LEVEL SECURITY;

-- Vouches table
CREATE TABLE IF NOT EXISTS vouches (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  voucher_id uuid REFERENCES users(id) ON DELETE CASCADE,
  vouched_id uuid REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamp DEFAULT now(),
  UNIQUE(voucher_id, vouched_id)
);
ALTER TABLE vouches DISABLE ROW LEVEL SECURITY;

-- Add missing columns to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS tags text[],
  ADD COLUMN IF NOT EXISTS languages text[],
  ADD COLUMN IF NOT EXISTS phone text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS is_pro boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS pro_expires_at timestamp DEFAULT (now() + interval '3 months'),
  ADD COLUMN IF NOT EXISTS follower_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS following_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS session_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS streak_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS leaderboard_rank integer,
  ADD COLUMN IF NOT EXISTS vouch_count integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS profile_visibility text DEFAULT 'public',
  ADD COLUMN IF NOT EXISTS pro_filter_match_bds boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS pro_filter_same_college boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS pro_filter_same_city boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS pro_filter_same_state boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS show_online_status boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_session_count boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS neet_pg_target_year integer,
  ADD COLUMN IF NOT EXISTS years_of_experience integer;

-- Set all existing users to Pro free period (3 months from now)
UPDATE users SET
  is_pro = true,
  pro_expires_at = now() + interval '3 months'
WHERE pro_expires_at IS NULL OR pro_expires_at < now();

-- Increment/decrement RPC functions (idempotent)
CREATE OR REPLACE FUNCTION increment_follower_count(uid uuid)
RETURNS void LANGUAGE sql AS $$
  UPDATE users SET follower_count = COALESCE(follower_count, 0) + 1 WHERE id = uid;
$$;

CREATE OR REPLACE FUNCTION decrement_follower_count(uid uuid)
RETURNS void LANGUAGE sql AS $$
  UPDATE users SET follower_count = GREATEST(COALESCE(follower_count, 0) - 1, 0) WHERE id = uid;
$$;

CREATE OR REPLACE FUNCTION increment_following_count(uid uuid)
RETURNS void LANGUAGE sql AS $$
  UPDATE users SET following_count = COALESCE(following_count, 0) + 1 WHERE id = uid;
$$;

CREATE OR REPLACE FUNCTION decrement_following_count(uid uuid)
RETURNS void LANGUAGE sql AS $$
  UPDATE users SET following_count = GREATEST(COALESCE(following_count, 0) - 1, 0) WHERE id = uid;
$$;
