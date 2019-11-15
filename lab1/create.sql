/* psql -h localhost hospital lander */
create database Hospital;
create user lander with password '';
grant all on database hospital to lander;

create type _SEX as enum ('м', 'ж');
create type _BLOOD_TYPE as enum ('A', 'B', 'AB', '0');
create type _RHESUS_FACTOR as enum ('+', '-');
create type _HEALTH_GROUP as enum ('1', '2', '3a', '3b');
create type _DISABILITY as enum ('1', '2', '3', 'нет');
create type _CATEGORY as enum ('Первая', 'Вторая', 'Высшая');

create table Doctors
    (id serial primary key, 
    name varchar(60) NOT NULL,
    surname varchar(60) NOT NULL, 
    sex _SEX, date_of_birth date NOT NULL, 
    speciality text NOT NULL, 
    phone_num  varchar(11), 
    category _CATEGORY, 
    salary integer NOT NULL, 
    CHECK (salary > 9000));

create table Addresses(
    id serial primary key, 
    country varchar(100) NOT NULL, 
    city varchar(100) NOT NULL, 
    street varchar(100) NOT NULL, 
    house_number integer NOT NULL, 
    building varchar(5), 
    flat integer,
    CHECK (house_number > 0 AND flat > 0));

create table OutpatientCards(
    id serial primary key, 
    name varchar(60) NOT NULL, 
    surname varchar(60) NOT NULL, 
    sex _SEX, 
    date_of_birth date NOT NULL, 
    phone_num  varchar(11), 
    OMS_policy_number varchar(16), 
    address integer references Addresses(id), 
    blood_type _BLOOD_TYPE, 
    rhesus_factor _RHESUS_FACTOR, 
    health_group _HEALTH_GROUP, 
    disability _DISABILITY);

create table Patients(
    id serial primary key, 
    outpat_card integer references OutpatientCards(id));

create table Receptions(id serial primary key, 
    patient integer references Patients(id), 
    date_time timestamp, 
    doctor integer references Doctors(id));

/* insert into doctors (name, surname, sex, date_of_birth, speciality, phone_num, category, salary) values ('Маша', 'Машина', 'м', '1992-01-01', 'Эмбриолог', '79992345678', 'Первая', -2);
insert into addresses (country, city, street, house_number, building, flat) values ('Россия', 'Печкинск', 'Печкина', 1, 'A', -1); */

\ir /home/syzygy/Desktop/Labs/DB/lab1/insert_people.sql
\ir /home/syzygy/Desktop/Labs/DB/lab1/create_receptions.sql
\ir /home/syzygy/Desktop/Labs/DB/lab1/create_addresses.sql
\ir /home/syzygy/Desktop/Labs/DB/lab1/create_cards.sql
\ir /home/syzygy/Desktop/Labs/DB/lab1/insert_patient.sql


