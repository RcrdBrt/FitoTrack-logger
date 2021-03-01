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
create index if not exists idx_training_data_geog on training_data using GIST(geog);

create or replace view training_duration as
(select td_start.id as id,
	td_start.t as start_time,
	td_end.t as end_time,
	date_trunc('second', (td_end.t - td_start.t)) as duration
from (select td_row_n.t, td_row_n.id
		from (select *,
				row_number() over (partition by td.training_id order by td.t asc) as row_n
			from training_data td join training t on (t.id = td.training_id)
		order by td.t asc) as td_row_n
	where td_row_n.row_n = 1
	order by td_row_n.t asc) td_start
	
	join
	
	(select td_row_n.t, td_row_n.id
		from (select *,
				row_number() over (partition by td.training_id order by td.t desc) as row_n
			from training_data td join training t on (t.id = td.training_id)
		order by td.t asc) as td_row_n
	where td_row_n.row_n = 1) td_end

	on (td_start.id = td_end.id)
);