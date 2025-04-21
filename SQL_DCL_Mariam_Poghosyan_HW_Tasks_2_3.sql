--2.1
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
-- Make sure the user can connect to the database, but no table permissions yet

--2.2
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;
GRANT SELECT ON TABLE customer TO rentaluser;

-- run this to verify:
SELECT * FROM customer;


--2.3
CREATE ROLE rental;
GRANT rental TO rentaluser;


--2.4

GRANT INSERT, UPDATE ON rental TO rental;

-- Switch to rentaluser and test:
-- Insert a new row
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NOW(), 1);

-- Update an existing row
UPDATE rental
SET return_date = NOW()
WHERE rental_id = 1;

GRANT USAGE ON SCHEMA public TO rentaluser;



--2.5
REVOKE INSERT ON rental FROM rental;

-- Test denial (should result in an error)
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NOW(), 1);

--2.6


SELECT DISTINCT c.first_name, c.last_name, c.customer_id
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
LIMIT 1;


CREATE ROLE client_Mary_Smith LOGIN PASSWORD 'clientpassword';
GRANT CONNECT ON DATABASE dvdrental TO client_Mary_Smith;
GRANT USAGE ON SCHEMA public TO client_Mary_Smith;
GRANT SELECT ON payment, rental TO client_Mary_Smith;

-- As client_Mary_Smith
SELECT * FROM payment WHERE customer_id = 5;
SELECT * FROM rental WHERE customer_id = 5;



--3.1
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

--3.2
CREATE POLICY rental_policy_client_mary_smith
ON rental
FOR SELECT
TO client_Mary_Smith
USING (customer_id = 5);

CREATE POLICY payment_policy_client_mary_smith
ON payment
FOR SELECT
TO client_Mary_Smith
USING (customer_id = 5);


--3.3

SELECT * FROM rental;
SELECT * FROM payment;
REVOKE UPDATE, DELETE ON rental, payment FROM client_Mary_Smith;


