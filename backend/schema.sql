-- MedGraph — Supabase PostgreSQL Schema
-- Run this in your Supabase SQL editor.

-- ─── Enums ────────────────────────────────────────────────────────────────────
create type user_role      as enum ('student', 'doctor');
create type user_status    as enum ('pending_verification', 'verified_student', 'verified_practitioner', 'suspended');
create type session_mode   as enum ('study', 'clinical', 'casual');
create type session_status as enum ('scheduled', 'active', 'completed', 'cancelled');
create type req_status     as enum ('pending', 'matched', 'expired', 'cancelled');
create type post_type      as enum ('rounds', 'cases', 'life');
create type media_type     as enum ('video', 'image', 'pdf');
create type payment_type   as enum ('pro_subscription', 'creator_subscription', 'consultation');
create type payment_status as enum ('pending', 'captured', 'failed', 'refunded');
create type sub_status     as enum ('active', 'cancelled', 'expired');
create type report_reason  as enum ('fake_doctor', 'inappropriate', 'spam', 'other');
create type mcq_answer     as enum ('a', 'b', 'c', 'd');
create type fame_tier      as enum ('none', 'rising', 'notable', 'top_educator', 'medgraph_fellow');
create type visibility     as enum ('public', 'connections', 'hidden');

-- ─── Users ────────────────────────────────────────────────────────────────────
create table users (
  id                      uuid primary key references auth.users on delete cascade,
  email                   text unique not null,
  phone                   text,
  role                    user_role not null default 'student',
  status                  user_status not null default 'pending_verification',
  full_name               text not null default '',
  avatar_url              text,
  college                 text,
  academic_year           int,
  city                    text,
  state                   text,
  specialty               text,
  hospital                text,
  mrn                     text,
  id_photo_url            text,
  years_experience        int,
  bio                     text check (char_length(bio) <= 300),
  is_pro                  boolean not null default false,
  pro_expires_at          timestamptz,
  follower_count          int not null default 0,
  following_count         int not null default 0,
  post_count              int not null default 0,
  current_streak          int not null default 0,
  longest_streak          int not null default 0,
  last_session_date       date,
  daily_sessions_count    int not null default 0,
  sessions_this_month     int not null default 0,
  topics_this_month       text[] not null default '{}',
  subscription_price      int,
  razorpay_subscription_id text,
  creator_plan_id         text,
  fame_tier               fame_tier not null default 'none',
  profile_visibility      visibility not null default 'public',
  handle                  text unique,
  fcm_token               text,
  created_at              timestamptz not null default now()
);

-- ─── Follows ─────────────────────────────────────────────────────────────────
create table follows (
  id           uuid primary key default gen_random_uuid(),
  follower_id  uuid not null references users on delete cascade,
  following_id uuid not null references users on delete cascade,
  created_at   timestamptz not null default now(),
  unique(follower_id, following_id)
);

-- ─── Session requests ─────────────────────────────────────────────────────────
create table session_requests (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references users on delete cascade,
  topic              text not null default '',
  date               date not null,
  time               time not null,
  mode               session_mode not null default 'study',
  status             req_status not null default 'pending',
  filters            jsonb not null default '{}',
  matched_session_id uuid references sessions(id),
  created_at         timestamptz not null default now()
);

-- ─── Sessions ────────────────────────────────────────────────────────────────
create table sessions (
  id               uuid primary key default gen_random_uuid(),
  user1_id         uuid not null references users on delete cascade,
  user2_id         uuid not null references users on delete cascade,
  room_id          text unique not null,
  topic            text not null default '',
  mode             session_mode not null default 'study',
  status           session_status not null default 'scheduled',
  started_at       timestamptz,
  ended_at         timestamptz,
  duration_minutes int,
  summary_notes    text,
  created_at       timestamptz not null default now()
);
-- Migration (run if sessions table already exists):
-- alter table sessions add column if not exists summary_notes text;

-- Fix forward reference in session_requests
alter table session_requests
  add constraint fk_matched_session
  foreign key (matched_session_id) references sessions(id);

-- ─── Posts ───────────────────────────────────────────────────────────────────
create table posts (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references users on delete cascade,
  type          post_type not null,
  content       text not null default '',
  media_url     text,
  media_type    media_type,
  topic_tag     text,
  like_count    int not null default 0,
  comment_count int not null default 0,
  view_count    int not null default 0,
  is_premium    boolean not null default false,
  -- MCQ fields (nullable — only set for case posts with polls)
  mcq_question      text,
  mcq_option_a      text,
  mcq_option_b      text,
  mcq_option_c      text,
  mcq_option_d      text,
  mcq_correct_answer mcq_answer,
  mcq_explanation   text,
  created_at    timestamptz not null default now()
);

-- ─── Post likes ──────────────────────────────────────────────────────────────
create table post_likes (
  user_id uuid not null references users on delete cascade,
  post_id uuid not null references posts on delete cascade,
  primary key (user_id, post_id)
);

-- ─── Comments ────────────────────────────────────────────────────────────────
create table comments (
  id                uuid primary key default gen_random_uuid(),
  post_id           uuid not null references posts on delete cascade,
  author_id         uuid not null references users on delete cascade,
  content           text not null,
  is_correct_answer boolean not null default false,
  created_at        timestamptz not null default now()
);

-- ─── Creator subscriptions ───────────────────────────────────────────────────
create table creator_subscriptions (
  id                       uuid primary key default gen_random_uuid(),
  subscriber_id            uuid not null references users on delete cascade,
  creator_id               uuid not null references users on delete cascade,
  razorpay_subscription_id text,
  status                   sub_status not null default 'active',
  created_at               timestamptz not null default now(),
  unique(subscriber_id, creator_id)
);

-- ─── Reports ─────────────────────────────────────────────────────────────────
create table reports (
  id               uuid primary key default gen_random_uuid(),
  reporter_id      uuid not null references users on delete cascade,
  reported_user_id uuid not null references users on delete cascade,
  reason           report_reason not null,
  note             text,
  created_at       timestamptz not null default now()
);

-- ─── Daily MCQ ───────────────────────────────────────────────────────────────
create table daily_mcq (
  id             uuid primary key default gen_random_uuid(),
  question       text not null,
  option_a       text not null,
  option_b       text not null,
  option_c       text not null,
  option_d       text not null,
  correct_answer mcq_answer not null,
  explanation    text,
  topic          text,
  posted_at      date unique,
  created_at     timestamptz not null default now()
);

-- ─── Consultation waitlist ────────────────────────────────────────────────────
create table consultation_waitlist (
  id             uuid primary key default gen_random_uuid(),
  doctor_id      uuid not null references users on delete cascade,
  patient_name   text not null,
  patient_email  text not null,
  reason         text,
  created_at     timestamptz not null default now()
);

-- ─── Weekly rankings ─────────────────────────────────────────────────────────
create table weekly_rankings (
  id         uuid primary key default gen_random_uuid(),
  doctor_id  uuid not null references users on delete cascade,
  specialty  text not null,
  rank       int not null,
  score      int not null,
  week_start date not null,
  created_at timestamptz not null default now()
);

-- ─── Payments ────────────────────────────────────────────────────────────────
create table payments (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid references users on delete set null,
  type                     payment_type,
  amount                   int not null,
  currency                 text not null default 'INR',
  razorpay_payment_id      text,
  razorpay_subscription_id text,
  status                   payment_status not null default 'pending',
  created_at               timestamptz not null default now()
);

-- ─── Indexes ─────────────────────────────────────────────────────────────────
create index idx_posts_type_created      on posts (type, created_at desc);
create index idx_posts_author            on posts (author_id);
create index idx_sessions_users          on sessions (user1_id, user2_id);
create index idx_session_requests_status on session_requests (status, date);
create index idx_follows_follower        on follows (follower_id);
create index idx_follows_following       on follows (following_id);
create index idx_users_handle            on users (handle);
create index idx_users_role_status       on users (role, status);

-- ─── Helper RPC functions (called from backend) ───────────────────────────────
create or replace function increment_post_count(uid uuid)
returns void language sql as $$
  update users set post_count = post_count + 1 where id = uid;
$$;

create or replace function increment_like_count(pid uuid)
returns void language sql as $$
  update posts set like_count = like_count + 1 where id = pid;
$$;

create or replace function decrement_like_count(pid uuid)
returns void language sql as $$
  update posts set like_count = greatest(0, like_count - 1) where id = pid;
$$;

create or replace function increment_comment_count(pid uuid)
returns void language sql as $$
  update posts set comment_count = comment_count + 1 where id = pid;
$$;

create or replace function increment_follower_count(uid uuid)
returns void language sql as $$
  update users set follower_count = follower_count + 1 where id = uid;
$$;

create or replace function decrement_follower_count(uid uuid)
returns void language sql as $$
  update users set follower_count = greatest(0, follower_count - 1) where id = uid;
$$;

create or replace function increment_following_count(uid uuid)
returns void language sql as $$
  update users set following_count = following_count + 1 where id = uid;
$$;

create or replace function decrement_following_count(uid uuid)
returns void language sql as $$
  update users set following_count = greatest(0, following_count - 1) where id = uid;
$$;

-- Row Level Security

alter table users enable row level security;
alter table posts enable row level security;
alter table post_likes enable row level security;
alter table comments enable row level security;
alter table follows enable row level security;
alter table sessions enable row level security;
alter table session_requests enable row level security;
alter table creator_subscriptions enable row level security;
alter table reports enable row level security;
alter table payments enable row level security;

-- users
create policy "users_select_public" on users for select using (profile_visibility <> 'hidden');
create policy "users_update_own" on users for update using (auth.uid() = id) with check (auth.uid() = id);

-- posts
create policy "posts_select_all" on posts for select using (not is_premium or auth.uid() is not null);
create policy "posts_insert_own" on posts for insert with check (auth.uid() = author_id);
create policy "posts_update_own" on posts for update using (auth.uid() = author_id) with check (auth.uid() = author_id);
create policy "posts_delete_own" on posts for delete using (auth.uid() = author_id);

-- post_likes
create policy "post_likes_select" on post_likes for select using (auth.uid() is not null);
create policy "post_likes_insert" on post_likes for insert with check (auth.uid() = user_id);
create policy "post_likes_delete" on post_likes for delete using (auth.uid() = user_id);

-- comments
create policy "comments_select_all" on comments for select using (true);
create policy "comments_insert_own" on comments for insert with check (auth.uid() = author_id);
create policy "comments_delete_own" on comments for delete using (auth.uid() = author_id);

-- follows
create policy "follows_select_all" on follows for select using (true);
create policy "follows_insert_own" on follows for insert with check (auth.uid() = follower_id);
create policy "follows_delete_own" on follows for delete using (auth.uid() = follower_id);

-- sessions
create policy "sessions_select_participants" on sessions for select using (auth.uid() = user1_id or auth.uid() = user2_id);

-- session_requests
create policy "session_requests_select_own" on session_requests for select using (auth.uid() = user_id);
create policy "session_requests_insert_own" on session_requests for insert with check (auth.uid() = user_id);
create policy "session_requests_update_own" on session_requests for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- creator_subscriptions
create policy "creator_subscriptions_select_parties" on creator_subscriptions for select using (auth.uid() = subscriber_id or auth.uid() = creator_id);
create policy "creator_subscriptions_insert_subscriber" on creator_subscriptions for insert with check (auth.uid() = subscriber_id);

-- reports
create policy "reports_insert_own" on reports for insert with check (auth.uid() = reporter_id);

-- payments
create policy "payments_select_own" on payments for select using (auth.uid() = user_id);
