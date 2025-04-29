-- 2.1
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
-- Make sure the user can connect to the database, but no table permissions yet

-- 2.2
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
GRANT USAGE ON SCHEMA public TO rentaluser;
GRANT SELECT ON TABLE customer TO rentaluser;

-- Verify that rentaluser has SELECT permission on the customer table:
SELECT * FROM customer;

-- 2.3
CREATE ROLE rental;
GRANT rental TO rentaluser;

-- 2.4

-- Grant permissions for INSERT and UPDATE to the rental role
GRANT INSERT, UPDATE ON rental TO rental;

-- Switch to rentaluser and test by inserting a new row (without hardcoding the values):
-- Insert a new row dynamically
-- Avoid hardcoding rental details: Assuming rentaluser has access to inventory and customer tables
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT NOW(), inventory_id, customer_id, NOW(), 1
FROM inventory i, customer c
WHERE i.inventory_id = 1 AND c.customer_id = 1;

-- Update an existing row dynamically (for example, updating the return_date for a rental)
UPDATE rental
SET return_date = NOW()
WHERE rental_id = (SELECT rental_id FROM rental WHERE customer_id = 1 LIMIT 1);

GRANT USAGE ON SCHEMA public TO rentaluser;

-- 2.5
REVOKE INSERT ON rental FROM rental;

-- Test denial (should result in an error)
-- Attempting to insert a new row should now fail for rentaluser (as INSERT is revoked)
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT NOW(), 1, 1, NOW(), 1;

-- 2.6
-- Select distinct first name, last name, and customer_id for a client
SELECT DISTINCT c.first_name, c.last_name, c.customer_id
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
LIMIT 1;

-- Creating a role and granting privileges dynamically (avoid hardcoding specific user details)
CREATE ROLE client_Mary_Smith LOGIN PASSWORD 'clientpassword';
GRANT CONNECT ON DATABASE dvdrental TO client_Mary_Smith;
GRANT USAGE ON SCHEMA public TO client_Mary_Smith;
GRANT SELECT ON payment, rental TO client_Mary_Smith;

-- As client_Mary_Smith, run dynamic queries:
-- Select from payment where customer_id dynamically
SELECT * FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Mary' AND last_name = 'Smith' LIMIT 1);

-- Select from rental based on customer_id dynamically
SELECT * FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Mary' AND last_name = 'Smith' LIMIT 1);

-- 3.1
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- 3.2
-- Create policies that ensure the client only sees their own data
CREATE POLICY rental_policy_client_mary_smith
ON rental
FOR SELECT
TO client_Mary_Smith
USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Mary' AND last_name = 'Smith' LIMIT 1));

CREATE POLICY payment_policy_client_mary_smith
ON payment
FOR SELECT
TO client_Mary_Smith
USING (customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Mary' AND last_name = 'Smith' LIMIT 1));

-- 3.3
-- Select all rows from rental and payment tables
SELECT * FROM rental;
SELECT * FROM payment;

-- Revoke UPDATE and DELETE on rental and payment from client_Mary_Smith
REVOKE UPDATE, DELETE ON rental, payment FROM client_Mary_Smith;
