-- 1.1 Add favorite movies to the 'film' table (with dynamic language_id)
INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update, special_features, fulltext)
SELECT 
    'Interstellar', 
    'A team of explorers travels through a wormhole in space to save humanity.', 
    2014, 
    (SELECT language_id FROM language WHERE name = 'English'), 
    7 * 1, 
    4.99, 
    169, 
    19.99, 
    'PG-13'::mpaa_rating,  -- Explicit cast to mpaa_rating
    NOW(), 
    ARRAY['Behind the Scenes', 'Commentary'], 
    to_tsvector('english', '') 
UNION ALL
SELECT 
    'Fast and Furious', 
    'A group of street racers gets involved in heists and high-speed chases.', 
    2001, 
    (SELECT language_id FROM language WHERE name = 'English'), 
    7 * 2, 
    9.99, 
    106, 
    17.99, 
    'PG-13'::mpaa_rating, 
    NOW(), 
    ARRAY['Deleted Scenes', 'Trailer'], 
    to_tsvector('english', '')  
UNION ALL
SELECT 
    'Good Children Don''t Cry', 
    'A touching story of a young girl battling illness and finding strength in friendship.', 
    2012, 
    (SELECT language_id FROM language WHERE name = 'English'), 
    7 * 3, 
    19.99, 
    96, 
    16.99, 
    'PG'::mpaa_rating, 
    NOW(), 
    ARRAY['Trailer', 'Behind the Scenes'], 
    to_tsvector('english', 'A touching story of a young girl battling illness and finding strength in friendship.')  -- Example of tsvector conversion with a text


-- 1.2 Add actors to the 'actor' table
INSERT INTO actor (first_name, last_name)
VALUES 
    ('Matthew', 'McConaughey'),  -- Interstellar
    ('Anne', 'Hathaway'),        -- Interstellar
    ('Vin', 'Diesel'),           -- Fast and Furious
    ('Paul', 'Walker'),          -- Fast and Furious
    ('Hanna', 'Obbeek'),         -- Good Children Don't Cry
    ('Nils', 'Verkooijen');      -- Good Children Don't Cry

-- 1.3 Link actors to their films in 'film_actor' (dynamic actor_id, film_id)
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id, 
    f.film_id, 
    NOW()
FROM actor a
JOIN film f ON 
    (LOWER(a.first_name) = LOWER('Matthew') AND LOWER(a.last_name) = LOWER('McConaughey') AND LOWER(f.title) = LOWER('Interstellar'))
    OR (LOWER(a.first_name) = LOWER('Anne') AND LOWER(a.last_name) = LOWER('Hathaway') AND LOWER(f.title) = LOWER('Interstellar'))
    OR (LOWER(a.first_name) = LOWER('Vin') AND LOWER(a.last_name) = LOWER('Diesel') AND LOWER(f.title) = LOWER('Fast and Furious'))
    OR (LOWER(a.first_name) = LOWER('Paul') AND LOWER(a.last_name) = LOWER('Walker') AND LOWER(f.title) = LOWER('Fast and Furious'))
    OR (LOWER(a.first_name) = LOWER('Hanna') AND LOWER(a.last_name) = LOWER('Obbeek') AND LOWER(f.title) = LOWER('Good Children Don''t Cry'))
    OR (LOWER(a.first_name) = LOWER('Nils') AND LOWER(a.last_name) = LOWER('Verkooijen') AND LOWER(f.title) = LOWER('Good Children Don''t Cry'));


-- 1.4 Add movies to a store's inventory (store_id = 1, dynamic film_id)
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, NOW()
FROM film f
WHERE f.title IN ('Interstellar', 'Fast and Furious', 'Good Children Don''t Cry');


-- 1.5 Find a customer with at least 43 rentals & 43 payments and update their info (dynamic customer_id)
UPDATE customer 
SET 
    first_name = LOWER('John'), last_name = LOWER('Doe'), address_id = 100, email = LOWER('john.doe@example.com'), last_update = NOW()
WHERE customer_id = (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
);


-- 1.6 Remove all records related to the updated customer except from 'Customer' and 'Inventory' (dynamic customer_id)
DELETE FROM payment WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'John' AND last_name = 'Doe');
DELETE FROM rental WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'John' AND last_name = 'Doe');


-- 1.7 Rent the movies and insert payment records (dynamic rental dates and film titles)
WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-10 10:00:00', i.inventory_id, c.customer_id, 1, '2017-01-17 10:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON LOWER(c.first_name) = LOWER('John') AND LOWER(c.last_name) = LOWER('Doe') -- Dynamically match customer details
    WHERE f.title = 'Interstellar'  -- Dynamically select title from the film table
    RETURNING rental_id, customer_id, f.rental_rate  -- Dynamically retrieve rental rate from the film table
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, rental_rate, '2017-01-10' FROM rentals;

WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-11 14:00:00', i.inventory_id, c.customer_id, 1, '2017-01-18 14:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON LOWER(c.first_name) = LOWER('John') AND LOWER(c.last_name) = LOWER('Doe')  -- Dynamically match customer details
    WHERE f.title = 'Fast and Furious'  -- Dynamically select title from the film table
    RETURNING rental_id, customer_id, f.rental_rate  -- Dynamically retrieve rental rate from the film table
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, rental_rate, '2017-01-11' FROM rentals;

WITH rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT '2017-01-12 18:00:00', i.inventory_id, c.customer_id, 1, '2017-01-19 18:00:00', NOW()
    FROM inventory i
    JOIN film f ON i.film_id = f.film_id
    JOIN customer c ON LOWER(c.first_name) = LOWER('John') AND LOWER(c.last_name) = LOWER('Doe')  -- Dynamically match customer details
    WHERE f.title = 'Good Children Don''t Cry'  -- Dynamically select title from the film table
    RETURNING rental_id, customer_id, f.rental_rate  -- Dynamically retrieve rental rate from the film table
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT customer_id, 1, rental_id, rental_rate, '2017-01-12' FROM rentals;