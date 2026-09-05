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







