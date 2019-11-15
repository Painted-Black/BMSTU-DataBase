/* Вывести имена, фамилии, специальности врачей, которые проводили приемы в 2000 и в 2002 годах */
select D.name AS "Имя", D.surname AS "Фамилия", D.speciality AS "Специальность", R.date_time AS "Дата приема" 
    from doctors D, receptions R 
    where R.doctor = D.id 
        AND D.sex = 'м'
        AND (extract(year from R.date_time) = '2000' OR extract(year from R.date_time) = '2002') 
    ORDER BY R.date_time;

/*Вывести имена, фамилии и даты рождения пациентов, которые родились между 1998-01-01 и 2005-01-01*/
SELECT O.name AS "Имя", O.surname AS "Фамилия", O.date_of_birth AS "Дата рождения" 
    FROM outpatientcards O 
    where date_of_birth  BETWEEN  '1998-01-01' AND '2005-01-01'
    ORDER BY O.date_of_birth;

/* Вывести имена, фамилии, номера телефонов и улицу проживания всех пациентов, которые проживают на 
   улице, название которой начинается на 'А' */
select O.name AS "Имя", O.surname AS "Фамилия", O.phone_num AS "Номер телефона", O.street AS "Улица" 
    FROM (outpatientcards JOIN addresses ON outpatientcards.address = addresses.id) O 
    WHERE O.street LIKE 'А%';

/* Вывести id пациентов, id докторов и время приема для приемов, на которые пришли пациенты из города 'Москва' */
select patient, date_time, doctor FROM receptions 
    WHERE patient IN (
        SELECT p.id 
        FROM (patients p  JOIN outpatientcards o ON p.outpat_card = o.id) 
            JOIN addresses ON o.address = addresses.id WHERE city = 'Москва');

/* Получить список пациентов, которые никогда не были на приеме у врача */
SELECT * FROM patients p 
    WHERE not EXISTS (
        SELECT * 
            FROM receptions r
            WHERE p.id = r.patient);

/* Получить список врачей, зарплата которых больше зарплаты любого врача категории 'Вторая' */
SELECT id, name, surname, speciality, salary 
    FROM doctors 
    WHERE salary > ALL (
        SELECT salary 
        FROM doctors 
        WHERE category = 'Вторая');

/* Вывести среднюю зарплату всех врачей */
SELECT AVG(salary) AS "Средняя зарплата врачей" 
    FROM doctors;

/* !! */

/* Вывести имена, фамилии, количество принятых пациентов, зарплаты, специальности и количество врачей данной специальности для каждого врача высшей категории */
SELECT d.surname AS "Фамилия",
    d.name AS "Имя", 
    (SELECT COUNT(*) FROM patients p JOIN receptions r ON p.id = r.patient WHERE doctor = d.id) AS "Количество принятых пациентов",
    d.salary AS "Зарплата", 
    d.speciality AS "Специальность", 
    (SELECT COUNT(*) FROM doctors _d WHERE _d.speciality = d.speciality) AS "Количество специалистов" 
    FROM doctors d 
    WHERE d.category = 'Высшая';


/* Вывести даты всех приемов и ФИО пациентов, которые были на них. Напротив каждого приема указать 'Этот год', 'Прошлый год' или 'n лет назад',
    в зависимости от даты приема */
SELECT date_time, name, surname, 
    CASE extract(year from date_time)
        WHEN extract(year from CURRENT_DATE) THEN 'This year'
        WHEN extract(year from CURRENT_DATE) - 1 THEN 'Last year'
        ELSE CAST(DATE_PART('year', CURRENT_DATE) - DATE_PART('year', date_time) AS TEXT) || ' years ago'
    END AS "When"
FROM receptions r JOIN patients p ON r.patient = p.id JOIN outpatientcards o ON o.id = p.outpat_card;

/* Вывести ФИО всех пациентов. Напротив вывести 'До 18', '18-45' или 'Более 45', в зависимости от возраста пациента */
SELECT name, surname,
    CASE
        WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', o.date_of_birth) < 18 then 'Under 18'
        WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', o.date_of_birth) < 40 then '18-48'
        ELSE 'Over 45'
    END AS "Age"
from outpatientcards o;


/* Во временную таблицу записать количество врачей для каждой специальности */
SELECT DISTINCT d.speciality, (
    SELECT COUNT(*) 
    FROM doctors _d 
    WHERE _d.speciality = d.speciality) 
AS "Количество специалистов" 
INTO TEMPORARY sp_quality 
FROM doctors d;

 
/* Для каждой врачебной специальности вывести среднюю зарплату, максимальную и минимальную */
SELECT DISTINCT 
    d.speciality, 
    AVG(d.salary) OVER(PARTITION BY d.speciality) AS AvgSalary,
    MAX(d.salary) OVER(PARTITION BY d.speciality) AS MaxSalary,
    MIN(d.salary) OVER(PARTITION BY d.speciality) AS MinSalary 
FROM doctors d ORDER BY d.speciality;


/* Уволим врачей, которые не приняли ни одного пациента */
DELETE FROM doctors 
    WHERE id IN (
        SELECT d.id 
            FROM doctors d 
            WHERE (
                SELECT COUNT(*) 
                    FROM patients p JOIN receptions r ON p.id = r.patient 
                    WHERE doctor = d.id) = 0);

/* Удалим приемы, которые были проведены ранее, чем в 1995 году */
DELETE FROM receptions r WHERE DATE_PART('year', r.date_time) < 1995;

/* Обновим номер телефона врача с id = 2 */
UPDATE doctors SET phone_num = '89991231212' WHERE id = 2;

/* Поднимем в 1.2 раза зарплату всем врачам второй категории, чья зарплата меньше средней зарплаты врачей второй категории */
UPDATE doctors 
    SET salary = ((
        SELECT AVG(salary) FROM doctors where category = 'Вторая') * 1.2) 
    WHERE category = 'Вторая' AND salary < ((
        SELECT AVG(salary) FROM doctors where category = 'Вторая') * 1.2);

/* Добавим нового врача */
INSERT INTO doctors (name, surname, sex, date_of_birth, speciality, phone_num, category, salary) 
VALUES ('Адам', 'Дженсен', 'м', '1993-03-09', 'Офтальмолог', '89999999999', 'Высшая', 99999);


/* Врач 6 принял пациентов 1-6 2019-11-06. Добавить соотв. записи в таблицу приемов*/
INSERT INTO RECEPTIONS (patient, date_time, doctor)
SELECT p.id, '2019-11-06', d.id
FROM patients p CROSS JOIN doctors d WHERE p.id < 6 AND d.id = 1;

/* Вывести ID всех врачей, зарплата которых меньше средней зарплаты врачей */
SELECT DISTINCT 
    d.id, 
    AVG(d.salary) AS AvgSalary
FROM doctors d GROUP BY d.id, d.salary HAVING AVG(d.salary) < (SELECT AVG(salary) FROM doctors);

/* Вывести названия всех специальностей, средняя зарплата врачей первой категории которых меньше средней зарплаты всех врачей */
SELECT 
    d.speciality,
    AVG(d.salary)
FROM doctors d WHERE d.category= 'Первая'
GROUP BY d.speciality HAVING AVg(d.salary) > (SELECT AVG(salary) FROM doctors) ORDER BY d.speciality;


/* Для каждой специальности вывести среднюю зарплату врачей высшей категории */
SELECT 
    d.speciality,
    AVG(d.salary)
FROM doctors d WHERE d.category= 'Высшая'
GROUP BY d.speciality;

/* Для каждого приема выведем имена пациентов, которые на них присутствовали. Удалим дублирующиеся строки */
SELECT name, surname FROM (
    SELECT o.name, o.surname, ROW_NUMBER() OVER (PARTITION BY o.id) AS n 
        FROM (receptions r JOIN patients p ON r.patient = p.id) JOIN outpatientcards o ON p.outpat_card = o.id) 
        AS T 
WHERE n = 1;

/* Вывести среднее количество принятых пациентов для врачей высшей категории */
WITH CTE AS (
    SELECT d.surname AS "Фамилия",
        d.name AS "Имя", 
        (SELECT COUNT(*) FROM patients p JOIN receptions r ON p.id = r.patient WHERE doctor = d.id) AS PatientsNum
    FROM doctors d 
    WHERE d.category = 'Высшая'
)
SELECT AVG(PatientsNum) AS "Среднее кол-во пациентов(высш.кат.)" FROM CTE;

/* Вывести всю информацию о самом старом и самом молодом пациенте */
SELECT 'Самый старый' AS what, * FROM (SELECT * FROM outpatientcards ORDER BY date_of_birth LIMIT 1) AS Oldest UNION
SELECT 'Смый молодой' AS what, * FROM (SELECT * FROM outpatientcards ORDER BY date_of_birth DESC LIMIT 1) AS Youngest;

/* Вывести имена и контактные данные всех пациентов, которые были на приемах в период с  '2018-01-01' до '2019-01-01'*/
SELECT o.name, o.surname, o.phone_num 
FROM outpatientcards o 
WHERE o.id IN (
    SELECT p.outpat_card 
    FROM patients p 
    WHERE p.id IN (
        SELECT r.patient    
        FROM receptions r 
        WHERE date_time BETWEEN '2018-01-01' AND '2019-01-01'));

/* Вывести ID всех пациентов, которые были на приемах больше всех */
WITH CTE AS 
(
    SELECT r.patient,
        (SELECT COUNT(*) FROM receptions _r WHERE _r.patient = r.patient) AS RecQ
        FROM receptions r
) 
SELECT DISTINCT patient FROM CTE
WHERE recq = (
    SELECT MAX(RecQ) FROM (
        SELECT r.patient,
            (SELECT COUNT(*) FROM receptions _r WHERE _r.patient = r.patient) AS RecQ
                FROM receptions r) AS MaxRecQ) ORDER BY patient;


/* Для таблицы Ogranisations для каждой организации вывести ее предков */
       WITH RECURSIVE temp1 (id ,name, parent, type, PATH, LEVEL) AS 
(
    SELECT T1.id, T1.name, T1.parent, T1.type, CAST (T1.id AS VARCHAR (50)) as PATH, 1
        FROM organisations T1 WHERE T1.parent IS NULL
    union
    select T2.id, T2.name, T2.parent, T2.type, CAST ( temp1.PATH ||'->'|| T2.id AS VARCHAR(50)) ,LEVEL + 1
         FROM organisations T2 INNER JOIN temp1 ON( temp1.id= T2.parent))
    select * from temp1 ORDER BY PATH;

