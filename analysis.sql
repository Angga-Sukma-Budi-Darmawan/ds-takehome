-- SOAL 1: Menghitung skor RFM + ≥ 6 segmen pelanggan
WITH base_rfm AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS freq_order,
        SUM(payment_value) AS total_payment,
        DATEDIFF('2025-05-06', MAX(order_date)) AS latest_order
    FROM e_commerce_transactions
    GROUP BY customer_id
),

recency_ranked AS (
    SELECT 
        customer_id,
        latest_order,
        NTILE(5) OVER (ORDER BY latest_order DESC) AS recency_score
    FROM base_rfm
),

frequency_ranked AS (
    SELECT 
        customer_id,
        freq_order,
        NTILE(5) OVER (ORDER BY freq_order ASC) AS frequency_score
    FROM base_rfm
),

monetary_ranked AS (
    SELECT 
        customer_id,
        total_payment,
        NTILE(5) OVER (ORDER BY total_payment ASC) AS monetary_score
    FROM base_rfm
)

SELECT 
    r.customer_id,
    r.latest_order,
    f.freq_order,
    m.total_payment,
    r.recency_score,
    f.frequency_score,
    m.monetary_score,
    CONCAT(r.recency_score, f.frequency_score, m.monetary_score) AS rfm_segment
FROM recency_ranked r
JOIN frequency_ranked f ON r.customer_id = f.customer_id
JOIN monetary_ranked m ON r.customer_id = m.customer_id
ORDER BY 4;

-- SOAL 2: Cek Anomali
WITH noise_quartiles AS (
    SELECT *, 
           NTILE(4) OVER (ORDER BY decoy_noise) AS noise_qtile
    FROM e_commerce_transactions
),

q_values AS (
    SELECT 
        MAX(CASE WHEN noise_qtile = 1 THEN decoy_noise END) AS q1,
        MAX(CASE WHEN noise_qtile = 3 THEN decoy_noise END) AS q3
    FROM noise_quartiles
),

threshold AS (
    SELECT 
        q1, 
        q3, 
        (q3 - q1) AS iqr,
        (q3 + 5 * (q3 - q1)) AS upper_bound
    FROM q_values
)

SELECT e.*
FROM e_commerce_transactions e
JOIN threshold t ON e.decoy_noise > t.upper_bound
ORDER BY e.decoy_noise;




-- SOAL 3 : Query repeat-purchase bulanan
WITH monthly_orders AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_yearmonth,
        COUNT(DISTINCT order_id) AS orders_in_month
    FROM e_commerce_transactions
    GROUP BY customer_id, order_yearmonth
)

SELECT 
    customer_id,
    order_yearmonth,
    orders_in_month
FROM monthly_orders
WHERE orders_in_month > 1
ORDER BY 1;

WITH monthly_orders AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_yearmonth,
        COUNT(DISTINCT order_id) AS orders_in_month
    FROM e_commerce_transactions
    GROUP BY customer_id, order_yearmonth
)

SELECT
    order_yearmonth,
    COUNT(DISTINCT customer_id) AS repeated_customers
FROM monthly_orders
WHERE orders_in_month > 1
GROUP BY order_yearmonth
ORDER BY order_yearmonth;



