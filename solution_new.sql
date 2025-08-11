create schema raw_data;

create table raw_data.sales();

select count(*) from raw_data.sales;

select * from raw_data.sales;

alter table raw_data.sales 
add column name_auto varchar(50),
add column color varchar(50);

update raw_data.sales
set
	name_auto = split_part(auto, ', ', 1),
	color = split_part(auto, ', ', 2);

alter table raw_data.sales drop column auto;

--Начало нормализации из обработанной таблицы sales
create table raw_data.cars(
	car_id serial primary key,
	gasoline_consumption real null,
	brand_origin varchar(50) null,
	name_auto varchar(50) null,
	color varchar(50) not null
);

create table raw_data.persons(
	person_id serial primary key,
	person_name varchar(200),
	phone varchar(255)
);

create table raw_data.sale(
	sale_id serial primary key,
	price real not null default 0,
	discount integer not null default 0,
	"date" timestamp not null,
	car_id integer references raw_data.cars(car_id),
	person_id integer references raw_data.persons(person_id)
);

-- Заполнение таблиц
INSERT INTO raw_data.cars (car_id, gasoline_consumption, brand_origin, name_auto, color)
select
  id,
  gasoline_consumption,
  brand_origin,
  name_auto,
  color
FROM raw_data.sales;


INSERT INTO raw_data.persons (person_name, phone)
SELECT
  person_name,
  phone
FROM raw_data.sales
group by 1,2
select * from raw_data.persons;

INSERT INTO raw_data.sale (price, discount, "date", car_id, person_id)
SELECT
  s.price,
  s.discount,
  s."date",
  c.car_id,
  p.person_id
FROM raw_data.sales s
join raw_data.cars c
  on c.car_id = s.id
join raw_data.persons p 
  on p.phone = s.phone;

-- Вывод всей информации с помощью запроса
select
	*
from raw_data.sale s
join raw_data.cars c
	on s.car_id = c.car_id
join raw_data.persons p
	on s.person_id = p.person_id

select * from raw_data.cars;
select * from raw_data.persons;
select * from raw_data.sale;
-- Добавление сущностей для cars (persons и sales настроены корректно)
create table raw_data.color(
	id_color serial primary key,
	name_color varchar(30)
);
insert into raw_data.color(name_color)
select distinct color from raw_data.cars c;
select * from raw_data.color;

alter table raw_data.cars
add column id_color int;

ALTER TABLE raw_data.cars
ADD CONSTRAINT fk_color_id_color
FOREIGN KEY (id_color) 
REFERENCES raw_data.color(id_color);

update raw_data.cars c
set id_color = co.id_color 
from raw_data.color co
where c.color = co.name_color

alter table raw_data.cars
drop column color;


create table raw_data.car_info(
	id_car_info serial primary key,
	gasoline_consumption float4,
	brand_origin varchar(100),
	name_auto varchar(100)
);

select * from raw_data.car_info;

insert into raw_data.car_info(gasoline_consumption, brand_origin, name_auto)
select gasoline_consumption, brand_origin, name_auto
from raw_data.cars
group by 1,2,3;

alter table raw_data.cars
add column id_car_info int;

alter table raw_data.car_info
add column model varchar(150),
add column brand varchar(150);

update raw_data.car_info
set
	brand = split_part(name_auto, ' ', 1),
	model = substring(name_auto FROM ' (.*)');

select * from raw_data.car_info;

alter table raw_data.car_info
drop column name_auto;

create table raw_data.brand(
	brand_id serial primary key,
	name_brand varchar(150),
	country_id integer references raw_data.country (country_id)
);

select * from raw_data.car_info ci; 
insert into raw_data.brand(name_brand)
select distinct brand from raw_data.car_info ci;

alter table raw_data.car_info
drop column brand;

alter table raw_data.car_info
add column brand_id integer;

alter table raw_data.car_info 
add constraint fk_brand_info
foreign key (brand_id)
references raw_data.brand(brand_id)

ALTER TABLE raw_data.cars
ADD CONSTRAINT fk_info_car
FOREIGN KEY (id_car_info) 
REFERENCES raw_data.car_info(id_car_info);

update raw_data.cars c
set id_car_info = i.id_car_info
from raw_data.car_info i
where c.gasoline_consumption = i.gasoline_consumption
and c.brand_origin = i.brand_origin and c.name_auto = i.name_auto

alter table raw_data.cars
drop column gasoline_consumption, 
drop column brand_origin,
drop column name_auto;

select * from raw_data.car_info

create table raw_data.country (
	country_id serial primary key,
	name_country varchar(150)
);

insert into raw_data.country (name_country)
select distinct brand_origin from raw_data.car_info;

select * from raw_data.car_info;


--Заполнение стран и бренда
update raw_data.brand b
set country_id = c.country_id 
from raw_data.country c
join raw_data.sales s
	on s.brand_origin = c.name_country
where split_part(s.name_auto, ' ', 1) = b.name_brand


update raw_data.car_info ci
set brand_id = b.brand_id 
from raw_data.brand b
join raw_data.sales s
	on split_part(s.name_auto, ' ', 1) = b.name_brand
where substring(s.name_auto FROM ' (.*)') = ci.model


-- Выполнение заданий
-- Задание 1

SELECT 
  ROUND(100.0 * COUNT(*) FILTER (WHERE gasoline_consumption IS NULL) / COUNT(*), 2) 
  AS nulls_percentage_gasoline_consumption
FROM raw_data.cars;

-- Задание 2

SELECT 
  c.name_auto AS brand_name,
  EXTRACT(YEAR FROM s.date) AS year,
  ROUND(AVG(s.price)::numeric, 2) AS price_avg
FROM raw_data.sale s
JOIN raw_data.cars c ON s.car_id = c.car_id
GROUP BY c.name_auto, EXTRACT(YEAR FROM s.date)
ORDER BY c.name_auto, year;

-- Задание 3

SELECT 
  EXTRACT(MONTH FROM s.date) AS month,
  EXTRACT(YEAR FROM s.date) AS year,
  ROUND(AVG(s.price)::numeric, 2) AS price_avg
FROM raw_data.sale s
WHERE EXTRACT(YEAR FROM s.date) = 2022
GROUP BY EXTRACT(YEAR FROM s.date), EXTRACT(MONTH FROM s.date)
ORDER BY month;

-- Задание 4

SELECT 
  p.person_name AS person,
  STRING_AGG(c.name_auto, ',') AS cars
FROM raw_data.sale s
JOIN raw_data.persons p ON s.person_id = p.person_id
JOIN raw_data.cars c ON s.car_id = c.car_id
GROUP BY p.person_name
ORDER BY p.person_name;

-- Задание 5

SELECT 
  c.brand_origin,
  ROUND(MAX(s.price / (1 - s.discount / 100.0))::numeric, 2) AS price_max,
  ROUND(MIN(s.price / (1 - s.discount / 100.0))::numeric, 2) AS price_min
FROM raw_data.sale s
JOIN raw_data.cars c ON s.car_id = c.car_id
GROUP BY c.brand_origin
ORDER BY c.brand_origin;

-- Задание 6

SELECT 
  COUNT(*) AS persons_from_usa_count
FROM raw_data.persons
WHERE phone LIKE '+1%';








