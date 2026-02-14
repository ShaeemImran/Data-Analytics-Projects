Phase 1: Data Cleaning
The raw data contained inconsistent dates, mixed product naming, and missing values. I implemented a robust cleaning pipeline in 01_sales_data_cleaning.sql:

Staging: Created a backup table to ensure data safety.
Schema Refinement: Standardized column names and data types.
Text Normalization: Unified product names (e.g., 'Smart phone' → 'SmartPhone') and fixed capitalization.
Date Standardisation: Resolved multiple date formats (e.g., DD/MM/YYYY, YYYY.MM.DD) into a single ISO-standard DATE column using prioritized COALESCE logic.
Data Healing: Used algebraic relationships (Qty * Price = Total) to fill in missing numerical values.
Null Handling: Replaced "junk" strings ('?', 'NA', 'None') with standard SQL NULL values.
