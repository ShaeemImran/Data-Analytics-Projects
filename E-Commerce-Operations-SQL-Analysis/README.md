# E-Commerce Operations Analytics (MySQL)

##  Executive Summary
This project delivers an end-to-end SQL data analytics pipeline built on raw e-commerce transaction records (`ecom_ops` database). The primary objective is to clean unstructured operational logs, correct transactional anomalies, and apply **5 Core Data Analytics Frameworks** to evaluate sales growth, customer retention, Pareto segmentation, and operational refund bottlenecks.

1. Clean and transform raw e-commerce transaction data
2. Identify transactional anomalies and data quality issues
3. Analyze sales growth and revenue trends
4. Segment customers based on spending
5. Evaluate customer retention and repeat purchases
6. Compare payment methods and identify refund bottlenecks
---

## 🛠️ Data Pipeline & Cleaning Strategy (`01_data_cleaning_and_staging.sql`)

1. Created a staging table to protect the raw dataset
2. Removed duplicate records using ROW_NUMBER()
3. Standardized text using TRIM(), UPPER(), LOWER(), and CONCAT()
4. Converted empty strings to NULL
5. Cast dates and financial columns to appropriate data types
6. Engineered:
7. Total_revenue = Quantity × Price_Per_Unit
8. Delivery_days = DATEDIFF()
9. Corrected negative financial values and refund-related anomalies using ABS()
---

## 📊 Core Analytical Frameworks & Findings (`02_exploratory_data_analysis_and_frameworks.sql`)

**1. Executive Overview & Critical Red Flag**
Gross Revenue: ~$3.69M across ~2,000 orders.
Operational Bottleneck: Over 16% of gross sales revenue is lost to product refunds.
*Key Driver:* The Crypto payment channel carries a 42.6% return/refund rate (227 refunded orders out of 533 total), primarily driven by Fraud Chargebacks and Damaged Item claims.

**2. Time-Series & Month-over-Month (MoM) Growth**
Applied window functions (LAG()) to calculate chronological month-over-month sales trends.
Identified revenue performance fluctuations, including a notable ~14% sales decline between February 2026 ($216.9K) and March 2026 ($186.6K).

**3. Cumulative Revenue Trajectory (Running Totals)**
Built daily and monthly cumulative sum metrics using SUM() OVER (ORDER BY orders_month).
Key Milestone: The store crossed its first $1,000,000 in cumulative gross sales in May 2025.

**4. Customer VIP Segmentation (Pareto Principle)**
Applied CASE statements over aggregated spending CTEs to tier customers into three operational cohorts:
VIP Customers: Total spend ≥ $15,000
Regular Customers: Total spend between $5,000 and $14,999
Low-Value Customers: Total spend < $5,000

**5. Cohort Analysis & Order Frequency (Retention)**
Evaluated customer repeat rates to measure loyalty:
Repeat Buyers: Account for multi-order customer segments and higher lifetime value.
One-Time Buyers: Highlight initial conversion performance. (new customers into actual buyers.)

**6. Operational Efficiency & Payment Share**
Analyzed payment methods by transaction volume, gross revenue, Average Order Value (AOV), and market share (SUM() OVER()):
Credit Card: Drives volume and market share (47.47% of total revenue, 976 orders).
PayPal: Drives cart value, achieving the highest AOV at $2,002.93 per order (26.65% revenue share).
  * **Crypto:** Represents a solid secondary volume channel (**25.88% revenue share**), but requires immediate risk management intervention due to excess refunds.
