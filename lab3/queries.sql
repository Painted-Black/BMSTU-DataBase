-- DML триггер AFTER
CREATE FUNCTION after_doctors_insert() RETURNS TRIGGER AS $$
DECLARE d integer := (SELECT COUNT(*) FROM doctors);
BEGIN
RAISE NOTICE 'Doctors in total: %', d;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER AInsertDoctors
AFTER INSERT
ON doctors FOR EACH ROW
EXECUTE PROCEDURE after_doctors_insert();

-- DML триггер INSTEAD OF
CREATE VIEW doctors_view AS SELECT * FROM doctors;

CREATE FUNCTION insteadof_doctors_delete() RETURNS TRIGGER AS $$
DECLARE d integer := OLD.id;
BEGIN
RAISE NOTICE 'Deleted id: %', d;
DELETE FROM doctors WHERE id = OLD.id;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER BDeleteDoctors
INSTEAD OF DELETE
ON doctors_view FOR EACH ROW
EXECUTE PROCEDURE insteadof_doctors_delete();

--Скалярная функция
CREATE FUNCTION count_specialities() RETURNS INTEGER AS $$
DECLARE speciality_count integer := (SELECT COUNT(*) FROM (SELECT DISTINCT d.speciality FROM doctors d) AS AllSpec);
BEGIN
    RETURN speciality_count;
END;
$$ LANGUAGE plpgsql;

SELECT count_specialities();

--Подставляемая табличная функция
CREATE FUNCTION avg_salary_high() RETURNS TABLE (speciality text, avg_salary numeric) AS $$
(
    SELECT 
    d.speciality,
    AVG(d.salary)
    FROM doctors d WHERE d.category= 'Высшая'
    GROUP BY d.speciality
)
$$ LANGUAGE SQL;

SELECT * FROM avg_salary_high();

--Рекурсивная функция
CREATE FUNCTION factorial(n integer) RETURNS integer AS $$
BEGIN
    if n < 0 THEN
        RAISE NOTICE 'Факториал не определен на множестве отрицательных чисел.';
        RETURN -1;
    END IF;   
    if n = 0 THEN
        RETURN 1;
    END IF;
    RETURN n * factorial(n - 1);
END;
$$ LANGUAGE plpgsql;

--Функция с рекурсивным ОТВ
CREATE FUNCTION parents() RETURNS TABLE (id integer, name text, parent integer, type text, PATH text, LEVEL integer) AS $$
(
    WITH RECURSIVE temp1 (id ,name, parent, type, PATH, LEVEL) AS 
    (
        SELECT T1.id, T1.name, T1.parent, T1.type, CAST (T1.id AS VARCHAR (50)) as PATH, 1
            FROM organisations T1 WHERE T1.parent IS NULL
        UNION
        SELECT T2.id, T2.name, T2.parent, T2.type, CAST (temp1.PATH ||'->'|| T2.id AS VARCHAR(50)) ,LEVEL + 1
            FROM organisations T2 INNER JOIN temp1 ON( temp1.id= T2.parent)
    )
    select * from temp1 ORDER BY PATH
)
$$ LANGUAGE SQL;

--Хранимая процедура без параметров или с параметрами
CREATE PROCEDURE add_reception(_patient integer, _doctor integer, _date_time timestamp) AS $$
    INSERT INTO receprions(patient, date_time, doctor) VALUES (_patient, _date_time, _doctor);
$$ LANGUAGE SQL;s





/*
+---------------------------------+----------------------------------------+
| Stored Procedure (SP)           | Function (UDF - User Defined           |
|                                 | Function)                              |
+---------------------------------+----------------------------------------+
| SP can return zero , single or  | Function must return a single value    |
| multiple values.                | (which may be a scalar or a table).    |
+---------------------------------+----------------------------------------+
| We can use transaction in SP.   | We can't use transaction in UDF.       |
+---------------------------------+----------------------------------------+
| SP can have input/output        | Only input parameter.                  |
| parameter.                      |                                        |
+---------------------------------+----------------------------------------+
| We can call function from SP.   | We can't call SP from function.        |
+---------------------------------+----------------------------------------+
| We can't use SP in SELECT/      | We can use UDF in SELECT/ WHERE/       |
| WHERE/ HAVING statement.        | HAVING statement.                      |
+---------------------------------+----------------------------------------+
| We can use exception handling   | We can't use Try-Catch block in UDF.   |
| using Try-Catch block in SP.    |                                        |
+---------------------------------+----------------------------------------+ */


