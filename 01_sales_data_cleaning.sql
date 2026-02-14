-- SQL Data Cleaning Project: Messy Retail Sales Data
-- Database: MySQL

USE messy_sales;

---------------------------------------------------------
-- STEP 1: STAGING & PROFILING
---------------------------------------------------------

-- Create a staging table to preserve original data
CREATE TABLE messy_backup AS
SELECT * FROM messy_inventory_practice;

-- Initial data profiling
DESCRIBE messy_backup;
SELECT * FROM messy_backup LIMIT 20;

---------------------------------------------------------
-- STEP 2: COLUMN STANDARDIZATION
---------------------------------------------------------

-- Rename columns for clarity
ALTER TABLE messy_backup RENAME COLUMN Price_Each TO Price_Per_Quantity;
ALTER TABLE messy_backup RENAME COLUMN Sale_Date TO Sales_date;

-- Standardize Text (Trim spaces and fix capitalization: 'laptop' -> 'Laptop')
UPDATE messy_backup
SET Product_Name = CONCAT(UPPER(LEFT(TRIM(Product_Name),1)), LOWER(SUBSTRING(TRIM(Product_Name),2))),
Category     = CONCAT(UPPER(LEFT(TRIM(Category),1)),     LOWER(SUBSTRING(TRIM(Category),2)));

-- Standardize inconsistent category and product naming
UPDATE messy_backup SET Category = 'Electronics' WHERE Category IN ('Elec');
UPDATE messy_backup SET Category = 'Gadgets'     WHERE Category IN ('Gads');
UPDATE messy_backup SET Product_Name = 'SmartPhone' WHERE Product_Name IN ('Smart phone', 'Smartphone');
UPDATE messy_backup SET Product_Name = 'Tablet'     WHERE Product_Name = 'Tablets';

---------------------------------------------------------
-- STEP 3: DATA TYPE & DATE NORMALIZATION
---------------------------------------------------------

-- Add a column for the standardized date
ALTER TABLE messy_backup ADD COLUMN Sales_date_updated DATE;

-- Transactional update to handle multiple date formats safely using IGNORE keyword
START TRANSACTION;

UPDATE IGNORE messy_backup
SET Sales_date_updated = COALESCE(
    STR_TO_DATE(Sales_date, '%Y-%m-%d'), -- 2024-01-01
    STR_TO_DATE(Sales_date, '%Y.%m.%d'), -- 2024.03.01
    STR_TO_DATE(Sales_date, '%Y/%m/%d'), -- 2024/01/09
    STR_TO_DATE(Sales_date, '%d-%m-%Y'), -- 06-01-2024
    STR_TO_DATE(Sales_date, '%d/%m/%Y'), -- 01/02/2024
    STR_TO_DATE(Sales_date, '%m/%d/%Y')  -- 01/09/2024
);

COMMIT;

---------------------------------------------------------
-- STEP 4: HANDLING NULLS & INVALID STRINGS
---------------------------------------------------------

-- Replace placeholder strings with NULLs
UPDATE messy_backup SET Product_Name = NULL WHERE Product_Name IN ('','?','ERROR','NA','None');
UPDATE messy_backup SET Category     = NULL WHERE Category     IN ('','?','ERROR','NA','None');
UPDATE messy_backup SET Quantity     = NULL WHERE Quantity     IN ('','?','ERROR','NA','None');
UPDATE messy_backup SET Total_Price  = NULL WHERE Total_Price  IN ('','?','ERROR','NA','None');
UPDATE messy_backup SET Sales_date   = NULL WHERE Sales_date   IN ('','?','ERROR','NA','None');

---------------------------------------------------------
-- STEP 5: MATHEMATICAL DATA DEALING
---------------------------------------------------------

-- Fill missing Quantity using Total Price and Unit Price
UPDATE messy_backup 
SET Quantity = Total_Price / Price_Per_Quantity 
WHERE Quantity IS NULL 
  AND Total_Price IS NOT NULL 
  AND Price_Per_Quantity > 0;
-- Price_Per_Quantity > 0--> if dividing by =0 it'll crash

-- Fill missing Total Price using Quantity and Unit Price
UPDATE messy_backup
SET Total_Price = Quantity * Price_Per_Quantity
WHERE Total_Price IS NULL
  AND Quantity IS NOT NULL 
  AND Price_Per_Quantity IS NOT NULL;

-- Cleaned Data
SELECT * FROM messy_backup;
