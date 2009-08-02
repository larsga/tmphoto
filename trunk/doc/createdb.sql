
create table photo_score (
  id serial primary key,
  photo varchar(20) not null,
  username varchar(20) not null,
  score integer not null,
  updated timestamp not null
);

create table comments (
  id       SERIAL primary key,
  photo    varchar(10) not null,
  verified int not null default 0,
  datetime timestamp not null,
  username varchar(15) not null,
  content  varchar(4000) not null,

  email    varchar(100) null,
  name     varchar(100) null,
  url      varchar(100) null
);
