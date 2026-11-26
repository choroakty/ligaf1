-- Uruchom raz w SQL Editor istniejącego projektu Supabase.
create table public.seasons (
  id bigint generated always as identity primary key,
  ended_at timestamptz not null default now(),
  scores jsonb not null
);
alter table public.seasons enable row level security;
grant select on public.seasons to authenticated;
create policy seasons_read on public.seasons for select to authenticated using (public.is_member());

create function public.finish_season() returns void
language plpgsql security definer set search_path = public as $$
declare final_scores jsonb;
begin
  if not public.is_admin() then
    raise exception 'Tylko administrator może zakończyć sezon.' using errcode = '42501';
  end if;
  lock table public.races, public.picks in share row exclusive mode;
  if not exists (select 1 from public.races) then
    raise exception 'Nie ma wyścigów do zakończenia sezonu.';
  end if;
  select jsonb_object_agg(t.name, t.points) into final_scores
  from (
    select p.name, coalesce(sum(
      case when r.result is not null and r.starts_at <= now() then
        (select count(*) from generate_series(1,10) i where k.positions[i] = r.result[i])
        + case when k.fastest = r.fastest then 1 else 0 end
      else 0 end
    ), 0) as points
    from public.profiles p
    left join public.picks k on k.user_id = p.id
    left join public.races r on r.id = k.race_id
    where not p.is_admin
    group by p.id, p.name
  ) t;
  if final_scores is null then
    raise exception 'Brak graczy do zapisania w archiwum.';
  end if;
  insert into public.seasons(scores) values (final_scores);
  delete from public.picks;
  delete from public.races;
end;
$$;
revoke all on function public.finish_season() from public;
grant execute on function public.finish_season() to authenticated;
