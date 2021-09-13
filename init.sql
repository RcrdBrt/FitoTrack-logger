create table if not exists training(
    id uuid primary key default gen_random_uuid(),
    owner varchar(255) not null,
    filename text not null,
    type varchar(255) not null,
    description text not null,
    moving_time float not null,
    stopped_time float not null,
    moving_distance float not null,
    stopped_distance float not null,
    data jsonb not null default '{}'
);

create table if not exists training_data(
    training_id uuid not null,
    t timestamp with time zone not null,
    geog GEOGRAPHY(Point) not null, -- perf issues but don't care enough for geometry->projection->geography conversions
    speed float,
    elevation float not null,
    constraint fk_training_id foreign key(training_id) references training(id) on delete cascade
);
create index if not exists idx_training_data_t on training_data(t);
create index if not exists idx_training_data_training_id on training_data(training_id);
create index if not exists idx_training_data_geog on training_data using GIST(geog);

-- poor man's reverse geocoding
create or replace function resolve_geo_location(geography) returns text as $$
begin 
	case when st_dwithin($1, st_point(45.516114, 9.216108), 1000) then
			return 'Bicocca';
		when st_dwithin($1, st_point(45.058302, 11.644477), 2000) then
			return 'Villanova';
		when st_dwithin($1, st_point(45.106055, 11.794563), 2000) then
			return 'Boara';
		when st_dwithin($1, st_point(45.610874, 9.522227), 2000) then
			return 'Trezzo sull` Adda';
		when st_dwithin($1, st_point(45.645741, 9.265780), 2000) then
			return 'Sovico';
		when st_dwithin($1, st_point(45.588173, 9.275549), 3000) then
			return 'Monza';
	else
		return 'unknown';
	end case;
end
$$ language plpgsql immutable;

create or replace view training_info as
(
select
        td_start.training_id as training_id,
        td_start.t as start_time,
        td_end.t as end_time,
        resolve_geo_location(td_start.geog) AS start_location,
        resolve_geo_location(td_end.geog) AS end_location,
        date_trunc('second'::text, td_end.t - td_start.t) AS duration,
        round(((t.moving_distance)/1000)::numeric, 2) as distance,
        round(( (t.moving_distance / 1000) / (select extract(epoch from date_trunc('second'::text, td_end.t - td_start.t))/3600))::numeric, 1) as pace_kmh
    from
    (
        select distinct on (td2.training_id) *
                from training_data td2 order by td2.training_id, t asc
    ) td_start
    join
    (
        select distinct on (td2.training_id) *
                from training_data td2 order by td2.training_id, t desc
    ) td_end
    on (td_start.training_id = td_end.training_id)
    join training t on (t.id = td_start.training_id)
order by td_start.t asc
);

---------------------------------------------
-- trovare allenamenti usando georeference --
---------------------------------------------
-- COSTANTI
-- via mirabello (dentro al parco): st_point(45.607115, 9.283687)
-- rotatoria Tamoil (per la via del nord): st_point(45.622779, 9.276274)

-- giro del parco di monza
create or replace view parco_monza_classico as
(
    select duration,
            distance,
            pace_kmh,
            start_time,
            end_time,
            start_location,
            end_location,
            training_id
        from training_info ti
    where ti.training_id in (
        -- trovo id allenamenti che passano sicuramente per il parco di monza
        select distinct t.id
            from training t
                join training_data td on (t.id = td.training_id)
                join training_data td2 using (training_id)
        where
            distance < 31 and
            st_dwithin(td.geog, st_point(45.607115, 9.283687), 20) -- se passo a 20 metri da via mirabello dentro al parco
            and not st_dwithin(td2.geog, st_point(45.622779, 9.276274), 20) -- e se non passo dal tamoil
    )
);

-- giro di arcore
create or replace view arcore as
(
    select duration,
            distance,
            pace_kmh,
            start_time,
            end_time,
            start_location,
            end_location,
            training_id
        from training_info ti
    where ti.training_id in (
        -- trovo id allenamenti che passano sicuramente per il parco di monza
        select td.training_id
        from training_data td join training_data td2 using (training_id)
        where
            distance < 42 and
            end_location = 'Bicocca' and
            st_dwithin(td.geog, st_point(45.622779, 9.276274), 20) -- se passo a 20 metri dal Tamoil
            and st_dwithin(td2.geog, st_point(45.631299, 9.308985), 30) -- e se passo a 30 metri dalla rotatoria per arcore
    )
);