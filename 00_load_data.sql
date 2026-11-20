-- =====================================================================
-- Olist SQL project: create the database, build 8 tables, load the CSVs
-- Run from Terminal, inside the folder that holds the CSV files:
--   /usr/local/mysql/bin/mysql --local-infile=1 -u root -p < load_olist.sql
-- (geolocation is left out on purpose; we can add it later)
-- =====================================================================

SET GLOBAL local_infile = 1;

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

-- ---------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------

CREATE TABLE customers (
    customer_id              VARCHAR(32) PRIMARY KEY,   -- one per ORDER
    customer_unique_id       VARCHAR(32) NOT NULL,      -- the real person
    customer_zip_code_prefix VARCHAR(5),                -- text: keeps leading zeros
    customer_city            VARCHAR(60),
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5),
    seller_city            VARCHAR(60),
    seller_state           CHAR(2)
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(60) PRIMARY KEY,
    product_category_name_english VARCHAR(60)
);

CREATE TABLE products (
    product_id                 VARCHAR(32) PRIMARY KEY,
    product_category_name      VARCHAR(60),
    product_name_length        INT,   -- source column is misspelt "lenght"
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE orders (
    order_id                      VARCHAR(32) PRIMARY KEY,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
    order_id            VARCHAR(32),
    order_item_id       INT,
    product_id          VARCHAR(32),
    seller_id           VARCHAR(32),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             VARCHAR(32),
    payment_sequential   INT,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id is NOT unique in this data (814 repeats), so the key is the pair
CREATE TABLE order_reviews (
    review_id               VARCHAR(32),
    order_id                VARCHAR(32),
    review_score            TINYINT,
    review_comment_title    VARCHAR(100),
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

-- ---------------------------------------------------------------------
-- 2. Load the CSVs
--    Blank cells are turned into NULL with NULLIF(..., '')
-- ---------------------------------------------------------------------

LOAD DATA LOCAL INFILE 'olist_customers_dataset.csv'
INTO TABLE customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'olist_sellers_dataset.csv'
INTO TABLE sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'product_category_name_translation.csv'
INTO TABLE category_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'olist_products_dataset.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, @cat, @nl, @dl, @ph, @w, @l, @h, @wd)
SET product_category_name      = NULLIF(@cat, ''),
    product_name_length        = NULLIF(@nl, ''),
    product_description_length = NULLIF(@dl, ''),
    product_photos_qty         = NULLIF(@ph, ''),
    product_weight_g           = NULLIF(@w, ''),
    product_length_cm          = NULLIF(@l, ''),
    product_height_cm          = NULLIF(@h, ''),
    product_width_cm           = NULLIF(@wd, '');

LOAD DATA LOCAL INFILE 'olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, @purch, @appr, @carr, @deliv, @est)
SET order_purchase_timestamp      = NULLIF(@purch, ''),
    order_approved_at             = NULLIF(@appr, ''),
    order_delivered_carrier_date  = NULLIF(@carr, ''),
    order_delivered_customer_date = NULLIF(@deliv, ''),
    order_estimated_delivery_date = NULLIF(@est, '');

LOAD DATA LOCAL INFILE 'olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'olist_order_payments_dataset.csv'
INTO TABLE order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- this file uses Windows line endings and has comments that span lines
LOAD DATA LOCAL INFILE 'olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(review_id, order_id, review_score, @title, @msg, @created, @answered)
SET review_comment_title    = NULLIF(@title, ''),
    review_comment_message  = NULLIF(@msg, ''),
    review_creation_date    = NULLIF(@created, ''),
    review_answer_timestamp = NULLIF(@answered, '');

-- ---------------------------------------------------------------------
-- 3. Check: compare each count with the expected number
-- ---------------------------------------------------------------------
SELECT 'customers'            AS table_name, COUNT(*) AS loaded_rows,  99441 AS expected FROM customers
UNION ALL SELECT 'sellers',              COUNT(*),   3095 FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*),     71 FROM category_translation
UNION ALL SELECT 'products',             COUNT(*),  32951 FROM products
UNION ALL SELECT 'orders',               COUNT(*),  99441 FROM orders
UNION ALL SELECT 'order_items',          COUNT(*), 112650 FROM order_items
UNION ALL SELECT 'order_payments',       COUNT(*), 103886 FROM order_payments
UNION ALL SELECT 'order_reviews',        COUNT(*),  99224 FROM order_reviews;
