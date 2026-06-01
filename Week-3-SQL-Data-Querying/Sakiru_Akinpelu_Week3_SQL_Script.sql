-- ============================================================
--  AnalystLab Africa | Week 3: SQL & Data Querying
--  Prepared by  : Sakiru Akinpelu
--  Program      : AnalystLab Africa Data Analytics Internship
--  Databases    : Chinook (PostgreSQL) | Sales Data (MySQL)
--  Tools        : pgAdmin 4 | MySQL Workbench
-- ============================================================


-- ============================================================
-- PART 1: CHINOOK MUSIC STORE DATABASE (PostgreSQL)
-- ============================================================


-- ------------------------------------------------------------
-- SECTION 1: DATABASE SETUP & SCHEMA EXPLORATION
-- ------------------------------------------------------------

-- 1.1 List all tables in the Chinook database
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 1.2 Preview key tables
SELECT * FROM "artist"       LIMIT 5;
SELECT * FROM "album"        LIMIT 5;
SELECT * FROM "track"        LIMIT 5;
SELECT * FROM "customer"     LIMIT 5;
SELECT * FROM "invoice"      LIMIT 5;
SELECT * FROM "invoice_line" LIMIT 5;
SELECT * FROM "employee"     LIMIT 5;
SELECT * FROM "genre"        LIMIT 5;


-- ------------------------------------------------------------
-- SECTION 2: CORE SQL QUERIES
-- ------------------------------------------------------------

-- 2.1 List all artists alphabetically
SELECT * FROM "artist"
ORDER BY "name";

-- 2.2 Count total number of tracks
SELECT COUNT(*) AS total_tracks
FROM "track";

-- 2.3 Find all tracks priced above $0.99
SELECT "name", "unit_price"
FROM "track"
WHERE "unit_price" > 0.99
ORDER BY "unit_price" DESC;

-- 2.4 Overall revenue summary
SELECT
    SUM("total")   AS total_revenue,
    AVG("total")   AS avg_invoice_value,
    COUNT(*)       AS total_invoices
FROM "invoice";


-- ------------------------------------------------------------
-- SECTION 3: GROUP BY, HAVING & AGGREGATES
-- ------------------------------------------------------------

-- 3.1 Total revenue by country
SELECT
    "billing_country",
    COUNT(*)                                    AS total_invoices,
    ROUND(SUM("total")::NUMERIC, 2)             AS total_revenue
FROM "invoice"
GROUP BY "billing_country"
ORDER BY total_revenue DESC;

-- 3.2 Number of tracks per genre
SELECT
    g."name"                  AS genre,
    COUNT(t."track_id")       AS total_tracks
FROM "genre" g
JOIN "track" t ON g."genre_id" = t."genre_id"
GROUP BY g."name"
ORDER BY total_tracks DESC;

-- 3.3 Top 10 best-selling artists by revenue
SELECT
    ar."name"                                                       AS artist,
    ROUND(SUM(il."unit_price" * il."quantity")::NUMERIC, 2)        AS total_revenue
FROM "artist" ar
JOIN "album"        al ON ar."artist_id"  = al."artist_id"
JOIN "track"        t  ON al."album_id"   = t."album_id"
JOIN "invoice_line" il ON t."track_id"    = il."track_id"
GROUP BY ar."name"
ORDER BY total_revenue DESC
LIMIT 10;

-- 3.4 Countries with total revenue greater than $100 (HAVING)
SELECT
    "billing_country",
    ROUND(SUM("total")::NUMERIC, 2) AS total_revenue
FROM "invoice"
GROUP BY "billing_country"
HAVING SUM("total") > 100
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- SECTION 4: JOINS
-- ------------------------------------------------------------

-- 4.1 INNER JOIN — Invoices with customer names
SELECT
    c."first_name" || ' ' || c."last_name"  AS customer_name,
    c."country",
    i."invoice_date",
    i."total"
FROM "customer" c
INNER JOIN "invoice" i ON c."customer_id" = i."customer_id"
ORDER BY i."total" DESC
LIMIT 10;

-- 4.2 LEFT JOIN — All customers with invoice totals (including customers with no invoices)
SELECT
    c."first_name" || ' ' || c."last_name"      AS customer_name,
    c."country",
    COUNT(i."invoice_id")                        AS total_invoices,
    ROUND(SUM(i."total")::NUMERIC, 2)            AS total_spent
FROM "customer" c
LEFT JOIN "invoice" i ON c."customer_id" = i."customer_id"
GROUP BY c."customer_id", c."first_name", c."last_name", c."country"
ORDER BY total_spent DESC
LIMIT 10;

-- 4.3 Multiple JOINs — Tracks purchased with album and artist details
SELECT
    ar."name"       AS artist,
    al."title"      AS album,
    t."name"        AS track,
    il."unit_price",
    il."quantity"
FROM "invoice_line" il
JOIN "track"  t  ON il."track_id"  = t."track_id"
JOIN "album"  al ON t."album_id"   = al."album_id"
JOIN "artist" ar ON al."artist_id" = ar."artist_id"
ORDER BY il."unit_price" DESC
LIMIT 10;

-- 4.4 Customer with their assigned support representative
SELECT
    c."first_name" || ' ' || c."last_name"      AS customer_name,
    c."country",
    e."first_name" || ' ' || e."last_name"      AS support_rep
FROM "customer" c
JOIN "employee" e ON c."support_rep_id" = e."employee_id"
ORDER BY support_rep, customer_name;


-- ------------------------------------------------------------
-- SECTION 5: SUBQUERIES
-- ------------------------------------------------------------

-- 5.1 Customers who spent more than the average customer spending
SELECT
    c."first_name" || ' ' || c."last_name"  AS customer_name,
    ROUND(SUM(i."total")::NUMERIC, 2)        AS total_spent
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
GROUP BY c."customer_id", c."first_name", c."last_name"
HAVING SUM(i."total") > (
    SELECT AVG(total_per_customer)
    FROM (
        SELECT SUM("total") AS total_per_customer
        FROM "invoice"
        GROUP BY "customer_id"
    ) AS avg_spend
)
ORDER BY total_spent DESC;

-- 5.2 Tracks that have never been purchased
SELECT
    t."name"        AS track_name,
    t."unit_price"
FROM "track" t
WHERE t."track_id" NOT IN (
    SELECT DISTINCT "track_id"
    FROM "invoice_line"
)
ORDER BY t."name";

-- 5.3 Most popular genre by number of purchases
SELECT
    g."name"        AS genre,
    COUNT(*)        AS total_purchases
FROM "genre" g
JOIN "track"        t  ON g."genre_id"  = t."genre_id"
JOIN "invoice_line" il ON t."track_id"  = il."track_id"
WHERE g."genre_id" = (
    SELECT t2."genre_id"
    FROM "track" t2
    JOIN "invoice_line" il2 ON t2."track_id" = il2."track_id"
    GROUP BY t2."genre_id"
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
GROUP BY g."name";

-- 5.4 Customers with above-average order value
SELECT
    c."first_name" || ' ' || c."last_name"  AS customer_name,
    ROUND(AVG(i."total")::NUMERIC, 2)        AS avg_order_value
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
GROUP BY c."customer_id", c."first_name", c."last_name"
HAVING AVG(i."total") > (
    SELECT AVG("total") FROM "invoice"
)
ORDER BY avg_order_value DESC;


-- ------------------------------------------------------------
-- SECTION 6: WINDOW FUNCTIONS
-- ------------------------------------------------------------

-- 6.1 RANK() — Rank customers by total spending
SELECT
    c."first_name" || ' ' || c."last_name"      AS customer_name,
    c."country",
    ROUND(SUM(i."total")::NUMERIC, 2)            AS total_spent,
    RANK() OVER (ORDER BY SUM(i."total") DESC)   AS spending_rank
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
GROUP BY c."customer_id", c."first_name", c."last_name", c."country"
ORDER BY spending_rank;

-- 6.2 PARTITION BY — Rank customers within each country
SELECT
    c."first_name" || ' ' || c."last_name"          AS customer_name,
    c."country",
    ROUND(SUM(i."total")::NUMERIC, 2)                AS total_spent,
    RANK() OVER (
        PARTITION BY c."country"
        ORDER BY SUM(i."total") DESC
    )                                                AS country_rank
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
GROUP BY c."customer_id", c."first_name", c."last_name", c."country"
ORDER BY c."country", country_rank;

-- 6.3 ROW_NUMBER() — Number each customer's purchases chronologically
SELECT
    c."first_name" || ' ' || c."last_name"  AS customer_name,
    i."invoice_date",
    i."total",
    ROW_NUMBER() OVER (
        PARTITION BY c."customer_id"
        ORDER BY i."invoice_date"
    )                                        AS purchase_number
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
ORDER BY customer_name, purchase_number;

-- 6.4 Running total of revenue over time
SELECT
    "invoice_date",
    ROUND("total"::NUMERIC, 2)                              AS daily_revenue,
    ROUND(SUM("total") OVER (
        ORDER BY "invoice_date"
    )::NUMERIC, 2)                                          AS running_total
FROM "invoice"
ORDER BY "invoice_date";

-- 6.5 Compare each invoice to the customer's average spending
SELECT
    c."first_name" || ' ' || c."last_name"          AS customer_name,
    i."invoice_date",
    ROUND(i."total"::NUMERIC, 2)                     AS invoice_total,
    ROUND(AVG(i."total") OVER (
        PARTITION BY c."customer_id"
    )::NUMERIC, 2)                                   AS customer_avg_spending,
    ROUND((i."total" - AVG(i."total") OVER (
        PARTITION BY c."customer_id"
    ))::NUMERIC, 2)                                  AS difference_from_avg
FROM "customer" c
JOIN "invoice" i ON c."customer_id" = i."customer_id"
ORDER BY customer_name, i."invoice_date";


-- ============================================================
-- PART 2: SAMPLE SALES DATABASE (MySQL)
-- ============================================================


-- ------------------------------------------------------------
-- SECTION 7: DATABASE SETUP
-- ------------------------------------------------------------

-- 7.1 Select the database
USE sales_data;

-- 7.2 Create the sales table
CREATE TABLE sales (
    ordernumber      INT,
    quantityordered  INT,
    priceeach        DECIMAL(10,2),
    orderlinenumber  INT,
    sales            DECIMAL(10,2),
    orderdate        VARCHAR(50),
    status           VARCHAR(50),
    qtr_id           INT,
    month_id         INT,
    year_id          INT,
    productline      VARCHAR(100),
    msrp             INT,
    productcode      VARCHAR(50),
    customername     VARCHAR(100),
    phone            VARCHAR(50),
    addressline1     VARCHAR(100),
    addressline2     VARCHAR(100),
    city             VARCHAR(50),
    state            VARCHAR(50),
    postalcode       VARCHAR(50),
    country          VARCHAR(50),
    territory        VARCHAR(50),
    contactlastname  VARCHAR(50),
    contactfirstname VARCHAR(50),
    dealsize         VARCHAR(20)
);

-- 7.3 Preview the data
SELECT * FROM sales LIMIT 10;


-- ------------------------------------------------------------
-- SECTION 8: CORE SQL QUERIES
-- ------------------------------------------------------------

-- 8.1 Overall sales summary
SELECT
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue,
    ROUND(AVG(sales),2) AS avg_order_value,
    MIN(sales)          AS min_sale,
    MAX(sales)          AS max_sale
FROM sales;

-- 8.2 Total revenue by product line
SELECT
    productline,
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY productline
ORDER BY total_revenue DESC;

-- 8.3 Total revenue by country
SELECT
    country,
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY country
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- SECTION 9: GROUP BY, HAVING & ADVANCED AGGREGATES
-- ------------------------------------------------------------

-- 9.1 Revenue by year
SELECT
    year_id,
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY year_id
ORDER BY year_id;

-- 9.2 Revenue by quarter
SELECT
    year_id,
    qtr_id              AS quarter,
    ROUND(SUM(sales),2) AS total_revenue,
    COUNT(*)            AS total_orders
FROM sales
GROUP BY year_id, qtr_id
ORDER BY year_id, qtr_id;

-- 9.3 Top 10 customers by revenue
SELECT
    customername,
    country,
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY customername, country
ORDER BY total_revenue DESC
LIMIT 10;

-- 9.4 Product lines with revenue greater than $500,000 (HAVING)
SELECT
    productline,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY productline
HAVING SUM(sales) > 500000
ORDER BY total_revenue DESC;

-- 9.5 Revenue by deal size
SELECT
    dealsize,
    COUNT(*)            AS total_orders,
    ROUND(SUM(sales),2) AS total_revenue,
    ROUND(AVG(sales),2) AS avg_order_value
FROM sales
GROUP BY dealsize
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- SECTION 10: SUBQUERIES
-- ------------------------------------------------------------

-- 10.1 Customers who spent above the average customer spending
SELECT
    customername,
    country,
    ROUND(SUM(sales),2) AS total_spent
FROM sales
GROUP BY customername, country
HAVING SUM(sales) > (
    SELECT AVG(total_per_customer)
    FROM (
        SELECT SUM(sales) AS total_per_customer
        FROM sales
        GROUP BY customername
    ) AS avg_table
)
ORDER BY total_spent DESC;

-- 10.2 Best performing month per year
SELECT
    year_id,
    month_id,
    ROUND(SUM(sales),2) AS monthly_revenue
FROM sales
GROUP BY year_id, month_id
HAVING SUM(sales) = (
    SELECT MAX(monthly_total)
    FROM (
        SELECT year_id AS yr, SUM(sales) AS monthly_total
        FROM sales
        WHERE sales.year_id = year_id
        GROUP BY month_id
    ) AS monthly_table
)
ORDER BY year_id;

-- 10.3 Products performing above average within their product line
SELECT
    productcode,
    productline,
    ROUND(SUM(sales),2) AS product_revenue
FROM sales
GROUP BY productcode, productline
HAVING SUM(sales) > (
    SELECT AVG(line_total)
    FROM (
        SELECT SUM(sales) AS line_total
        FROM sales AS inner_sales
        WHERE inner_sales.productline = sales.productline
        GROUP BY productcode
    ) AS line_avg
)
ORDER BY productline, product_revenue DESC;

-- 10.4 Countries generating above-average revenue
SELECT
    country,
    ROUND(SUM(sales),2) AS total_revenue
FROM sales
GROUP BY country
HAVING SUM(sales) > (
    SELECT AVG(country_total)
    FROM (
        SELECT SUM(sales) AS country_total
        FROM sales
        GROUP BY country
    ) AS country_avg
)
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- SECTION 11: WINDOW FUNCTIONS
-- ------------------------------------------------------------

-- 11.1 RANK() — Rank customers by total revenue
SELECT
    customername,
    country,
    ROUND(SUM(sales),2)                             AS total_revenue,
    RANK() OVER (ORDER BY SUM(sales) DESC)          AS revenue_rank
FROM sales
GROUP BY customername, country
ORDER BY revenue_rank
LIMIT 10;

-- 11.2 PARTITION BY — Rank customers within each country
SELECT
    customername,
    country,
    ROUND(SUM(sales),2)                             AS total_revenue,
    RANK() OVER (
        PARTITION BY country
        ORDER BY SUM(sales) DESC
    )                                               AS country_rank
FROM sales
GROUP BY customername, country
ORDER BY country, country_rank;

-- 11.3 Running total of revenue by year
SELECT
    year_id,
    month_id,
    ROUND(SUM(sales),2)                             AS monthly_revenue,
    ROUND(SUM(SUM(sales)) OVER (
        PARTITION BY year_id
        ORDER BY month_id
    ),2)                                            AS running_total
FROM sales
GROUP BY year_id, month_id
ORDER BY year_id, month_id;

-- 11.4 Compare each order to its product line average
SELECT
    ordernumber,
    productline,
    ROUND(sales,2)                                  AS order_sales,
    ROUND(AVG(sales) OVER (
        PARTITION BY productline
    ),2)                                            AS productline_avg,
    ROUND(sales - AVG(sales) OVER (
        PARTITION BY productline
    ),2)                                            AS difference_from_avg
FROM sales
ORDER BY productline, difference_from_avg DESC;

-- 11.5 ROW_NUMBER() — Top product per country
SELECT
    country,
    productline,
    ROUND(total_revenue,2) AS total_revenue
FROM (
    SELECT
        country,
        productline,
        SUM(sales)          AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY country
            ORDER BY SUM(sales) DESC
        )                   AS rn
    FROM sales
    GROUP BY country, productline
) AS ranked
WHERE rn = 1
ORDER BY total_revenue DESC;


-- ============================================================
-- END OF SCRIPT
-- Prepared by: Sakiru Akinpelu | AnalystLab Africa | Week 3
-- ============================================================
