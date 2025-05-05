--1 Sales report: Top 5 customers by sales per channel with sales percentage
SELECT
    channel,
    customer_id,
    ROUND(customer_sales, 2) AS total_sales_amount,
    TO_CHAR(ROUND((customer_sales / channel_total_sales) * 100, 4), 'FM999990.0000') || '%' AS sales_percentage
FROM (
    SELECT
        channel,
        customer_id,
        SUM(sales_amount) AS customer_sales,
        SUM(SUM(sales_amount)) OVER (PARTITION BY channel) AS channel_total_sales,  -- total sales in the same channel
        RANK() OVER (PARTITION BY channel ORDER BY SUM(sales_amount) DESC) AS rank_per_channel
    FROM sales
    GROUP BY channel, customer_id
) ranked_sales
WHERE rank_per_channel <= 5
ORDER BY channel, total_sales_amount DESC;



--2 Sales report: Total sales in Photo category, Asian region, year 2000
SELECT
    products.product_name,
    ROUND(SUM(sales.sales_amount), 2) AS total_sales,
    ROUND(SUM(SUM(sales.sales_amount)) OVER (), 2) AS YEAR_SUM -- Overall total for the report
FROM sales
JOIN products ON sales.product_id = products.product_id
JOIN categories ON products.category_id = categories.category_id
JOIN regions ON sales.region_id = regions.region_id
WHERE categories.category_name = 'Photo'
  AND regions.region_name = 'Asia'
  AND EXTRACT(YEAR FROM sales.sales_date) = 2000
GROUP BY products.product_name
ORDER BY YEAR_SUM DESC;



-- Example with crosstab to show sales by month for Photo category in the Asian region, year 2000
SELECT *
FROM crosstab(
    'SELECT products.product_name, EXTRACT(MONTH FROM sales.sales_date) AS month, SUM(sales.sales_amount) AS total_sales
     FROM sales
     JOIN products ON sales.product_id = products.product_id
     JOIN categories ON products.category_id = categories.category_id
     JOIN regions ON sales.region_id = regions.region_id
     WHERE categories.category_name = ''Photo''
       AND regions.region_name = ''Asia''
       AND EXTRACT(YEAR FROM sales.sales_date) = 2000
     GROUP BY products.product_name, month
     ORDER BY products.product_name, month',
    'SELECT generate_series(1, 12)'  -- Generating months from 1 to 12
) AS final_report(product_name TEXT, "Jan" NUMERIC, "Feb" NUMERIC, "Mar" NUMERIC, "Apr" NUMERIC, "May" NUMERIC, 
                  "Jun" NUMERIC, "Jul" NUMERIC, "Aug" NUMERIC, "Sep" NUMERIC, "Oct" NUMERIC, 
                  "Nov" NUMERIC, "Dec" NUMERIC);



--3 Sales report for top 300 customers by total sales across 1998, 1999, and 2001, categorized by sales channel
WITH sales_per_customer AS (
    SELECT
        customer_id,
        channel,
        SUM(sales_amount) AS total_sales
    FROM sales
    JOIN channels ON sales.channel_id = channels.channel_id
    WHERE EXTRACT(YEAR FROM sales.sales_date) IN (1998, 1999, 2001)  -- Sales years
    GROUP BY customer_id, channel
),
ranked_customers AS (
    SELECT
        customer_id,
        channel,
        total_sales,
        RANK() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS rank_per_channel
    FROM sales_per_customer
)
SELECT
    customer_id,
    channel,
    ROUND(total_sales, 2) AS total_sales
FROM ranked_customers
WHERE rank_per_channel <= 300  -- Top 300 customers
ORDER BY channel, total_sales DESC;


--4 Sales report for January, February, and March 2000 for Europe and Americas regions
SELECT
    TO_CHAR(sales.sales_date, 'Month') AS month,
    categories.category_name,
    ROUND(SUM(sales.sales_amount), 2) AS total_sales
FROM sales
JOIN products ON sales.product_id = products.product_id
JOIN categories ON products.category_id = categories.category_id
JOIN regions ON sales.region_id = regions.region_id
WHERE regions.region_name IN ('Europe', 'Americas')
  AND EXTRACT(YEAR FROM sales.sales_date) = 2000
  AND EXTRACT(MONTH FROM sales.sales_date) IN (1, 2, 3)  -- January, February, March
GROUP BY TO_CHAR(sales.sales_date, 'Month'), categories.category_name
ORDER BY month, categories.category_name;

