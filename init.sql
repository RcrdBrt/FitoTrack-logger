create table if not exists training(
    id integer primary key,
    medium varchar(255) not null,
    uuid uuid not null,
    t timestamp with time zone not null,
    lat float not null,
    lon float not null,
    speed float not null,
    altitude float not null,
    distance float not null,
    kcal int not null
);