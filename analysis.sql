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
),

rfm_combined AS (
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
)

SELECT *,
    CASE -- definisi segmen rfm
        WHEN rfm_segment IN ('555','554','544','545','454','455','445') THEN 'Champion'
        WHEN rfm_segment IN ('543','444','435','355','354','345','344','335') THEN 'Loyal Customer'
        WHEN rfm_segment IN ('553','551','552','541','542','533','532','531','452','451','442','441','431','453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential Loyalist'
        WHEN rfm_segment IN ('512','511','422','421','412','411','311') THEN 'New Customer'
        WHEN rfm_segment IN ('525','524','523','522','521','515','514','513','425','424','413','414','415','315','314','313') THEN 'Promising'
        WHEN rfm_segment IN ('535','534','443','434','343','334','325','324') THEN 'Need Attention'
        WHEN rfm_segment IN ('155','154','144','214','215','115','114','113') THEN 'Cannot Lose Them'
        WHEN rfm_segment IN ('331','321','312','221','213') THEN 'About to Sleep'
        WHEN rfm_segment IN ('255','254','245','244','253','252','243','242','235','234','225','224','153','152','145','143','142','135','134','133','125','124') THEN 'At Risk'
        WHEN rfm_segment IN ('332','322','231','241','251','233','232','223','222','132','123','122','212','211') THEN 'Hibernating'
        WHEN rfm_segment IN ('111','112','121','131','141','151') THEN 'Lost'
        ELSE 'Others'
    END AS rfm_category
FROM rfm_combined
ORDER BY rfm_segment;

-- ANALISA SEGMEN : Jumlah Pelanggan per Segmen
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
),

rfm_combined AS (
    SELECT 
        r.customer_id,
        CONCAT(r.recency_score, f.frequency_score, m.monetary_score) AS rfm_segment
    FROM recency_ranked r
    JOIN frequency_ranked f ON r.customer_id = f.customer_id
    JOIN monetary_ranked m ON r.customer_id = m.customer_id
),

rfm_categorized AS (
    SELECT *,
        CASE
            WHEN rfm_segment IN ('555','554','544','545','454','455','445') THEN 'Champion'
            WHEN rfm_segment IN ('543','444','435','355','354','345','344','335') THEN 'Loyal Customer'
            WHEN rfm_segment IN ('553','551','552','541','542','533','532','531','452','451','442','441','431','453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential Loyalist'
            WHEN rfm_segment IN ('512','511','422','421','412','411','311') THEN 'New Customer'
            WHEN rfm_segment IN ('525','524','523','522','521','515','514','513','425','424','413','414','415','315','314','313') THEN 'Promising'
            WHEN rfm_segment IN ('535','534','443','434','343','334','325','324') THEN 'Need Attention'
            WHEN rfm_segment IN ('155','154','144','214','215','115','114','113') THEN 'Cannot Lose Them'
            WHEN rfm_segment IN ('331','321','312','221','213') THEN 'About to Sleep'
            WHEN rfm_segment IN ('255','254','245','244','253','252','243','242','235','234','225','224','153','152','145','143','142','135','134','133','125','124') THEN 'At Risk'
            WHEN rfm_segment IN ('332','322','231','241','251','233','232','223','222','132','123','122','212','211') THEN 'Hibernating'
            WHEN rfm_segment IN ('111','112','121','131','141','151') THEN 'Lost'
            ELSE 'Others'
        END AS rfm_category
    FROM rfm_combined
)

SELECT 
    rfm_category,
    COUNT(*) AS num_customers
FROM rfm_categorized
GROUP BY rfm_category
ORDER BY num_customers DESC;


-- SOAL 2: CEK ANOMALI (Extreme Outlier = q3 + 3 * (q3 - q1))
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
        (q3 + 3 * (q3 - q1)) AS upper_bound
    FROM q_values
)

SELECT e.*
FROM e_commerce_transactions e
JOIN threshold t ON e.decoy_noise > t.upper_bound
ORDER BY e.decoy_noise;

-- PENJELASAN : decoy_noise right-skewed, sehingga extreme outlier (anomali) ada pada nilai decoy_noise besar
-- nilai decoy_noise minimum & maksimum
SELECT 
    MAX(decoy_noise) AS max_decoy_noise,
    MIN(decoy_noise) AS min_decoy_noise
FROM e_commerce_transactions;

-- JUMLAH ANOMALI:
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
        (q3 + 3 * (q3 - q1)) AS upper_bound
    FROM q_values
)

SELECT 
    COUNT(*) AS num_anomalies
FROM e_commerce_transactions e
JOIN threshold t ON e.decoy_noise > t.upper_bound;

-- SOAL 3 : Query repeat-purchase bulanan
WITH monthly_orders AS (
    SELECT
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m') AS order_yearmonth,
        COUNT(DISTINCT order_id) AS orders_in_month
    FROM e_commerce_transactions
    GROUP BY customer_id, order_yearmonth
),
customers_with_multiple_orders AS (
    SELECT 
        customer_id,
        order_yearmonth
    FROM monthly_orders
    WHERE orders_in_month > 1
)

SELECT 
    order_yearmonth,
    COUNT(DISTINCT customer_id) AS num_recurring_customers
FROM customers_with_multiple_orders
GROUP BY order_yearmonth
ORDER BY order_yearmonth;

-- ANALISA : Pelanggan Baru pada tiap Bulan
WITH first_order AS (
    SELECT 
        customer_id,
        MIN(order_date) AS first_order_date
    FROM e_commerce_transactions
    GROUP BY customer_id
),

new_customers_per_month AS (
    SELECT 
        DATE_FORMAT(first_order_date, '%Y-%m') AS month,
        COUNT(*) AS new_customers
    FROM first_order
    GROUP BY month
)

SELECT *
FROM new_customers_per_month
ORDER BY month;