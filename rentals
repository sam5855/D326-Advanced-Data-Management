--Rubric B--
CREATE OR REPLACE FUNCTION decimal_to_money(decimal_val DECIMAL)
RETURNS MONEY AS $$
BEGIN
    RETURN decimal_val::MONEY;
END;
$$ LANGUAGE plpgsql;


--Rubric C--
--Summary Table--
CREATE TABLE summary_table (
    category_id INT,
    name VARCHAR(50),
    total_amount DECIMAL(10, 2),
    PRIMARY KEY (category_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

--Detailed Table--
CREATE TABLE detailed_table (
    category_id INT,
    name VARCHAR(50),
    rental_count INT,
    amount DECIMAL(10, 2),
    inventory_count INT,
    PRIMARY KEY (category_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);



--Rubric D--
--Summary Table Data Entry 
INSERT INTO summary_table (category_id, name, total_amount)
SELECT 
    c.category_id, 
    c.name, 
    SUM(p.amount) AS total_amount
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
LEFT JOIN 
    payment p ON r.rental_id = p.rental_id
GROUP BY 
    c.category_id, c.name;





--Detailed Table Data Entry--
INSERT INTO detailed_table (category_id, name, rental_count, amount, inventory_count)
SELECT 
    c.category_id, 
    c.name, 
    COUNT(r.rental_id) AS rental_count,
    SUM(p.amount) AS amount,
    COUNT(DISTINCT i.film_id) AS inventory_count
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
LEFT JOIN 
    payment p ON r.rental_id = p.rental_id
GROUP BY 
    c.category_id, c.name;


--Rubric E--
CREATE OR REPLACE FUNCTION update_summary_table_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the total_amount in summary_table for the affected category
    UPDATE summary_table s
    SET total_amount = (
        SELECT COALESCE(SUM(d.amount))
        FROM detailed_table d
        WHERE d.category_id = NEW.category_id
    )
    WHERE s.category_id = NEW.category_id;

    -- If the category does not exist in summary_table, insert it
    IF NOT EXISTS (
        SELECT 1
        FROM summary_table
        WHERE category_id = NEW.category_id
    ) THEN
        INSERT INTO summary_table (category_id, name, total_amount)
        VALUES (NEW.category_id, NEW.name, COALESCE(NEW.amount, 0));
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_summary_table_trigger
AFTER INSERT OR UPDATE ON detailed_table
FOR EACH ROW
EXECUTE FUNCTION update_summary_table_function();




--Rubric F--
CREATE OR REPLACE PROCEDURE refresh_tables()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Clear detailed_table
    DELETE FROM detailed_table;

    -- Step 2: Clear summary_table
    DELETE FROM summary_table;

    -- Step 3: Repopulate detailed_table
    INSERT INTO detailed_table (category_id, name, rental_count, amount, inventory_count)
    SELECT 
        c.category_id, 
        c.name, 
        COUNT(r.rental_id) AS rental_count,
        COALESCE(SUM(p.amount), 0) AS amount,
        COUNT(DISTINCT i.film_id) AS inventory_count
    FROM 
        category c
    JOIN 
        film_category fc ON c.category_id = fc.category_id
    JOIN 
        film f ON fc.film_id = f.film_id
    JOIN 
        inventory i ON f.film_id = i.film_id
    LEFT JOIN 
        rental r ON i.inventory_id = r.inventory_id
    LEFT JOIN 
        payment p ON r.rental_id = p.rental_id
    GROUP BY 
        c.category_id, c.name;

    -- Step 4: Repopulate summary_table
    INSERT INTO summary_table (category_id, name, total_amount)
    SELECT 
        c.category_id, 
        c.name, 
        SUM(p.amount) AS total_amount
    FROM 
        category c
    JOIN 
        film_category fc ON c.category_id = fc.category_id
    JOIN 
        film f ON fc.film_id = f.film_id
    JOIN 
        inventory i ON f.film_id = i.film_id
    LEFT JOIN 
        rental r ON i.inventory_id = r.inventory_id
    LEFT JOIN 
        payment p ON r.rental_id = p.rental_id
    GROUP BY 
        c.category_id, c.name;
    --=================
    ON CONFLICT (category_id) DO NOTHING;
END;
$$;

CALL refresh_tables();
















--==================================================================================================--
--Detailed table with populating data--
CREATE TABLE detailed_table AS
SELECT 
    c.category_id, 
    c.name, 
    COUNT(r.rental_id) AS rental_count,
    SUM(p.amount) AS amount,
    COUNT(DISTINCT i.film_id) AS inventory_count
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
LEFT JOIN 
    payment p ON r.rental_id = p.rental_id
GROUP BY 
    c.category_id, c.name;

--Summary table with populating data--
CREATE TABLE summary_table AS
SELECT 
    c.name, 
    SUM(p.amount) AS total_amount
FROM 
    category c
JOIN 
    film_category fc ON c.category_id = fc.category_id
JOIN 
    film f ON fc.film_id = f.film_id
JOIN 
    inventory i ON f.film_id = i.film_id
LEFT JOIN 
    rental r ON i.inventory_id = r.inventory_id
LEFT JOIN 
    payment p ON r.rental_id = p.rental_id
GROUP BY 
    c.name;