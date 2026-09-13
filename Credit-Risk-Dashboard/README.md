# Executive Banking Credit Risk & Risk Stratification Analytics Dashboard

## Business Problem Solved: Evaluated portfolio default risk across $77.7M in loan exposure by identifying high-risk borrower concentrations, quantifying a 20.71% delinquency rate, 
and monitoring Debt-to-Income (DTI) health across economic sectors to prevent loan losses.
---

## Key Steps & Technical Workflow

1. **Data Cleaning & Standardization (Excel / Power Query):**
   * Processed a raw portfolio dataset of 1,000 credit records.
   * Handled missing/invalid credit scores (flagged 30 unscorable records).
   * Standardized loan status classifications and calculated derived fields (`loan_age`, valid score flags).

2. **Data Modeling & Measures:**
   * Calculated total loan values using dynamic dynamic formulas (`SUMIFS`, `COUNTIFS`).
   * Formatted currency metrics visually using Custom Formatting 

3. **Dashboard Architecture & Visuals:**
   * **KPI Summary Cards:** Custom shape containers with dynamic cell-linked text elements.
   * **Risk Stratification Column Chart:** Risk tier visualization showing distribution across High, Medium, Low, and Unscorable tiers.
   * **DTI by Industry Bar Chart:** Average Debt-to-Income ratios across key sectors (Healthcare, Tech, Retail, Hospitality, Energy).
   * **Monthly Origination Trend Lines:** Multi-line chart tracking portfolio growth across Auto Loans, Credit Cards, Mortgages, and Personal Loans (2024–2025).
   * 
