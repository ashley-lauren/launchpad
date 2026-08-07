alter table if exists public.classroom_state
  add column if not exists current_phase_id text;

update public.classroom_state
set current_phase_id = null
where current_phase_id is null;
