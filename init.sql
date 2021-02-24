create table if not exists training(
    id uuid primary key default gen_random_uuid(),
    owner varchar(255) not null,
    filename text not null,
    medium varchar(255) not null,
    description text not null,
    data jsonb not null default '{}'
);

create table if not exists training_data(
    training_id uuid not null,
    t timestamp with time zone not null,
    lat float not null,
    lon float not null,
    speed float not null,
    altitude float not null,
    distance float not null,
    kcal int not null,
    constraint fk_training_id foreign key(training_id) references training(id) on delete cascade
);
create index if not exists idx_training_data_training_id on training_data(training_id);