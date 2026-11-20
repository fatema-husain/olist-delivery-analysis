USE olist;
SHOW TABLES;
USE olist;

-- 1. How many orders are there in each status?
SELECT order_status, COUNT(*) AS orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 2. What date range does the data cover?
SELECT MIN(order_purchase_timestamp) AS first_order,
       MAX(order_purchase_timestamp) AS last_order
FROM orders;

-- 3. Top 10 product categories by items sold (English names)
SELECT t.product_category_name_english AS category,
       COUNT(*) AS items_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY items_sold DESC
LIMIT 10;

-- 4. Average delivery time in days (delivered orders only)
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

-- 5. What % of delivered orders arrived late?
SELECT ROUND(100 * AVG(order_delivered_customer_date > order_estimated_delivery_date), 1) AS pct_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;

  -- 6. Do late deliveries get worse reviews?
SELECT
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
       THEN 'late' ELSE 'on time' END AS delivery,
  COUNT(*) AS orders,
  ROUND(AVG(r.review_score), 2) AS avg_review
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery;

-- 7. Orders per month (spot the near-empty months at either end)
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY month
ORDER BY month;

-- 8. Late delivery rate by customer state (where is it worst?)
SELECT c.customer_state,
       COUNT(*) AS orders,
       ROUND(100 * AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date), 1) AS pct_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING orders >= 500
ORDER BY pct_late DESC;

-- 9. How many late orders get a 1-star review vs on-time ones?
SELECT
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
       THEN 'late' ELSE 'on time' END AS delivery,
  ROUND(100 * AVG(r.review_score = 1), 1) AS pct_one_star
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery;

-- 10. Where are the sellers based?
SELECT seller_state, COUNT(*) AS sellers
FROM sellers
GROUP BY seller_state
ORDER BY sellers DESC
LIMIT 5;

-- 11. Is delivery later when seller and customer are in different states?
SELECT
  CASE WHEN s.seller_state = c.customer_state THEN 'same state' ELSE 'different state' END AS route,
  COUNT(DISTINCT o.order_id) AS orders,
  ROUND(100 * AVG(o.order_delivered_customer_date > o.order_estimated_delivery_date), 1) AS pct_late
FROM orders o
JOIN customers c   ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s     ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY route;

-- 12. For late vs on-time orders: where does the time go?
SELECT
  CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
       THEN 'late' ELSE 'on time' END AS delivery,
  ROUND(AVG(DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp)), 1) AS days_seller_to_courier,
  ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_delivered_carrier_date)), 1) AS days_courier_to_customer
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
GROUP BY delivery;

-- 13. Are the averages pulled up by a few extreme orders?
SELECT
  CASE
    WHEN DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) <= 7  THEN '1. 0-7 days'
    WHEN DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) <= 14 THEN '2. 8-14 days'
    WHEN DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) <= 30 THEN '3. 15-30 days'
    ELSE '4. 30+ days'
  END AS delivery_time,
  COUNT(*) AS orders,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY delivery_time
ORDER BY delivery_time;

-- 14. Does the main finding still hold inside the clean time window (Jan 2017 - Aug 2018)?
SELECT
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
       THEN 'late' ELSE 'on time' END AS delivery,
  COUNT(*) AS orders,
  ROUND(AVG(r.review_score), 2) AS avg_review,
  ROUND(100 * AVG(r.review_score = 1), 1) AS pct_one_star
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01'
GROUP BY delivery;
