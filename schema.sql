-- Uruchom raz w SQL Editor nowego projektu Supabase.
create table public.profiles (id uuid primary key references auth.users on delete cascade, name text not null unique check(name in ('Piotr','Mateusz','Kacper','Admin')), is_admin boolean not null default false, check ((name = 'Admin') = is_admin));
create table public.drivers (id bigint generated always as identity primary key, name text not null unique, active boolean not null default true);
create table public.races (id bigint generated always as identity primary key, name text not null, starts_at timestamptz not null, result bigint[], fastest bigint references public.drivers(id), check ((result is null and fastest is null) or (cardinality(result) = 10 and fastest is not null)));
create table public.picks (race_id bigint not null references public.races(id), user_id uuid not null references public.profiles(id), positions bigint[] not null, fastest bigint not null references public.drivers(id), primary key (race_id,user_id), check (cardinality(positions)=10));

insert into public.drivers(name) values ('Max Verstappen'),('Yuki Tsunoda'),('Lando Norris'),('Oscar Piastri'),('Charles Leclerc'),('Lewis Hamilton'),('George Russell'),('Andrea Kimi Antonelli'),('Fernando Alonso'),('Lance Stroll'),('Pierre Gasly'),('Franco Colapinto'),('Alexander Albon'),('Carlos Sainz'),('Nico Hülkenberg'),('Gabriel Bortoleto'),('Liam Lawson'),('Isack Hadjar'),('Esteban Ocon'),('Oliver Bearman');

create function public.is_member() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from profiles where id=auth.uid()) $$;
create function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from profiles where id=auth.uid() and is_admin) $$;
create function public.valid_positions(p bigint[]) returns boolean language sql stable security definer set search_path=public as $$ select cardinality(p)=10 and (select count(distinct x)=10 and count(d.id)=10 from unnest(p) x left join drivers d on d.id=x) $$;
create function public.pick_status() returns table(race_id bigint, user_id uuid) language sql stable security definer set search_path=public as $$ select p.race_id,p.user_id from picks p where public.is_member() $$;
revoke all on function public.is_member(), public.is_admin(), public.valid_positions(bigint[]), public.pick_status() from public;
grant execute on function public.is_member(), public.is_admin(), public.valid_positions(bigint[]), public.pick_status() to authenticated;

alter table public.profiles enable row level security;
alter table public.drivers enable row level security;
alter table public.races enable row level security;
alter table public.picks enable row level security;
grant select on public.profiles,public.drivers,public.races,public.picks to authenticated;
grant insert,update on public.drivers,public.races,public.picks to authenticated;
grant usage,select on all sequences in schema public to authenticated;
create policy profiles_read on public.profiles for select to authenticated using (public.is_member());
create policy drivers_read on public.drivers for select to authenticated using (public.is_member());
create policy drivers_insert on public.drivers for insert to authenticated with check (public.is_admin());
create policy drivers_update on public.drivers for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy races_read on public.races for select to authenticated using (public.is_member());
create policy races_insert on public.races for insert to authenticated with check (public.is_admin() and result is null and fastest is null);
create policy races_update on public.races for update to authenticated using (public.is_admin()) with check (public.is_admin() and (result is null or (starts_at <= now() and public.valid_positions(result))));
create policy picks_read on public.picks for select to authenticated using (public.is_member() and (user_id=auth.uid() or exists(select 1 from public.races r where r.id=race_id and r.starts_at<=now())));
create policy picks_insert on public.picks for insert to authenticated with check (public.is_member() and not public.is_admin() and user_id=auth.uid() and public.valid_positions(positions) and exists(select 1 from public.races r where r.id=race_id and r.starts_at>now()));
create policy picks_update on public.picks for update to authenticated using (user_id=auth.uid() and exists(select 1 from public.races r where r.id=race_id and r.starts_at>now())) with check (public.is_member() and not public.is_admin() and user_id=auth.uid() and public.valid_positions(positions) and exists(select 1 from public.races r where r.id=race_id and r.starts_at>now()));

create function public.delete_race(p_race_id bigint) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.is_admin() then
    raise exception 'Tylko administrator może usuwać wyścigi.' using errcode = '42501';
  end if;
  perform 1 from public.races where id=p_race_id for update;
  if not found then raise exception 'Nie znaleziono wyścigu.'; end if;
  delete from public.picks where race_id=p_race_id;
  delete from public.races where id=p_race_id;
end;
$$;
revoke all on function public.delete_race(bigint) from public;
grant execute on function public.delete_race(bigint) to authenticated;

-- Archiwum zawiera wyłącznie końcową punktację sezonu.
create table public.seasons (id bigint generated always as identity primary key, ended_at timestamptz not null default now(), scores jsonb not null);
alter table public.seasons enable row level security;
grant select on public.seasons to authenticated;
create policy seasons_read on public.seasons for select to authenticated using (public.is_member());
create function public.finish_season() returns void language plpgsql security definer set search_path=public as $$
declare final_scores jsonb;
begin
  if not public.is_admin() then raise exception 'Tylko administrator może zakończyć sezon.' using errcode='42501'; end if;
  lock table public.races, public.picks in share row exclusive mode;
  if not exists (select 1 from public.races) then raise exception 'Nie ma wyścigów do zakończenia sezonu.'; end if;
  select jsonb_object_agg(t.name,t.points) into final_scores from (
    select p.name, coalesce(sum(case when r.result is not null and r.starts_at<=now() then
      (select count(*) from generate_series(1,10) i where k.positions[i]=r.result[i])
      + case when k.fastest=r.fastest then 1 else 0 end else 0 end),0) as points
    from public.profiles p left join public.picks k on k.user_id=p.id
    left join public.races r on r.id=k.race_id where not p.is_admin group by p.id,p.name
  ) t;
  if final_scores is null then raise exception 'Brak graczy do zapisania w archiwum.'; end if;
  insert into public.seasons(scores) values (final_scores);
  delete from public.picks;
  delete from public.races;
end;
$$;
revoke all on function public.finish_season() from public;
grant execute on function public.finish_season() to authenticated;
