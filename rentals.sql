--Rubric B--




--Rubric C--
CREATE TABLE rental_summary (
    name VARCHAR(25),
    total_amount NUMERIC(5,2)
);

CREATE TABLE rental_detail (
    category_id INT,
    name VARCHAR(25),
    rental_count INT,
    amount NUMERIC(5,2), 
    inventory_count INT;
);

