CREATE DATABASE rk3;
grant all on database hospital to lander;

CREATE TYPE _DAY_OF_WEEK as enum ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');
CREATE TYPE _TYPE as enum (1, 2);

CREATE TABLE arrival
    (id serial primary key,
     employee_id integer,
     _date date NOT NULL,
     day_of_week _DAY_OF_WEEK NOT NULL,
     _time time NOT NULL,
     _type _TYPE NOT NULL);

CREATE TABLE employees
    (id serial primary key,
     SNP text NOT NULL,
     date_of_birth date NOT NULL,
     department text);

-- гг-мм-дд

INSERT INTO arrival (employee_id, _date, day_of_week, _time, _type) VALUES (1, '2018-12-14', 'Saturday', '9:00', '1');
INSERT INTO arrival (employee_id, _date, day_of_week, _time, _type) VALUES (1, '2018-12-14', 'Saturday', '9:20', '2');
INSERT INTO arrival (employee_id, _date, day_of_week, _time, _type) VALUES (1, '2018-12-14', 'Saturday', '9:25', '1');
INSERT INTO arrival (employee_id, _date, day_of_week, _time, _type) VALUES (2, '2018-12-14', 'Saturday', '9:05', '1');

INSERT INTO employees (SNP, date_of_birth, department) VALUES ('Ivanov Ivan Ivanovich', '1990-09-25', 'IT');
INSERT INTO employees (SNP, date_of_birth, department) VALUES ('Petrov Petr Petrovich', '1987-11-12', 'Accounting');

--Функция, выводящая средний возраст опоздавших сегодня сотрудников (опоздал если пришел после 9:00)
CREATE OR REPLACE FUNCTION avg_age() RETURNS TABLE (_avg_age interval) AS $$
(
    select AVG(foo.age) FROM (select age(CURRENT_DATE, e.date_of_birth) from arrival a JOIN employees e on employee_id = e.id where _time > '9:00') as foo
)
$$ LANGUAGE SQL;

SELECT * FROM avg_age();

--Отделы, в которых ни один сотрудник никогда не опаздывал
select department from employees where department NOT IN(select department from arrival a JOIN employees e on employee_id = e.id WHERE _time > '9:00');

--Отделы, в которых хоть один сотрудник опаздывал за последние 10 дней
select * from arrival a JOIN employees e on employee_id = e.id where (
_time > '9:00' AND _type = '1' AND (age(CURRENT_DATE, _date) > '0 mons 10 days'));




