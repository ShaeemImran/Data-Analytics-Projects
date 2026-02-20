/* DATA CLEANING PROJECT: Sales Inventory
( Standardize names, fix dates, and repair broken calculations. )
*/

-- 1. BACKUP & PREVIEW
CREATE TABLE inventory_staging AS 
SELECT * FROM messy_inventory_practice;

SELECT * FROM inventory_staging LIMIT 10;

-- 2. FIX COLUMN NAMES
-- Making headers consistent and readable.
ALTER TABLE inventory_staging RENAME COLUMN Price_Each TO Unit_Price;
ALTER TABLE inventory_staging RENAME COLUMN Sale_Date TO Transaction_Date;

-- 3. REMOVE DUPLICATES
-- Finding rows where every single piece of information is identical.
SELECT *, ROW_NUMBER() 
OVER (PARTITION BY Transaction_ID, Product_Name, Sales_date) as row_num
FROM inventory_staging;

-- 4. CLEAN TEXT & CATEGORIES
-- Remove extra spaces, fix capitalization, and group shorthand names (e.g., 'Elec' -> 'Electronics').
UPDATE inventory_staging
SET Product_Name = TRIM(CONCAT(UPPER(LEFT(Product_Name, 1)), LOWER(SUBSTRING(Product_Name, 2)))),
    Category = CASE 
        WHEN Category IN ('Elec', 'electronics') THEN 'Electronics'
        WHEN Category IN ('Gads', 'gadget') THEN 'Gadgets'
        ELSE TRIM(Category)
    END;

-- 5. STANDARDIZE DATE FORMATS
-- Converting various text formats (2024.01.01, 01/02/24) into a standard SQL Date.
UPDATE inventory_staging
SET Transaction_Date = COALESCE(
    STR_TO_DATE(Transaction_Date, '%Y-%m-%d'),
    STR_TO_DATE(Transaction_Date, '%m/%d/%Y'),
    STR_TO_DATE(Transaction_Date, '%d/%m/%Y'),
    STR_TO_DATE(Transaction_Date, '%Y.%m.%d')
);

-- 6. HANDLE MISSING VALUES (NULLS)
-- Replace '?' or 'NA' with actual NULL values (so the database recognizes them as empty)
UPDATE inventory_staging
SET Product_Name = NULL WHERE Product_Name IN ('?', 'NA', 'None', 'Error');

-- 7. REPAIR BROKEN MATH (For ensuring integrity)
-- (If) Quantity is missing but we have the Total and Unit Price, calculate it.
UPDATE inventory_staging 
SET Quantity = Total_Price / Unit_Price 
WHERE Quantity IS NULL AND Unit_Price > 0;

-- (If) Total Price is missing, calculate it from Quantity and Unit Price.
UPDATE inventory_staging 
SET Total_Price = Quantity * Unit_Price 
WHERE Total_Price IS NULL;

-- FINAL CHECK
SELECT * FROM inventory_staging;
