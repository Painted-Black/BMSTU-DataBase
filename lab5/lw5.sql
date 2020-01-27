-- Использование JSON с базами данных

-- 1) Из таблиц базы данных, созданной в ЛР 1,
-- извлечь данные с помощью функций создания JSON.
select row_to_json(doctors) from doctors;
select to_json(doctors) from doctors;
select json_build_array(row(doctors)) from doctors;

-- 2) Выполниить загрузку и сохранение данных с JSON-документом
-- Сохранение в JSON
\copy (select row_to_json(doctors) from doctors) to '/home/syzygy/Desktop/Labs/DB/lab5//doctors.json';

\copy (select array_to_json(array_agg(row_to_json(doctors))) from doctors) to '/home/syzygy/Desktop/Labs/DB/lab5//doctors2.json';

select * from doctors;

-- Загрузка из JSON-файла
create unlogged table doctors_import(doc json);

\copy doctors_import from '/home/syzygy/Desktop/Labs/DB/lab5//doctors.json';

select * from doctors_import;


insert into doctors (
    name, surname, sex, date_of_birth, speciality, phone_num, category, salary, fired)
select name, surname, sex, date_of_birth, speciality, phone_num, category, salary, fired
from doctors_import
cross join json_populate_recordset(null::doctors, doc) as p;

select * from doctors;

--truncate doctors;

-- 3) Работа с JSON-схемой
-- 	1. Создать JSON-схему для какого-либо документа,
-- 	набрав описание вручную с помощью какого-либо текстового редактора.

-- 4) Написать консольное приложение на языке Python, которое выполняет проверку
-- допустимости разработанного в текущей ЛР JSON-документа, используя JSON-схему.
-- Проведите эксперименты с JSON-документом и убедитесь в том, что
-- приложение действительно обнаруживает ошибки при проверке допустимости.
