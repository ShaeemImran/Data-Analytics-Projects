USE ecom_ops;

-- RENAME TABLE `ecom global operations mysql` TO raw_ecom_orders;

-- -----------------------------------------------------------------------------
-- 1. STAGING TABLE SETUP & PROFILING
-- -----------------------------------------------------------------------------

CREATE TABLE ecomm_staging LIKE raw_ecom_orders;

INSERT INTO ecomm_staging
SELECT * FROM raw_ecom_orders;

-- Profiling the data
SELECT * FROM raw_ecom_orders;
DESCRIBE raw_ecom_orders;

-- SELECT Order_ID, COUNT(*) 
-- FROM ecomm_staging
-- GROUP BY Order_ID
-- HAVING COUNT(*) > 1;

-- SELECT *
-- FROM ecomm_staging
-- WHERE Order_ID IN (10049, 10099, 10149);


-- -----------------------------------------------------------------------------
-- 2. DUPLICATE REMOVAL
-- -----------------------------------------------------------------------------

WITH dup_cte AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY 
                `Order_ID`,
                `Customer_Name`,
                `Region`,
                `Order_Date`,
                `Shipping_Date`,
                `Category`,
                `Quantity`,
                `Price_Per_Unit`,
                `Payment_Method`,
                `Return_Reason`,
                `Refund_Amount`
        ) AS rn
    FROM ecomm_staging
)
SELECT *
FROM dup_cte
WHERE rn = 1;


-- -----------------------------------------------------------------------------
-- 3. DATA STANDARDIZATION & CLEANING
-- -----------------------------------------------------------------------------

-- SELECT * FROM raw_ecom_orders;
SELECT * FROM ecomm_staging;

-- Trimming regions
UPDATE ecomm_staging
SET Region = TRIM(Region);

-- SELECT
-- CONCAT(
--     UPPER(LEFT(TRIM(Region), 1)),
--     LOWER(SUBSTRING(TRIM(Region), 2))
-- ) AS cleaned_region
-- FROM ecomm_staging;

UPDATE ecomm_staging
SET Region = CONCAT(
    UPPER(LEFT(TRIM(Region), 1)),
    LOWER(SUBSTRING(TRIM(Region), 2))
);

UPDATE ecomm_staging
SET Payment_Method = TRIM(Payment_Method);

UPDATE ecomm_staging
SET Category = TRIM(Category);

UPDATE ecomm_staging
SET Return_Reason = TRIM(Return_Reason);

-- SELECT Payment_Method,
-- CASE 
--     WHEN Payment_Method = 'credit card' THEN 'Credit Card'
--     ELSE Payment_Method
-- END AS cleaned_payment_method
-- FROM ecomm_staging;

UPDATE ecomm_staging
SET Payment_Method = CASE 
    WHEN Payment_Method = 'credit card' THEN 'Credit Card'
    ELSE Payment_Method
END;


-- -----------------------------------------------------------------------------
-- 4. NULL HANDLING & DATATYPE MODIFICATIONS
-- -----------------------------------------------------------------------------

SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Shipping_date IS NULL OR Shipping_date = '' THEN 1 ELSE 0 END) AS Missing_ShippingDates,
    SUM(CASE WHEN Return_Reason IS NULL OR Return_Reason = '' THEN 1 ELSE 0 END) AS Missing_ReturnReason,
    SUM(CASE WHEN Refund_Amount IS NULL OR Refund_Amount = '' THEN 1 ELSE 0 END) AS Missing_Refunds
FROM ecomm_staging;

-- Standard date format (2025-09-01) = Modify
-- Non-standard format = 28/09/01 = str_to_date then modify

-- Data type handling:
-- CONVERT THE EMPTY STRING '' TO NULL FIRST THEN MODIFY THE DATA TYPE. 
-- Since MySQL treats the empty string as string, converting directly to decimal/numeric throws an error.
UPDATE ecomm_staging
SET Shipping_Date = NULL
WHERE Shipping_Date = '';

UPDATE ecomm_staging
SET Order_Date = NULL
WHERE Order_Date = '';

UPDATE ecomm_staging
SET Refund_Amount = NULL
WHERE Refund_Amount = '';

UPDATE ecomm_staging
SET Return_Reason = NULL
WHERE Return_Reason = '';

ALTER TABLE ecomm_staging
    MODIFY COLUMN Shipping_Date DATE,
    MODIFY COLUMN Order_Date DATE,
    MODIFY COLUMN Refund_Amount DECIMAL(10,2); 

DESCRIBE ecomm_staging;


-- -----------------------------------------------------------------------------
-- 5. FEATURE ENGINEERING & ANOMALY CORRECTION
-- -----------------------------------------------------------------------------

ALTER TABLE ecomm_staging
    ADD COLUMN Total_revenue DECIMAL(10,2),
    ADD COLUMN Delivery_days INT;

SELECT * FROM ecomm_staging
LIMIT 10;

UPDATE ecomm_staging 
SET 
    Total_revenue = Quantity * Price_Per_Unit,
    Delivery_days = DATEDIFF(Shipping_Date, Order_Date);

-- To align with financial database standards and prevent float precision, convert Price_Per_Unit to DECIMAL(10,2):
ALTER TABLE ecomm_staging
    MODIFY Price_Per_Unit DECIMAL(10,2);

-- Fix negative prices and recalculate Total_revenue
UPDATE ecomm_staging
SET 
    Price_Per_Unit = ABS(Price_Per_Unit),
    Total_revenue = ABS(Quantity * Price_Per_Unit)
WHERE Price_Per_Unit < 0;

UPDATE ecomm_staging
SET Refund_Amount = ABS(Refund_Amount)
WHERE Refund_Amount < 0;










