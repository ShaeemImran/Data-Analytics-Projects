/*
Data Cleaning Project: World Layoffs Dataset
Database: MySQL
Author: Shaeem Imran
Steps: 
1. Create Staging Tables
2. Remove Duplicates
3. Standardize Data (Formatting & Misspellings)
4. Handle Null and Blank Values
5. Remove Irrelevant Columns/Rows
*/

USE world_layoffs;

-- -----------------------------------------------------------------------------
-- STEP 1: STAGING & DATA PROFILING
-- -----------------------------------------------------------------------------

-- Create an initial staging table to protect the source data
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging 
SELECT * FROM layoffs;

-- Describe table structure
DESCRIBE layoffs_staging;

-- -----------------------------------------------------------------------------
-- STEP 2: REMOVING DUPLICATES
-- -----------------------------------------------------------------------------

-- Use a CTE to identify duplicate rows based on all columns
WITH duplicate_cte AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, 
                     funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- Create a secondary staging table to physically store row numbers for deletion
CREATE TABLE layoffs_staging2 (
  company VARCHAR(100),
  location VARCHAR(100),
  industry VARCHAR(100),
  total_laid_off INT,
  percentage_laid_off FLOAT,
  `date` DATE,
  stage VARCHAR(50),
  country VARCHAR(50),
  funds_raised_millions FLOAT,
  row_num INT
);

-- Insert data while standardizing the date format and assigning row numbers
INSERT INTO layoffs_staging2
SELECT
  company,
  location,
  industry,
  total_laid_off,
  percentage_laid_off,
  STR_TO_DATE(`date`, '%m/%d/%Y'),
  stage,
  country,
  funds_raised_millions,
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, 
                 percentage_laid_off, `date`, stage, country, 
                 funds_raised_millions
  ) AS row_num
FROM layoffs_staging;

-- Delete identified duplicates
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- -----------------------------------------------------------------------------
-- STEP 3: STANDARDIZING DATA
-- -----------------------------------------------------------------------------

-- 1. Trim whitespace from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2. Standardize Industry names (e.g., 'CryptoCurrency' -> 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3. Fix Country names (Remove trailing periods)
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 4. Final Data Type conversion for Date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- -----------------------------------------------------------------------------
-- STEP 4: HANDLING NULL AND BLANK VALUES
-- -----------------------------------------------------------------------------

-- Convert blank industry strings to NULL for easier processing
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Self-join to populate missing industry values using other rows from the same company
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Remove records where essential data (layoffs) is missing
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- -----------------------------------------------------------------------------
-- STEP 5: FINAL CLEANUP
-- -----------------------------------------------------------------------------

-- Drop the helper row_num column used for deduplication
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final data check
SELECT * FROM layoffs_staging2;
