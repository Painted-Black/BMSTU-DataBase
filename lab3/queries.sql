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
CREATE FUNCTION parents() RETURNS TABLE (id integer, name text, surname text, parent integer, PATH text, LEVEL integer) AS $$
(
	WITH RECURSIVE temp1 (id, name, surname, parent, PATH, LEVEL) AS 
		(
        SELECT T1.id, T1.name, T1.surname, T1.chief, CAST (T1.id AS VARCHAR (50)) as PATH, 1
            FROM doctors T1 WHERE T1.chief IS NULL
        UNION
        SELECT T2.id, T2.name, T2.surname, T2.chief, CAST (temp1.PATH ||'->'|| T2.id AS VARCHAR(50)), LEVEL + 1
            FROM doctors T2 INNER JOIN temp1 ON(temp1.id = T2.chief)
		)
		select * from temp1
)
$$ LANGUAGE SQL;

SELECT * FROM parents();

--Хранимая процедура без параметров или с параметрами
CREATE PROCEDURE add_reception(_patient integer, _doctor integer, _date_time timestamp) AS $$
    INSERT INTO receprions(patient, date_time, doctor) VALUES (_patient, _date_time, _doctor);
$$ LANGUAGE SQL;

CALL add_reception(2, 5, '2019-11-16');

--Хранимая процедура с курсором
CREATE OR REPLACE PROCEDURE count_specialities(_cat _CATEGORY, _spec text) AS $$
	DECLARE
		high_doctors_cursor NO SCROLL CURSOR FOR SELECT d.id FROM doctors d WHERE d.category = _cat AND d.speciality = _spec;
		cnt integer := 0;
		rec_doctors RECORD;
	BEGIN
		OPEN high_doctors_cursor;
		LOOP
			FETCH high_doctors_cursor INTO rec_doctors;
			IF NOT FOUND THEN EXIT;END IF;
			cnt = cnt + 1;
		END LOOP;
		RAISE NOTICE 'Врачей специальности "%" категории "%" всего: %', _spec, _cat, cnt;
		CLOSE high_doctors_cursor;
	END;
$$ LANGUAGE plpgsql;

CALL count_specialities('Высшая', 'Валеолог');

--Хранимая процедура доступа к метаданным
CREATE OR REPLACE PROCEDURE meta() AS $$
	DECLARE tx CURSOR FOR 	
		SELECT 
			format('%I.%I.%I', fk.table_schema, fk.table_name, fk.column_name) AS foreign_side,
			format('%I.%I.%I', pk.table_schema, pk.table_name, pk.column_name) AS target_side
		FROM information_schema.referential_constraints rc 
			INNER JOIN information_schema.key_column_usage fk 
			ON (rc.constraint_catalog = fk.constraint_catalog 
			AND rc.constraint_schema = fk.constraint_schema 
			AND rc.constraint_name = fk.constraint_name) 
			INNER JOIN information_schema.constraint_column_usage pk 
			ON (rc.unique_constraint_catalog = pk.constraint_catalog 
			AND rc.unique_constraint_schema = rc.constraint_schema 
			AND rc.unique_constraint_name = pk.constraint_name);
		-- The view key_column_usage identifies all columns in the current database that are restricted by some unique, primary key, or foreign key constraint.
		-- The view constraint_column_usage identifies all columns in the current database that are used by some constraint. 
		-- For a foreign key constraint, this view identifies the columns that the foreign key references.
			
		rec_tables RECORD;
BEGIN

	OPEN tx;
	LOOP
		FETCH tx INTO rec_tables;
			
		IF NOT FOUND THEN 
			EXIT;
		END IF;
			
		RAISE NOTICE '% -> %', rec_tables.foreign_side, rec_tables.target_side;
	END LOOP;
	CLOSE tx;
	
END;
$$ LANGUAGE plpgsql;

CALL meta();

--Рекурсивную хранимую процедуру или хранимую процедур с рекурсивным ОТВ
ALTER TABLE doctors ADD COLUMN chief INTEGER;
ALTER TABLE doctors ADD CONSTRAINT doctors_doctors_fkey REFERENCES doctors.id;

CREATE PROCEDURE chiefs() AS $$
	DECLARE tx CURSOR FOR
		WITH RECURSIVE temp1 (id, name, surname, parent, PATH, LEVEL) AS 
		(
        SELECT T1.id, T1.name, T1.surname, T1.chief, CAST (T1.id AS VARCHAR (50)) as PATH, 1
            FROM doctors T1 WHERE T1.chief IS NULL
        UNION
        SELECT T2.id, T2.name, T2.surname, T2.chief, CAST (temp1.PATH ||'->'|| T2.id AS VARCHAR(50)), LEVEL + 1
            FROM doctors T2 INNER JOIN temp1 ON(temp1.id = T2.chief)
		)
		select * from temp1;
	rec_tables RECORD;
BEGIN
	OPEN tx;
	LOOP
		FETCH tx INTO rec_tables;
			
		IF NOT FOUND THEN 
			EXIT;
		END IF;
			
		RAISE NOTICE '%, %, %, %, %, %', rec_tables.id, rec_tables.name, rec_tables.surname, rec_tables.parent, rec_tables.PATH, rec_tables.LEVEL;
	END LOOP;
	CLOSE tx;
END;
$$ LANGUAGE plpgsql;

CALL chiefs();


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
