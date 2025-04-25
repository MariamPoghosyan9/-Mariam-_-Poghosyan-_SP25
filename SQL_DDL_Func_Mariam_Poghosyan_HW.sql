-- 1. Create Sales Revenue By Category for the Current Quarter:

CREATE OR REPLACE FUNCTION create_sales_revenue_by_category_qtr_view()
RETURNS void AS $$
DECLARE
    view_exists BOOLEAN;
    current_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
    current_qtr INT := EXTRACT(QUARTER FROM CURRENT_DATE);
BEGIN
    -- Check if the view already exists
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.views
        WHERE table_name = 'sales_revenue_by_category_qtr'
    ) INTO view_exists;

    -- Drop view if it already exists to ensure rerun works
    IF view_exists THEN
        DROP VIEW sales_revenue_by_category_qtr;
    END IF;

    -- Create the view
    EXECUTE format($f$
        CREATE VIEW sales_revenue_by_category_qtr AS
        SELECT 
            c.name AS category,
            SUM(p.amount) AS total_sales_revenue
        FROM 
            payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
        WHERE 
            EXTRACT(YEAR FROM p.payment_date) = %s AND
            EXTRACT(QUARTER FROM p.payment_date) = %s
        GROUP BY c.name
        HAVING SUM(p.amount) > 0
    $f$, current_year, current_qtr);

    RAISE NOTICE 'View "sales_revenue_by_category_qtr" created successfully for Year: %, Quarter: %', current_year, current_qtr;
END;
$$ LANGUAGE plpgsql;

-- Call example:
SELECT create_sales_revenue_by_category_qtr_view();


-- 2. Get Sales Revenue By Category for a Given Quarter and Year:

CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(qtr INT, yr INT)
RETURNS TABLE (
    category TEXT,
    total_sales_revenue NUMERIC
) AS $$
    SELECT 
        c.name AS category,
        SUM(p.amount) AS total_sales_revenue
    FROM 
        payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE 
        EXTRACT(YEAR FROM p.payment_date) = yr AND
        EXTRACT(QUARTER FROM p.payment_date) = qtr
    GROUP BY c.name
    HAVING SUM(p.amount) > 0
$$ LANGUAGE sql STABLE;

-- Call example:
SELECT * FROM get_sales_revenue_by_category_qtr(2, 2024);


-- 3. Most Popular Films By Country (One Film Per Country):

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE (
    country_name TEXT,
    film_title TEXT,
    rental_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH popular_films AS (
        SELECT 
            co.country,
            f.title,
            COUNT(*) AS rental_count,
            RANK() OVER (PARTITION BY co.country ORDER BY COUNT(*) DESC) AS rank
        FROM 
            rental r
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN customer cu ON r.customer_id = cu.customer_id
        JOIN address a ON cu.address_id = a.address_id
        JOIN city ci ON a.city_id = ci.city_id
        JOIN country co ON ci.country_id = co.country_id
        WHERE co.country = ANY(countries)
        GROUP BY co.country, f.title
    )
    SELECT country, title, rental_count
    FROM popular_films
    WHERE rank = 1;
END;
$$ LANGUAGE plpgsql STABLE;

-- Call example:
SELECT * FROM most_popular_films_by_countries(ARRAY['USA', 'Canada']);


-- 4. Films in Stock by Title (Last Customer for Each Film):

CREATE OR REPLACE FUNCTION films_in_stock_by_title(pattern TEXT)
RETURNS TABLE (
    row_num INT,
    film_id INT,
    title TEXT,
    available_stock INT
) AS $$
DECLARE
    no_match BOOLEAN := TRUE;
    row_counter INT := 0;
BEGIN
    FOR film_id, title, available_stock IN
        SELECT 
            f.film_id,
            f.title,
            COUNT(i.inventory_id) AS available_stock
        FROM film f
        JOIN inventory i ON f.film_id = i.film_id
        WHERE f.title ILIKE pattern
        AND i.inventory_id NOT IN (
            SELECT r.inventory_id
            FROM rental r
            WHERE return_date IS NULL
        )
        GROUP BY f.film_id, f.title
        ORDER BY f.title
    LOOP
        row_counter := row_counter + 1;
        no_match := FALSE;
        RETURN NEXT;
    END LOOP;

    IF no_match THEN
        RAISE NOTICE 'No films found with title matching % currently in stock.', pattern;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Call example:
SELECT * FROM films_in_stock_by_title('%love%');

-- 5. Insert a New Movie (Handling Language ID):

CREATE OR REPLACE FUNCTION new_movie(
    title TEXT,
    release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    language_name TEXT DEFAULT 'Klingon'
)
RETURNS VOID AS $$
DECLARE
    lang_id INT;
    new_film_id INT;
BEGIN
    -- Ensure language exists
    SELECT language_id INTO lang_id FROM language WHERE name = language_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" not found in language table.', language_name;
    END IF;
    -- Generate new film_id (assuming serial PK; otherwise use MAX + 1 approach)
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO new_film_id FROM film;
    -- Insert new film
    INSERT INTO film (
        film_id, title, description, release_year,
        language_id, rental_duration, rental_rate, replacement_cost, last_update
    ) VALUES (
        new_film_id, title, 'New movie', release_year,
        lang_id, 3, 4.99, 19.99, CURRENT_TIMESTAMP
    );

    RAISE NOTICE 'New film "%" inserted with ID %', title, new_film_id;
END;
$$ LANGUAGE plpgsql;

-- Call examples:
SELECT new_movie('The Epic Adventure');
SELECT new_movie('Alien Romance', 2020, 'English');

