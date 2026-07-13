-- gymgyme koç — ortak damlahelloworld Supabase projesinde çalıştır (SQL editor).
-- Tablolar gg_ ön ekli, çünkü proje başka app'lerle paylaşımlı (çakışma olmasın).
-- Kamera/video ASLA buraya gelmez; sadece seansın sayıları saklanır. RLS ile
-- her kullanıcı yalnız kendi seanslarını görebilir/yazabilir/silebilir.

-- ── koç seansları ────────────────────────────────────────────────────────────
create table if not exists public.gg_coach_sessions (
  id               bigint generated always as identity primary key,
  user_id          uuid not null default auth.uid() references auth.users (id) on delete cascade,
  move             text not null,
  reps             int  not null default 0,
  sets             int  not null default 0,
  avg_score        int,
  best_score       int,
  clean_reps       int  not null default 0,
  half_reps        int  not null default 0,
  duration_sec     numeric not null default 0,
  workout_complete boolean not null default false,
  created_at       timestamptz not null default now()
);

create index if not exists gg_coach_sessions_user_time
  on public.gg_coach_sessions (user_id, created_at desc);

alter table public.gg_coach_sessions enable row level security;

-- yalnız kendi satırların: oku / ekle / sil (tam CRUD, geri alınabilir).
drop policy if exists gg_sessions_select on public.gg_coach_sessions;
create policy gg_sessions_select on public.gg_coach_sessions
  for select using (auth.uid() = user_id);

drop policy if exists gg_sessions_insert on public.gg_coach_sessions;
create policy gg_sessions_insert on public.gg_coach_sessions
  for insert with check (auth.uid() = user_id);

drop policy if exists gg_sessions_delete on public.gg_coach_sessions;
create policy gg_sessions_delete on public.gg_coach_sessions
  for delete using (auth.uid() = user_id);
