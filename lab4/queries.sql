--Создать, развернуть и протестировать 6 объектов SQL CLR:
--1) Определяемую пользователем скалярную функцию CLR,
--2) Пользовательскую агрегатную функцию CLR,
--3) Определяемую пользователем табличную функцию CLR,
--4) Хранимую процедуру CLR,
--5) Триггер CLR,
--6) Определяемый пользователем тип данных CLR.

--  1) Определяемая пользователем скалярная функция
-- Вывести количество пациентов из определенного города
ALTER TABLE receptions ADD CONSTRAINT receptions_doctor_fkey FOREIGN KEY (doctor) REFERENCES doctors(id);

CREATE OR REPLACE FUNCTION get_patients(city_name varchar)
  RETURNS varchar
AS $$
o = plpy.execute("select * from outpatientcards;")
a = plpy.execute("select * from addresses")
count = 0
for row_o in o:
    for row_a in a:
        if row_o['address'] == row_a['id'] and row_a['city'] == city_name:
            count += 1
return count
$$ LANGUAGE plpython3u;

SELECT * FROM get_patients('Москва');

-- 2) Пользовательская агрегатная функция
-- Определить количество пациентов в определенном возрастном промежутке
CREATE OR REPLACE FUNCTION count_by_age(a integer, b integer)
  RETURNS integer
AS $$
count = 0
for row in plpy.execute("select date_of_birth from outpatientcards;"):
    tmp = int(row['date_of_birth'][:4])
    if tmp >= a and tmp <= b:
         count += 1
return count
$$ LANGUAGE plpython3u;

SELECT * FROM count_by_age(1990, 2000);

-- 3) Определяемая пользователем табличная функция
-- вывести всех врачей опреленной специальности
CREATE OR REPLACE FUNCTION get_table (_spec text)
  RETURNS table (name varchar, surname varchar, phone_num varchar, speciality text)
AS $$
rv = plpy.execute('SELECT * FROM doctors')
res = []
for row in rv:
    if (row['speciality'] == _spec):
        res.append(row)
return res
$$ LANGUAGE plpython3u;

SELECT * FROM get_table('Хирург');

-- 4) хранимая процедура
-- для врача с заданным id изменить номер телефона на заданный
CREATE OR REPLACE PROCEDURE update_doctor_phone(_id integer, _new_phone varcar(11))
LANGUAGE plpython3u
AS $$
plan = plpy.prepare("UPDATE doctors SET phone_num = _new_phone WHERE phone_num = $1", ['integer'])

rv = plpy.execute(plan, [_id])
$$;

CALL update_cost_tickets(1, '89999999999');

SELECT * FROM doctors;

--  5) триггер
--  При удалении врача не удалять его, а помечать его как уволенного

alter table doctors add column fired boolean;
update doctors set fired = false;
CREATE VIEW doctors_view AS SELECT * FROM doctors;

CREATE OR REPLACE FUNCTION doctors_instead_delete()
RETURNS trigger 
AS $$
plan = plpy.prepare("UPDATE doctors SET fired = true where id = $1;", ['integer'])
rv = plpy.execute(plan, [TD['old']['id']])
return TD['new']
$$ LANGUAGE plpython3u;

CREATE TRIGGER trigger_doctors
INSTEAD OF DELETE ON
doctors_view FOR EACH ROW
EXECUTE PROCEDURE doctors_instead_delete();

DELETE FROM doctors_view WHERE id = 1;

SELECT * FROM doctors;

-- 6) Определяемый пользователем тип данных
-- Информация о враче: имя, фамилия, специальность, номер телефона
CREATE TYPE doctors_info AS (

  doc_name varchar,
  doc_surname varchar,
  doc_spec text,
  doc_phone varchar
);

-- возвращает информацию о враче по id врача
create or replace function get_doctors_info(_id integer)
returns doctors_info
as $$
f = plpy.execute("select * from doctors;")
for row in f:
    if row['id'] == _id:
        return (row['name'], row['surname'], row['speciality'], row['phone_num'])
$$ language plpython3u;

SELECT * FROM get_doctors_info(1);
