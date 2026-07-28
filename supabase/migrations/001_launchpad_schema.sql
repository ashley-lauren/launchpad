create extension if not exists "pgcrypto";

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  name text not null,
  table_number int not null,
  points int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.warmups (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  prompt text not null,
  agenda jsonb not null default '[]'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.submissions (
  id uuid primary key default gen_random_uuid(),
  warmup_id uuid not null references public.warmups(id) on delete cascade,
  team_id uuid not null references public.teams(id) on delete cascade,
  answer text not null,
  confidence text not null check (confidence in ('Low', 'Medium', 'High')),
  client_generated_id text not null unique,
  submitted_at timestamptz not null default now(),
  synced_at timestamptz null,
  unique (warmup_id, team_id)
);

create table if not exists public.point_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  warmup_id uuid not null references public.warmups(id) on delete cascade,
  reason text not null,
  points int not null,
  client_generated_id text not null unique,
  created_at timestamptz not null default now(),
  synced_at timestamptz null
);

create or replace function public.record_point_event_once(
  event_id uuid,
  target_team_id uuid,
  target_warmup_id uuid,
  event_reason text,
  point_delta int,
  event_client_generated_id text,
  event_created_at timestamptz
) returns boolean
language plpgsql
as $$
declare
  inserted_count int;
begin
  insert into public.point_events (
    id,
    team_id,
    warmup_id,
    reason,
    points,
    client_generated_id,
    created_at,
    synced_at
  )
  values (
    event_id,
    target_team_id,
    target_warmup_id,
    event_reason,
    point_delta,
    event_client_generated_id,
    event_created_at,
    now()
  )
  on conflict (client_generated_id) do nothing;

  get diagnostics inserted_count = row_count;

  if inserted_count = 1 then
    update public.teams
    set points = points + point_delta,
        updated_at = now()
    where id = target_team_id;
  end if;

  return inserted_count = 1;
end;
$$;

alter table public.classes enable row level security;
alter table public.teams enable row level security;
alter table public.warmups enable row level security;
alter table public.submissions enable row level security;
alter table public.point_events enable row level security;

create policy "MVP public read classes" on public.classes for select using (true);
create policy "MVP public write classes" on public.classes for all using (true) with check (true);

create policy "MVP public read teams" on public.teams for select using (true);
create policy "MVP public write teams" on public.teams for all using (true) with check (true);

create policy "MVP public read warmups" on public.warmups for select using (true);
create policy "MVP public write warmups" on public.warmups for all using (true) with check (true);

create policy "MVP public read submissions" on public.submissions for select using (true);
create policy "MVP public write submissions" on public.submissions for all using (true) with check (true);

create policy "MVP public read point_events" on public.point_events for select using (true);
create policy "MVP public write point_events" on public.point_events for all using (true) with check (true);

insert into public.classes (id, name)
values ('00000000-0000-4000-8000-000000000001', 'STEM Studio - Period 3')
on conflict (id) do nothing;

insert into public.teams (id, class_id, name, table_number, points)
values
  ('00000000-0000-4000-8000-000000000200', '00000000-0000-4000-8000-000000000001', 'Table 1', 1, 12),
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000001', 'Table 2', 2, 9),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000001', 'Table 3', 3, 11),
  ('00000000-0000-4000-8000-000000000203', '00000000-0000-4000-8000-000000000001', 'Table 4', 4, 8),
  ('00000000-0000-4000-8000-000000000204', '00000000-0000-4000-8000-000000000001', 'Table 5', 5, 10),
  ('00000000-0000-4000-8000-000000000205', '00000000-0000-4000-8000-000000000001', 'Table 6', 6, 7)
on conflict (id) do nothing;

insert into public.warmups (id, class_id, prompt, agenda, active)
values (
  '00000000-0000-4000-8000-000000000101',
  '00000000-0000-4000-8000-000000000001',
  'A rover has 20 minutes of battery left and three samples to collect. What should its algorithm prioritize, and why?',
  '["Warm-up reasoning sprint", "Prototype sensor decision trees", "Gallery walk and feedback", "Exit reflection"]'::jsonb,
  true
)
on conflict (id) do nothing;
