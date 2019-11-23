--Вариант 3, Овчинникова А.П., ИУ7-55
create database RK2;
grant all on database RK2 to lander;

create table departments (
    id serial primary key,
    name varchar(100) NOT NULL,
    description text);

insert into departments (name, description) values ('ИУ1', 'Системы автоматического управления');
insert into departments (name, description) values ('ИУ2', 'Приборы и системы ориентации');
insert into departments (name, description) values ('ИУ3', 'Информационные системы и коммуникации');
insert into departments (name, description) values ('ИУ4', 'Проектирование электронной аппаратуры');
insert into departments (name, description) values ('ИУ5', 'Системы обработки информации');
insert into departments (name, description) values ('ИУ6', 'Компьютерные системы и сети');
insert into departments (name, description) values ('ИУ7', 'Программное обеспечение ЭВМ');
insert into departments (name, description) values ('ИУ8', 'Информационная безопасность');
insert into departments (name, description) values ('ИУ9', 'Теоретическая информатика');
insert into departments (name, description) values ('ИУ10', 'Секретно');

create table teachers (
    id serial primary key,
    name varchar(60) NOT NULL, 
    surname varchar(60) NOT NULL, 
    patronymic varchar(60), 
    degree varchar(60), 
    position varchar(60),
    department int references departments(id));

insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Петров', 'Андрей', 'Игоревич', 'Доцент', 'Преподаватель', 1);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Сидоров', 'Павел', 'Сергеевич', 'Аспирант', 'Преподаватель', 2);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Волков', 'Алексей', 'Юрьевич', 'Доцент', 'Главный преподаватель', 2);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Иванов', 'Иван', 'Иванович', 'Магистр', 'Помощник преподавателя', 3);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Горнев', 'Антон', 'Сергеевич', 'Доцент', 'Заведующий кафедрой', 4);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Бабушкин', 'Павел', 'Михайлович', 'Аспирант', 'Преподаватель', 5);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Бардина', 'Марина', 'Анатольевна', 'Доцент', 'Преподаватель', 6);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Семенова', 'Анастасия', 'Сергеевна', 'Магистр', 'Помощник преподавателя', 7);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Буравов', 'Александр', 'Игоревич', 'Аспирант', 'Преподаватель', 8);
insert into teachers (name, surname, patronymic, degree, position, department) values
     ('Хохлов', 'Игорь', 'Павлович', 'Доцент', 'Заведующий кафедрой', 9);

create table subjects (
    id serial primary key,
    name varchar(100) NOT NULL,
    hours integer,
    semester integer,
    rating integer,
    CHECK (hours > 0),
    CHECK (semester > 0 AND semester <= 12),
    CHECK (rating >= 0 and rating <= 100));

INSERT INTO subjects (name, hours, semester, rating) values ('Анализ алгоритмов', 100, 5, 90);
INSERT INTO subjects (name, hours, semester, rating) values ('Базы данных', 110, 6, 95);
INSERT INTO subjects (name, hours, semester, rating) values ('Архитектура ЭВМ', 80, 2, 80);
INSERT INTO subjects (name, hours, semester, rating) values ('Операционные системы', 120, 7, 85);
INSERT INTO subjects (name, hours, semester, rating) values ('Теория вероятностей', 70, 2, 70);
INSERT INTO subjects (name, hours, semester, rating) values ('Математическая статистика', 85, 3, 60);
INSERT INTO subjects (name, hours, semester, rating) values ('Теория алгоритмов', 95, 4, 95);
INSERT INTO subjects (name, hours, semester, rating) values ('Программирование на Python', 60, 1, 100);
INSERT INTO subjects (name, hours, semester, rating) values ('ООП', 110, 5, 65);
INSERT INTO subjects (name, hours, semester, rating) values ('Компьютерная графика', 50, 8, 0);

create table ST (
    id serial primary key,
    subject_id integer references subjects(id),
    teacher_id integer references teachers(id));

insert into ST(subject_id, teacher_id) values (1, 1);
insert into ST(subject_id, teacher_id) values (2, 2); 
insert into ST(subject_id, teacher_id) values (3, 3); 
insert into ST(subject_id, teacher_id) values (4, 5); 
insert into ST(subject_id, teacher_id) values (5, 4); 
insert into ST(subject_id, teacher_id) values (6, 6); 
insert into ST(subject_id, teacher_id) values (7, 8); 
insert into ST(subject_id, teacher_id) values (8, 7); 
insert into ST(subject_id, teacher_id) values (9, 9); 
insert into ST(subject_id, teacher_id) values (10, 10);

--Вывести названия всех предметов, рейтинг которых выще рейтинга всех предметов, которые читаются во 2-м семестре
SELECT name FROM subjects WHERE rating > ALL(SELECT rating from subjects WHERE semester = 2);

--Вывести среднее количество учебных в каждом семестре
select semester, AVG(hours) from subjects GROUP by semester ORDER BY semester;

--во временную таблицу записать предметы и фамилии преподавателей, которые их ведут
select surname, s.name
    INTO TEMPORARY doctors_subjects
    from (
    teachers t join st on st.teacher_id = t.id) stt 
               join subjects s on s.id = stt.subject_id;
select * from doctors_subjects;

create or replace procedure indexes_info(_tablename text) as $$
$$ language sql;

--функция, которая выводит сведения о индексах таблицы с именем _tablename
create or replace function indexes_info(_tablename text) returns table(index_name name, indexdef text) as $$ (
    SELECT indexname, indexdef FROM pg_indexes WHERE tablename = _tablename
)
$$ language sql;
select * from indexes_info('subjects');

--Это процедура, но не протестированная, потому что мне не удалось запустить postgres12
create or replace procedure indexes_info_proc(_tablename text) as $$
    SELECT indexname, indexdef FROM pg_indexes WHERE tablename = _tablename;
$$ language sql;

call indexes_info_proc('subjects');

