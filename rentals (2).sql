--Rubric B--
CREATE OR REPLACE FUNCTION decimal_to_money(decimal_val DECIMAL)
RETURNS MONEY AS $$
BEGIN
    RETURN decimal_val::MONEY;
END;
$$ LANGUAGE plpgsql;

--Rubric B Test
SELECT decimal_to_money(amount) from payment


--Rubric C--
--Summary Table--
CREATE TABLE summary_table (
    category_id INT,
    name VARCHAR(50),
    total_amount DECIMAL(10, 2),
    PRIMARY KEY (category_id),
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

--Rubric C Test
SELECT * FROM summary_table;

--Detailed Table--
CREATE TABLE detailed_table (
    category_id INT,
    rental_id INT,
    payment_id INT,
    name VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10, 2),
    PRIMARY KEY (payment_id),  -- each sale is identified by a unique payment
    FOREIGN KEY (category_id) REFERENCES category(category_id),
    FOREIGN KEY (rental_id) REFERENCES rental(rental_id),
    FOREIGN KEY (payment_id) REFERENCES payment(payment_id)
);


--Rubric C Test
SELECT * FROM detailed_table;



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

--Rubric D Test
SELECT 
    category_id, 
    name, 
    decimal_to_money(total_amount)
FROM
    summary_table;



--Detailed Table Data Entry--
INSERT INTO detailed_table (category_id, rental_id, payment_id, name, sale_date, amount)
SELECT 
    c.category_id, 
    r.rental_id,
    p.payment_id,
    c.name, 
    r.rental_date AS sale_date,
    p.amount AS amount
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
    payment p ON r.rental_id = p.rental_id;


--Rubric D Test
SELECT 
    category_id, 
    rental_id, 
    payment_id, 
    name, 
    sale_date, 
    decimal_to_money(amount)
FROM 
    detailed_table;


--Rubric E--
CREATE OR REPLACE FUNCTION update_summary_table_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the total_amount in summary_table for the affected category
    UPDATE summary_table s
    SET total_amount = (
        SELECT COALESCE(SUM(d.amount), 0)
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
        VALUES (NEW.category_id, 
                (SELECT name FROM category WHERE category_id = NEW.category_id), 
                COALESCE(NEW.amount, 0));
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
        c.category_id, c.name
    ON CONFLICT (category_id) DO NOTHING;
END;
$$;

CALL refresh_tables();
















