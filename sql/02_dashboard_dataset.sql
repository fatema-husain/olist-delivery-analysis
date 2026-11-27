-- =====================================================================
-- Olist delivery analysis: dataset for the Power BI dashboard
-- One row per delivered order, Jan 2017 - Aug 2018
-- Run after 00_load_data.sql
-- =====================================================================

USE olist;

SELECT
    o.order_id,
    DATE(o.order_purchase_timestamp)                                   AS purchase_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')                AS purchase_month,
    c.customer_state,
    s.seller_state,
    CASE WHEN s.seller_state = c.customer_state
         THEN 'Same state' ELSE 'Different state' END                  AS route,
    DATEDIFF(o.order_delivered_carrier_date, o.order_purchase_timestamp)       AS days_seller_to_courier,
    DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date)  AS days_courier_to_customer,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)      AS total_delivery_days,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Late' ELSE 'On time' END                                AS delivery_status,
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 1 ELSE 0 END                                             AS is_late,
    r.review_score
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
-- the seller of the first item stands in for the order's seller
LEFT JOIN order_items AS oi
    ON o.order_id = oi.order_id
   AND oi.order_item_id = 1
LEFT JOIN sellers AS s
    ON oi.seller_id = s.seller_id
-- some orders have more than one review: use the latest one
LEFT JOIN (
    SELECT order_id, review_score
    FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (PARTITION BY order_id
                                  ORDER BY review_answer_timestamp DESC) AS rn
        FROM order_reviews
    ) AS ranked
    WHERE rn = 1
) AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';
