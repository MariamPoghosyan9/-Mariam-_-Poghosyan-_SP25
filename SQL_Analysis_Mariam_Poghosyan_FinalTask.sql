--1
WITH ranked_sales AS (
    SELECT
        channel_desc,
        country_region,
        SUM(quantity_sold) AS sales,
        RANK() OVER (PARTITION BY channel_desc ORDER BY SUM(quantity_sold) DESC) AS sales_rank,
        SUM(SUM(quantity_sold)) OVER (PARTITION BY channel_desc) AS total_channel_sales
    FROM
        sales_data  -- Replace with your actual table name
    GROUP BY
        channel_desc,
        country_region
),
top_sales AS (
    SELECT
        channel_desc,
        country_region,
        ROUND(sales::numeric, 2) AS sales,
        ROUND((sales * 100.0 / total_channel_sales)::numeric, 2) || '%' AS "SALES %"
    FROM
        ranked_sales
    WHERE
        sales_rank = 1
)
SELECT *
FROM top_sales
ORDER BY sales DESC;


--2

WITH yearly_sales AS (
    SELECT
        prod_subcategory,
        EXTRACT(YEAR FROM time_id)::int AS sales_year,
        SUM(quantity_sold) AS total_sales
    FROM
        sales_data  -- Replace with your actual table name
    WHERE
        EXTRACT(YEAR FROM time_id) BETWEEN 1998 AND 2001
    GROUP BY
        prod_subcategory, EXTRACT(YEAR FROM time_id)
),
sales_with_lag AS (
    SELECT
        prod_subcategory,
        sales_year,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY prod_subcategory ORDER BY sales_year) AS prev_year_sales
    FROM
        yearly_sales
),
growth_flags AS (
    SELECT
        *,
        CASE
            WHEN prev_year_sales IS NOT NULL AND total_sales > prev_year_sales THEN 1
            ELSE 0
        END AS is_growth
    FROM
        sales_with_lag
    WHERE sales_year BETWEEN 1999 AND 2001
),
consistent_growers AS (
    SELECT
        prod_subcategory
    FROM
        growth_flags
    GROUP BY
        prod_subcategory
    HAVING COUNT(*) = 3 AND SUM(is_growth) = 3
)
SELECT prod_subcategory
FROM consistent_growers;


--3
WITH filtered_sales AS (
    SELECT
        EXTRACT(YEAR FROM time_id)::int AS calendar_year,
        TO_CHAR(time_id, 'YYYY-"Q"Q') AS calendar_quarter_desc,
        prod_category,
        channel_desc,
        ROUND(SUM(amount_sold)::numeric, 2) AS sales
    FROM
        sales_data  -- Replace with your table
    WHERE
        EXTRACT(YEAR FROM time_id) BETWEEN 1999 AND 2000
        AND prod_category IN ('Electronics', 'Hardware', 'Software/Other')
        AND channel_desc IN ('Partners', 'Internet')
    GROUP BY
        EXTRACT(YEAR FROM time_id),
        TO_CHAR(time_id, 'YYYY-"Q"Q'),
        prod_category,
        channel_desc
),
ranked_sales AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        channel_desc,
        sales,
        FIRST_VALUE(sales) OVER (
            PARTITION BY calendar_year, prod_category, channel_desc
            ORDER BY calendar_quarter_desc
        ) AS q1_sales,
        SUM(sales) OVER (
            PARTITION BY calendar_year, prod_category, channel_desc
            ORDER BY calendar_quarter_desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cum_sum
    FROM
        filtered_sales
),
final_report AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        ROUND(sales, 2) AS "SALES$",
        CASE
            WHEN sales = q1_sales THEN 'N/A'
            ELSE ROUND(((sales - q1_sales) * 100.0 / q1_sales)::numeric, 2) || '%'
        END AS "DIFF_PERCENT",
        ROUND(cum_sum, 2) AS "CUM_SUM$"
    FROM
        ranked_sales
)
SELECT *
FROM final_report
ORDER BY calendar_year, calendar_quarter_desc, "SALES$" DESC;

