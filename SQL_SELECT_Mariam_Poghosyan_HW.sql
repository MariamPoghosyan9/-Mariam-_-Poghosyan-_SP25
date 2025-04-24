-- 1-1: Animation films released between 2017-2019 with rental_rate > 1
SELECT f.title, f.release_year
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id 
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE LOWER(c.name) = 'animation'
  AND f.release_year BETWEEN 2017 AND 2019 
  AND f.rental_rate > 1 
ORDER BY f.title ASC;

-- 1-2: Revenue per store from April 2017
SELECT 
  COALESCE(a.address, '') || COALESCE(', ' || a.address2, '') AS full_address,
  SUM(p.amount) AS revenue
FROM public.store s
INNER JOIN public.address a ON s.address_id = a.address_id 
INNER JOIN public.inventory i ON s.store_id = i.store_id 
INNER JOIN public.rental r ON i.inventory_id = r.inventory_id 
INNER JOIN public.payment p ON r.rental_id = p.rental_id 
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017 
  AND EXTRACT(MONTH FROM p.payment_date) > 3 
GROUP BY s.store_id, a.address, a.address2
ORDER BY revenue DESC;

-- 1-3: Top 5 actors by number of movies after 2015
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id 
INNER JOIN public.film f ON fa.film_id = f.film_id
WHERE f.release_year > 2015
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY number_of_movies DESC
LIMIT 5;

-- 1-4: Number of drama, travel, documentary movies per year
SELECT f.release_year,
       COUNT(CASE WHEN UPPER(c.name) = 'DRAMA' THEN f.film_id END) AS number_of_drama_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'TRAVEL' THEN f.film_id END) AS number_of_travel_movies,
       COUNT(CASE WHEN UPPER(c.name) = 'DOCUMENTARY' THEN f.film_id END) AS number_of_documentary_movies
FROM public.film f
INNER JOIN public.film_category fc ON f.film_id = fc.film_id
INNER JOIN public.category c ON fc.category_id = c.category_id
GROUP BY f.release_year
ORDER BY f.release_year DESC;

-- 2-1: Top 3 employees by revenue in 2017
WITH employee_revenue AS (
    SELECT 
        s.staff_id,
        s.store_id,
        SUM(p.amount) AS total_revenue,
        MAX(p.payment_date) AS last_payment_date
    FROM public.staff s
    INNER JOIN public.payment p ON s.staff_id = p.staff_id
    INNER JOIN public.rental r ON p.rental_id = r.rental_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.staff_id, s.store_id
)
SELECT 
    e.first_name || ' ' || e.last_name AS full_name,
    er.total_revenue
FROM employee_revenue er
JOIN public.staff e ON er.staff_id = e.staff_id
ORDER BY er.total_revenue DESC
LIMIT 3;


-- 2-2: Top 5 rented movies and audience age
WITH movie_rentals AS (
    SELECT f.film_id, f.title, COUNT(r.rental_id) AS rental_count, f.rating
    FROM public.film f
    INNER JOIN public.inventory i ON f.film_id = i.film_id
    INNER JOIN public.rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT mr.title, mr.rental_count,
       CASE 
           WHEN mr.rating = 'G' THEN 'All ages'
           WHEN mr.rating = 'PG' THEN 'Inappropriate for Children Under 13'
           WHEN mr.rating = 'PG-13' THEN 'Children Under 17 Require Accompanying Adult'
           WHEN mr.rating = 'R' THEN 'Inappropriate for Children Under 17'
           WHEN mr.rating = 'NC-17' THEN 'No one under 17'
           ELSE 'Unknown'
       END AS expected_audience_age
FROM movie_rentals mr
ORDER BY mr.rental_count DESC
LIMIT 5;

-- 3-1: Actor(s) with the longest time since last movie
WITH actor_last_movie AS (
    SELECT a.first_name, a.last_name,
           EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS years_since_last_movie
    FROM public.actor a
    INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
    INNER JOIN public.film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT * 
FROM actor_last_movie
WHERE years_since_last_movie = (SELECT MAX(years_since_last_movie) FROM actor_last_movie)
ORDER BY first_name, last_name;

-- 3-2: Actor(s) with the longest gap between two movies
WITH movie_gaps AS (
    SELECT a.actor_id, a.first_name, a.last_name, f1.release_year AS release_year,
           MIN(f2.release_year) AS next_release_year,
           COALESCE(MIN(f2.release_year) - f1.release_year, EXTRACT(YEAR FROM CURRENT_DATE) - f1.release_year) AS gap_between_films
    FROM public.actor a
    INNER JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
    INNER JOIN public.film f1 ON fa1.film_id = f1.film_id
    LEFT JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
    LEFT JOIN public.film f2 ON fa2.film_id = f2.film_id AND f2.release_year > f1.release_year 
    GROUP BY a.actor_id, a.first_name, a.last_name, f1.release_year
)
SELECT first_name, last_name, MAX(gap_between_films) AS longest_gap
FROM movie_gaps
WHERE gap_between_films IS NOT NULL
GROUP BY first_name, last_name
HAVING MAX(gap_between_films) = (SELECT MAX(gap_between_films) FROM movie_gaps)
ORDER BY first_name, last_name;