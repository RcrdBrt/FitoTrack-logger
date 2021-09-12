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

create or replace view training_duration as
(
select
        td_start.training_id as training_id,
        td_start.t as start_time,
        td_end.t as end_time,
        resolve_geo_location(td_start.geog) AS start_location,
        resolve_geo_location(td_end.geog) AS end_location,
        td_start.geog as start_location_point,
        td_end.geog as end_location_point,
        date_trunc('second'::text, td_end.t - td_start.t) AS duration
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
order by td_start.t asc
);

create or replace view training_info as
(select distinct
        td.t::date,
        date_trunc('second', training_duration.start_time::time) as start_time,
        date_trunc('second', training_duration.end_time::time) as end_time,
        training_duration.duration as duration,
        round(((t.moving_distance)/1000)::numeric, 2) as distance,
        round(( (t.moving_distance / 1000) / (select extract(epoch from training_duration.duration)/3600))::numeric, 1) as pace_kmh
    from training t
        join training_data td on (t.id = td.training_id)
        join training_duration on (t.id = training_duration.id)
order by td.t::date, date_trunc('second', training_duration.start_time::time) asc
);