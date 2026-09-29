-- EDA
USE ecom_ops;

SELECT * FROM ecomm_staging;

-- =============================================================================
-- 1. EXECUTIVE SUMMARY & HIGH-LEVEL METRICS
-- =============================================================================

SELECT
    COUNT(*) AS total_orders,
    MIN(Order_Date) AS first_Orderdate,
    MAX(Order_Date) AS fast_Orderdate,
    SUM(Total_revenue) AS gross_sales,
    SUM(COALESCE(Refund_Amount, 0)) AS total_refunds,
    SUM(Total_revenue - COALESCE(Refund_Amount, 0)) AS net_sales,
    AVG(Total_revenue) AS avg_order_value,
    AVG(Delivery_days) AS avg_deli_days
FROM ecomm_staging;

-- Red Flag: Over 16% of gross sales revenue is lost to refunds [refund/gross]


-- =============================================================================
-- 2. CATEGORICAL & REGIONAL EDA
-- =============================================================================

-- Categorical EDA (Group by) [categories: region, category]
SELECT 
    COUNT(*) AS total_orders,
    Category, 
    Region,
    SUM(Total_revenue) AS gross_sales,
    SUM(COALESCE(Refund_Amount, 0)) AS total_refunds
FROM ecomm_staging
GROUP BY Category, Region
ORDER BY gross_sales DESC;

-- Category level (highest sales, refund pct)
SELECT 
    COUNT(*) AS total_orders,
    Category,
    SUM(Total_revenue) AS gross_sales,
    SUM(COALESCE(Refund_Amount, 0)) AS total_refunds
FROM ecomm_staging
GROUP BY Category
ORDER BY gross_sales DESC;
-- Beauty generated highest revenue as well as the highest refund rates among all the categories

-- Analysis by region
SELECT 
    COUNT(*) AS total_orders,
    Region,
    SUM(Total_revenue) AS gross_sales,
    SUM(COALESCE(Refund_Amount, 0)) AS total_refunds,
    ROUND(SUM(COALESCE(Refund_Amount, 0)) / SUM(Total_revenue), 2) AS refund_pct
FROM ecomm_staging
GROUP BY Region
ORDER BY gross_sales DESC;


-- =============================================================================
-- 3. OPERATIONS, SHIPPING & RETURNS BREAKDOWN
-- =============================================================================

SELECT 
    Payment_Method,
    COUNT(Refund_Amount) AS Total_refunds,
    AVG(Delivery_days) AS avg_deli_days,
    ROUND((COUNT(Refund_Amount) * 100.0 / COUNT(*)), 2) AS refund_pct  -- refund/tot orders *100
FROM ecomm_staging
GROUP BY Payment_Method;

SELECT 
    Payment_Method,
    COUNT(*) AS total_orders
FROM ecomm_staging
GROUP BY Payment_Method
HAVING Payment_Method = 'Crypto';
-- Out of 533 orders for crypto, 227 orders were refunded.

-- What are the primary Return Reasons
SELECT 
    Payment_Method, 
    Return_Reason,
    COUNT(*) AS reason_count,
    SUM(COALESCE(Refund_Amount, 0)) AS total_refunds
FROM ecomm_staging
WHERE Return_Reason IS NOT NULL
GROUP BY Payment_Method, Return_Reason
ORDER BY Payment_Method, reason_count DESC;

-- SELECT COUNT(*) AS total_crypto_orders
-- FROM ecomm_staging
-- WHERE Payment_Method = 'Crypto';

-- The Core Bottleneck: Crypto payments carry an alarming 43% return rate,


-- =============================================================================
-- 4. THE 5 CORE ANALYTICAL FRAMEWORKS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Framework 1: Time Series Analysis & MoM Growth
-- -----------------------------------------------------------------------------

-- Problem solved: daily orders into monthly totals eg: all orders made on 2026-01 and giving a total revenue produced within that month,
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS orders_month,
    SUM(Total_revenue) AS gross_sales
FROM ecomm_staging
GROUP BY orders_month 
ORDER BY orders_month DESC; -- Aggregating by month reveals whether sales are growing, shrinking, or staying flat over time.

-- Month over month (MoM Growth Rate)

SELECT
    DATE_FORMAT(Order_Date, '%Y-%m') AS orders_month,
    SUM(Total_revenue) AS gross_sales,
    LAG(SUM(Total_revenue)) OVER (ORDER BY DATE_FORMAT(Order_Date, '%Y-%m')) AS prev_month_sales
FROM ecomm_staging
GROUP BY orders_month
ORDER BY orders_month;

-- Revenue experienced a drop of -13.97% (or roughly a 14% decline)
-- MoM Growth pct:
SELECT 
    DATE_FORMAT(Order_Date, '%Y-%m') AS orders_month,
    SUM(Total_revenue) AS gross_sales,
    LAG(SUM(Total_revenue)) OVER (ORDER BY DATE_FORMAT(Order_Date, '%Y-%m')) AS prev_month_sales,
    ROUND(
        (SUM(Total_revenue) - LAG(SUM(Total_revenue)) OVER (ORDER BY DATE_FORMAT(Order_Date, '%Y-%m')))
        / LAG(SUM(Total_revenue)) OVER (ORDER BY DATE_FORMAT(Order_Date, '%Y-%m')) * 100, 2
    ) AS mom_growth_pc
FROM ecomm_staging
GROUP BY orders_month
ORDER BY orders_month; 


-- -----------------------------------------------------------------------------
-- Framework 2: Cumulative Revenue (Running Total)
-- -----------------------------------------------------------------------------

-- Daily running totals
SELECT 
    Order_date, 
    SUM(Total_revenue) AS gross_sales,
    SUM(SUM(Total_revenue)) OVER (ORDER BY Order_date) AS running_total
FROM ecomm_staging
GROUP BY Order_date;

-- Monthly running totals
SELECT 
    DATE_FORMAT(Order_date, '%Y-%m') AS orders_month,
    SUM(Total_Revenue) AS gross_sales,
    SUM(SUM(Total_Revenue)) OVER (ORDER BY DATE_FORMAT(Order_date, '%Y-%m')) AS monthly_running_total
FROM ecomm_staging
GROUP BY orders_month
ORDER BY orders_month;
-- First Milestone ($1M+): The business crossed $1,000,000 in cumulative gross revenue in May 2025


-- -----------------------------------------------------------------------------
-- Framework 3: Customer Segmentation & Pareto (80/20 Rule)
-- -----------------------------------------------------------------------------

-- Total revenue spent per customer
SELECT 
    Customer_Name,
    SUM(Total_revenue) AS total_spent,
    COUNT(Order_Id) AS Total_orders
FROM ecomm_staging
GROUP BY Customer_Name
ORDER BY total_spent DESC
LIMIT 5;

-- Customer VIP Segmentation:
-- To make this insight actionable for marketing or leadership, we usually bucket customers into tiers using a CASE statement based on their total spending:
WITH customer_tier AS (
    SELECT 
        Customer_Name,
        SUM(Total_revenue) AS total_spent,
        COUNT(Order_Id) AS total_orders
    FROM ecomm_staging
    GROUP BY Customer_Name
)
SELECT 
    Customer_Name, 
    total_spent, 
    total_orders,
    CASE
        WHEN total_spent >= 15000 THEN 'VIP Customers'
        WHEN total_spent >= 5000 THEN 'Regular Customers'
        ELSE 'Low-value Customer'
    END AS Tier
FROM customer_tier
ORDER BY total_spent DESC;


-- -----------------------------------------------------------------------------
-- Framework 4: Cohort Analysis & Order Frequency (Customer Retention)
-- -----------------------------------------------------------------------------

WITH cust_retention AS (
    SELECT 
        Customer_Name,
        COUNT(Order_ID) AS total_orders,
        SUM(Total_Revenue) AS total_spent
    FROM ecomm_staging
    GROUP BY Customer_Name
)
SELECT 
    CASE
        WHEN total_orders > 1 THEN 'Repeat Buyers' 
        WHEN total_orders = 1 THEN 'One-Time Buyers'
    END AS buyer_type,
    COUNT(Customer_Name) AS customer_count,
    ROUND(SUM(total_spent), 2) AS grouped_revenue, -- adding that money per group of buyers 
    ROUND(AVG(total_orders), 2) AS Average_orders_count
FROM cust_retention
GROUP BY buyer_type
ORDER BY grouped_revenue DESC;


-- -----------------------------------------------------------------------------
-- Framework 5: Operational Efficiency & Payment Share
-- -----------------------------------------------------------------------------

SELECT 
    Payment_Method,
    COUNT(Order_ID) AS total_orders_count,
    SUM(Total_Revenue) AS Total_revenue,
    ROUND(AVG(Total_Revenue), 2) AS Avg_order_value,
    ROUND((SUM(Total_Revenue) * 100) / SUM(SUM(Total_Revenue)) OVER (), 2) AS pct_share_tot_rev
FROM ecomm_staging
GROUP BY Payment_Method
ORDER BY Avg_order_value DESC;