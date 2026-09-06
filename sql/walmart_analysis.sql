CREATE DATABASE walmart_analysis;
USE walmart_analysis;
CREATE TABLE walmart_sales (
    Store INT,
    Date DATE,
    Weekly_Sales DECIMAL(15,2),
    Holiday_Flag INT,
    Temperature DECIMAL(10,2),
    Fuel_Price DECIMAL(10,3),
    CPI DECIMAL(10,3),
    Unemployment DECIMAL(10,3),
    Year INT,
    Quarter INT,
    Month INT,
    Month_Name VARCHAR(20),
    Week INT
);
DESCRIBE walmart_sales;
SELECT * FROM walmart_sales LIMIT 10;
SELECT COUNT(*) AS total_records
FROM walmart_sales;
# BASIC DATA VALIDATION
SELECT COUNT(*) AS total_records,
COUNT(distinct Store) AS total_stores,
MIN(Date) AS earliest_date,
MAX(Date) AS latest_date
FROM walmart_sales;

# Which stores have the highest sales?
SELECT Store,SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY Store
ORDER BY Average_Weekly_Sales DESC;

# Top 10 stores which have the highest sales
SELECT Store,SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY Store
ORDER BY Average_Weekly_Sales DESC
LIMIT 10;

# Which stores have the lowest sales?
SELECT Store,SUM(Weekly_Sales) AS Total_Sales,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY Store
ORDER BY Average_Weekly_Sales ASC
LIMIT 10;

# Which are the monthly sales trends?
SELECT MONTH(date) AS Month,
MONTHNAME(Date) AS Month_Name,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY
MONTH(Date),
MONTHNAME(Date)
ORDER BY Month;

# Which months have the highest sales?
SELECT MONTH(Date) AS Month,
MONTHNAME(Date) AS Month_Name,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY
MONTH(Date),
MONTHNAME(Date)
ORDER BY Average_Weekly_Sales DESC;

# Top 3 months which have the highest sales?
SELECT MONTH(Date) AS Month,
MONTHNAME(Date) AS Month_Name,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY
MONTH(Date),
MONTHNAME(Date)
ORDER BY Average_Weekly_Sales DESC
LIMIT 3;

#Holiday vs Non-Holiday Sales
SELECT 
CASE
WHEN Holiday_Flag = 1 THEN 'Holiday'
	ELSE 'Non-Holiday'
END AS Period_Type,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY Holiday_Flag;

# Calculate Holiday Uplift
WITH holiday_sales AS (
    SELECT
        AVG(CASE
            WHEN Holiday_Flag = 1
            THEN Weekly_Sales
        END) AS Holiday_Avg,
        AVG(CASE
            WHEN Holiday_Flag = 0
            THEN Weekly_Sales
        END) AS Non_Holiday_Avg
    FROM walmart_sales
)
SELECT Holiday_Avg,Non_Holiday_Avg,
((Holiday_Avg - Non_Holiday_Avg)/Non_Holiday_Avg)*100 AS Holiday_Uplift_Percentage
FROM holiday_sales;

# Which stores benefit most from holidays?
WITH store_holiday AS (
    SELECT
        Store,
        AVG(
            CASE
                WHEN Holiday_Flag = 1
                THEN Weekly_Sales
            END
        ) AS Holiday_Avg,
        AVG(
            CASE
                WHEN Holiday_Flag = 0
                THEN Weekly_Sales
            END
        ) AS Non_Holiday_Avg
    FROM walmart_sales
    GROUP BY Store
)
SELECT Store,Holiday_Avg,Non_Holiday_Avg,
((Holiday_Avg - Non_Holiday_Avg)/Non_Holiday_Avg) * 100 AS Holiday_Uplift_Percentage
FROM store_holiday
ORDER BY Holiday_Uplift_Percentage DESC;

# top 10 stores which benefit from holidays
WITH store_holiday AS (
    SELECT Store,
        AVG(
            CASE
                WHEN Holiday_Flag = 1
                THEN Weekly_Sales
            END
        ) AS Holiday_Avg,
        AVG(
            CASE
                WHEN Holiday_Flag = 0
                THEN Weekly_Sales
            END
        ) AS Non_Holiday_Avg
    FROM walmart_sales
    GROUP BY Store
)
SELECT Store,Holiday_Avg,Non_Holiday_Avg,
((Holiday_Avg - Non_Holiday_Avg)/Non_Holiday_Avg) * 100 AS Holiday_Uplift_Percentage
FROM store_holiday
ORDER BY Holiday_Uplift_Percentage DESC LIMIT 10;

# What percentage of total sales does each store contribute?
WITH store_sales AS (
    SELECT Store,SUM(Weekly_Sales) AS Total_Sales
    FROM walmart_sales
    GROUP BY Store
)
SELECT Store,Total_Sales,
(Total_Sales/(SELECT SUM(Total_Sales)FROM store_sales))*100 AS Sales_Contribution_Percentage
FROM store_sales
ORDER BY Sales_Contribution_Percentage DESC;

# Which weeks had the highest sales?
SELECT Store,Date,Weekly_Sales,Holiday_Flag
FROM walmart_sales
ORDER BY Weekly_Sales DESC
LIMIT 10;

# Year-over-Year Sales Performance
-- First Calculate yearly avg weekly sales
WITH yearly_sales AS (
    SELECT YEAR(Date) AS Year,
	AVG(Weekly_Sales) AS Average_Weekly_Sales
    FROM walmart_sales
    GROUP BY YEAR(Date)
)
SELECT *
FROM yearly_sales
ORDER BY Year;
-- Use LAG()
WITH yearly_sales AS (
    SELECT YEAR(Date) AS Year,AVG(Weekly_Sales) AS Average_Weekly_Sales
    FROM walmart_sales
    GROUP BY YEAR(Date)
)
SELECT Year,Average_Weekly_Sales,
LAG(Average_Weekly_Sales)
OVER (ORDER BY Year) AS Previous_Year_Sales
FROM yearly_sales
ORDER BY Year;

# Calculate YoY%
WITH yearly_sales AS (
    SELECT YEAR(Date) AS Year,
	AVG(Weekly_Sales) AS Average_Weekly_Sales
    FROM walmart_sales
    GROUP BY YEAR(Date)
),
yearly_comparison AS (
    SELECT Year,Average_Weekly_Sales,
	LAG(Average_Weekly_Sales)
	OVER (ORDER BY Year) AS Previous_Year_Sales
    FROM yearly_sales
)
SELECT Year,Average_Weekly_Sales,Previous_Year_Sales,
((Average_Weekly_Sales-Previous_Year_Sales)/Previous_Year_Sales)*100 AS YoY_Change_Percentage
FROM yearly_comparison
ORDER BY Year;

# Which stores have high sales but high volatility?
SELECT Store,AVG(Weekly_Sales) AS Average_Weekly_Sales,
STDDEV_SAMP(Weekly_Sales) AS Sales_Std
FROM walmart_sales
GROUP BY Store
ORDER BY Sales_Std DESC;
-- CV = Standard Deviation / Average
WITH store_stats AS (
    SELECT Store,AVG(Weekly_Sales) AS Average_Weekly_Sales,
	STDDEV_SAMP(Weekly_Sales) AS Sales_Std
    FROM walmart_sales
    GROUP BY Store
)
SELECT Store,Average_Weekly_Sales,Sales_Std,Sales_Std/Average_Weekly_Sales AS CV
FROM store_stats
ORDER BY CV DESC;

# High Sales + High Volatility
WITH store_stats AS (
    SELECT Store,AVG(Weekly_Sales) AS Average_Weekly_Sales,
	STDDEV_SAMP(Weekly_Sales) AS Sales_Std
    FROM walmart_sales
    GROUP BY Store
),
store_cv AS (
    SELECT Store,Average_Weekly_Sales,Sales_Std,
	Sales_Std/Average_Weekly_Sales AS CV
    FROM store_stats
),
thresholds AS (
    SELECT AVG(Average_Weekly_Sales) AS Avg_Sales_Threshold,
	AVG(CV) AS Avg_CV_Threshold
    FROM store_cv
)
SELECT s.Store,s.Average_Weekly_Sales,s.Sales_Std,s.CV
FROM store_cv s
CROSS JOIN thresholds t
WHERE s.Average_Weekly_Sales>t.Avg_Sales_Threshold AND s.CV>t.Avg_CV_Threshold
ORDER BY s.CV DESC;

# Rank Stores
WITH store_sales AS (
    SELECT Store,AVG(Weekly_Sales) AS Average_Weekly_Sales
    FROM walmart_sales
    GROUP BY Store
)
SELECT Store,Average_Weekly_Sales,
RANK() OVER (
	ORDER BY Average_Weekly_Sales DESC
) AS Sales_Rank
FROM store_sales
ORDER BY Sales_Rank;

# Identify Store Performance Categories
WITH store_stats AS (
    SELECT Store,AVG(Weekly_Sales) AS Average_Weekly_Sales,
	STDDEV_SAMP(Weekly_Sales) AS Sales_Std
    FROM walmart_sales
    GROUP BY Store
),
store_metrics AS (
    SELECT Store,Average_Weekly_Sales,Sales_Std,Sales_Std / Average_Weekly_Sales AS CV
    FROM store_stats
)
SELECT Store,Average_Weekly_Sales,Sales_Std,CV,
    CASE
        WHEN Average_Weekly_Sales >=
             (SELECT AVG(Average_Weekly_Sales)
              FROM store_metrics)
         AND CV <=
             (SELECT AVG(CV)
              FROM store_metrics)
        THEN 'High Performance - Stable'
        WHEN Average_Weekly_Sales >=
             (SELECT AVG(Average_Weekly_Sales)
              FROM store_metrics)
         AND CV >
             (SELECT AVG(CV)
              FROM store_metrics)
        THEN 'High Performance - Volatile'
        WHEN Average_Weekly_Sales <
             (SELECT AVG(Average_Weekly_Sales)
              FROM store_metrics)
         AND CV <=
             (SELECT AVG(CV)
              FROM store_metrics)
        THEN 'Lower Performance - Stable'
        ELSE 'Lower Performance - Volatile'
    END AS Store_Category
FROM store_metrics
ORDER BY Average_Weekly_Sales DESC;

# Store+Month Analysis
SELECT Store,MONTH(Date) AS Month,MONTHNAME(Date) AS Month_Name,
AVG(Weekly_Sales) AS Average_Weekly_Sales
FROM walmart_sales
GROUP BY Store,MONTH(Date),MONTHNAME(Date)
ORDER BY Store,Month;

# Overall dataset summary
SELECT
COUNT(DISTINCT Store) AS Total_Stores,
COUNT(*) AS Total_Records,
ROUND(SUM(Weekly_Sales), 2) AS Total_Sales,
ROUND(AVG(Weekly_Sales), 2) AS Overall_Average_Weekly_Sales,
ROUND(MIN(Weekly_Sales), 2) AS Minimum_Weekly_Sales,
ROUND(MAX(Weekly_Sales), 2) AS Maximum_Weekly_Sales
FROM walmart_sales;



























