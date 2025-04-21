-- 1️.1 Add favorite movies to the 'film' table
INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext)
VALUES 
('Interstellar', 'A team of explorers travels through a wormhole in space to save humanity.', 2014, 1, 7 * 1, 4.99, 169, 19.99, 'PG-13', NOW(), ARRAY['Behind the Scenes', 'Commentary'], ''),
('Fast and Furious', 'A group of street racers gets involved in heists and high-speed chases.', 2001, 1, 7 * 2, 9.99, 106, 17.99, 'PG-13', NOW(), ARRAY['Deleted Scenes', 'Trailer'], ''),
('Good Children Don''t Cry', 'A touching story of a young girl battling illness and finding strength in friendship.', 2012, 1, 7 * 3, 19.99, 96, 16.99, 'PG', NOW(), ARRAY['Trailer', 'Behind the Scenes'], '')
RETURNING film_id;

-- 1.2️ Add actors to the 'actor' table
INSERT INTO actor (first_name, last_name)
VALUES 
('Matthew', 'McConaughey'),  -- Interstellar
('Anne', 'Hathaway'),        -- Interstellar
('Vin', 'Diesel'),           -- Fast and Furious
('Paul', 'Walker'),          -- Fast and Furious
('Hanna', 'Obbeek'),         -- Good Children Don''t Cry
('Nils', 'Verkooijen')       -- Good Children Don''t Cry
RETURNING actor_id;

-- 1.3️ Link actors to their films in 'film_actor'
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT actor_id, film_id, NOW()
FROM actor, film
WHERE 
    (first_name = 'Matthew' AND last_name = 'McConaughey' AND title = 'Interstellar')
 OR (first_name = 'Anne' AND last_name = 'Hathaway' AND title = 'Interstellar')
 OR (first_name = 'Vin' AND last_name = 'Diesel' AND title = 'Fast and Furious')
 OR (first_name = 'Paul' AND last_name = 'Walker' AND title = 'Fast and Furious')
 OR (first_name = 'Hanna' AND last_name = 'Obbeek' AND title = 'Good Children Don''t Cry')
 OR (first_name = 'Nils' AND last_name = 'Verkooijen' AND title = 'Good Children Don''t Cry');

-- 1.4️ Add movies to a store's inventory (store_id = 1)
INSERT INTO inventory (film_id, store_id, last_update)
SELECT film_id, 1, NOW() FROM film WHERE title IN ('Interstellar', 'Fast and Furious', 'Good Children Don''t Cry');

-- 1.5️ Find a customer with at least 43 rentals & 43 payments and update their info
UPDATE customer
SET first_name = 'John', last_name = 'Doe', address_id = 100, email = 'john.doe@example.com', last_update = NOW()
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
);

-- 1.6️ Remove all records related to the updated customer except from 'Customer' and 'Inventory'
DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'John' AND last_name = 'Doe');
DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'John' AND last_name = 'Doe');

-- 1.7️ Rent the movies and insert payment records
WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-10 10:00:00', i.inventory_id, c.customer_id, 1, '2017-01-17 10:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON c.first_name = 'John' AND c.last_name = 'Doe'
    WHERE f.title = 'Interstellar'
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, 4.99, '2017-01-10' FROM rentals;

WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-11 14:00:00', i.inventory_id, c.customer_id, 1, '2017-01-18 14:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON c.first_name = 'John' AND c.last_name = 'Doe'
    WHERE f.title = 'Fast and Furious'
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, 9.99, '2017-01-11' FROM rentals;

WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-12 18:00:00', i.inventory_id, c.customer_id, 1, '2017-01-19 18:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON c.first_name = 'John' AND c.last_name = 'Doe'
    WHERE f.title = 'Good Children Don''t Cry'
    RETURNING rental_id, customer_id
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, 19.99, '2017-01-12' FROM rentals;


