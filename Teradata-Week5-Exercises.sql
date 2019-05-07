-- Ex1
-- How many distinct dates are there in the saledate column of the transaction table for each month/year combination in the database?
SELECT EXTRACT(YEAR FROM saledate) AS year_num,
       EXTRACT(MONTH FROM saledate) AS month_num,
       COUNT(DISTINCT saledate)
FROM trnsact
GROUP BY year_num, month_num
ORDER BY year_num ASC, month_num ASC;
-- 13 rows


-- Ex2
-- Use a CASE statement within an aggregate function to determine which sku had the greatest total sales
-- during the combined summer months of June, July, and August.
SELECT TOP 5 sku, 
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate)=6 AND stype='P' THEN amt END) AS SalesJun,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate)=7 AND stype='P' THEN amt END) AS SalesJul,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate)=8 AND stype='P' THEN amt END) AS SalesAug,
             SalesJun+ SalesJul+ SalesAug AS SalesSummer
FROM trnsact
GROUP BY sku
ORDER BY SalesSummer DESC;
-- #1 is SKU=4108011 with SalesSummer=1,646,017.38

-- Ex3
-- How many distinct dates are there in the saledate column of the transaction table for each month/year/store
-- combination in the database? Sort your results by the number of days per combination in ascending order.
SELECT EXTRACT(YEAR FROM saledate) AS year_num,
       EXTRACT(MONTH from saledate) AS month_num,
       store,
       COUNT(DISTINCT saledate) AS NumSaleDates
FROM trnsact
GROUP BY year_num, month_num, store
ORDER BY NumSaleDates ASC;
-- 5 year/month/store combinations with only 1 saledate


-- Ex4
-- What is the average daily revenue for each store/month/year combination in the database?
-- Calculate this by dividing the total revenue for a group by the number of sales days available in the transaction table for that group.
SELECT EXTRACT(YEAR FROM saledate) AS year_num,
       EXTRACT(MONTH from saledate) AS month_num,
       store,
       COUNT(DISTINCT saledate) AS NumSaleDates,
       SUM(amt) AS Revenue,
       Revenue/NumSaleDates AS AvgDailyRev
FROM trnsact
WHERE stype='P'
GROUP BY year_num, month_num, store
ORDER BY AvgDailyRev DESC;
-- remove all data from August 2005 and exclude all year/month/store combo with fewer than 20 days of data
SELECT EXTRACT(YEAR FROM saledate) AS year_num,
       EXTRACT(MONTH from saledate) AS month_num,
       store,
       COUNT(DISTINCT saledate) AS NumSaleDates,
       SUM(amt) AS Revenue,
       Revenue/NumSaleDates AS AvgDailyRev,
       (CASE 
          WHEN year_num=2005 AND month_num=8 THEN 1
          ELSE 0
          END) AS Exclude
FROM trnsact
WHERE stype='P' AND Exclude=0
GROUP BY year_num, month_num, store
HAVING NumSaleDates > 20
ORDER BY AvgDailyRev DESC;
-- Rewrite the query:
SELECT year_num, month_num, TStore, NumSaleDates, Revenue/NumSaleDates AS AvgDailyRev
FROM (SELECT EXTRACT(YEAR FROM t.saledate) AS year_num,
             EXTRACT(MONTH from t.saledate) AS month_num,
             t.store AS TStore,
             COUNT(DISTINCT t.saledate) AS NumSaleDates,
             SUM(t.amt) AS Revenue,
             (CASE
              WHEN year_num=2005 AND month_num=8 THEN 1
              ELSE 0
              END) AS Exclude
      FROM trnsact t
      WHERE t.stype='P' AND Exclude=0
      GROUP BY year_num, month_num, TStore
      HAVING NumSaleDates > 20) AS CleanedData
ORDER BY AvgDailyRev DESC


-- Ex5
-- What is the average daily revenue brought in by Dillard’s stores in areas of high, medium, or low levels of high school education?

-- Suppose that the high school graduation rate is reflected by msa_high
SELECT MIN(msa_high), MAX(msa_high)
FROM store_msa;
-- Min = 50.5 and Max = 94.9
-- Create an Education group where Low = [50, 60], Medium = (60, 70], High = (70,)
SELECT (CASE
          WHEN msa_high >= 50 AND msa_high <= 60 THEN 'Low'
          WHEN msa_high > 60 AND msa_high <= 70 THEN 'Medium'
          WHEN msa_high > 70 THEN 'High'
          END) AS Education,
       msa_high
FROM store_msa;

-- Recall that the stores in store_msa are all distinct, 333 stores in total
SELECT COUNT(store), COUNT(DISTINCT store)
FROM store_msa;

-- Combine with Ex4, join store_msa and trnsact tables via store (1 store not in trnsact)
SELECT Education, SUM(Revenue)/SUM(NumSaleDates) AS AvgDailyRev
FROM (SELECT EXTRACT(YEAR FROM t.saledate) AS year_num,
             EXTRACT(MONTH from t.saledate) AS month_num,
             t.store AS TStore,
             COUNT(DISTINCT t.saledate) AS NumSaleDates,
             SUM(t.amt) AS Revenue,
             (CASE
              WHEN year_num=2005 AND month_num=8 THEN 1
              ELSE 0
              END) AS Exclude
      FROM trnsact t
      WHERE t.stype='P' AND Exclude=0
      GROUP BY year_num, month_num, t.store, Exclude
      HAVING NumSaleDates > 20) AS CleanedData
   JOIN
      (SELECT (CASE
          WHEN s.msa_high >= 50 AND s.msa_high <= 60 THEN 'Low'
          WHEN s.msa_high > 60 AND s.msa_high <= 70 THEN 'Medium'
          WHEN s.msa_high > 70 THEN 'High'
          END) AS Education,
         s.store AS SStore
       FROM store_msa s) AS CleanedMSA
   ON CleanedMSA.SStore=CleanedData.TStore
GROUP BY Education
ORDER BY AvgDailyRev DESC;
-- Education |  AvgDailyRev
-- Low       |    34159.76
-- Medium    |    25037.89
-- High      |    20937.31

-- Ex6
-- Compare the average daily revenues of the stores with the highest median msa_income and the lowest median msa_income.
-- In what city and state were these stores, and which store had a higher average daily revenue?

-- Highest and Lowest median income ($56099 and $16022)
SELECT MAX(msa_income), MIN(msa_income)
FROM store_msa;
-- Stores with highest and lowest median income
SELECT s.store, s.msa_income
FROM store_msa s
WHERE s.msa_income IN ((SELECT MAX(msa_income) FROM store_msa),
                       (SELECT MIN(msa_income) FROM store_msa))
-- Combine this with strinfo table to get the city and state of these stores
SELECT MSAStore, Income, city, state
FROM strinfo
   JOIN (SELECT s.store AS MSAStore, s.msa_income AS Income
         FROM store_msa s
         WHERE s.msa_income IN ((SELECT MAX(msa_income) FROM store_msa),
                                (SELECT MIN(msa_income) FROM store_msa))
        ) AS RepStores
   ON strinfo.store=MSAStore
-- Store | Income | State | City
-- 3902  | 56099  | AL    | Spanish Fort 
-- 2707  | 16022  | TX    | McAllen

-- Combine with Ex4 to get these city's daily profits
SELECT MSAStore, Income, city, state, SUM(Revenue)/Sum(NumSaleDates) AS AvgDailyRev
FROM (strinfo
         JOIN (SELECT s.store AS MSAStore, s.msa_income AS Income
               FROM store_msa s
               WHERE s.msa_income IN ((SELECT MAX(msa_income) FROM store_msa),
                                      (SELECT MIN(msa_income) FROM store_msa))
              ) AS RepStores
         ON strinfo.store=MSAStore)
      JOIN (SELECT EXTRACT(YEAR FROM t.saledate) AS year_num,
                   EXTRACT(MONTH from t.saledate) AS month_num,
                   t.store AS TStore,
                   COUNT(DISTINCT t.saledate) AS NumSaleDates,
                   SUM(t.amt) AS Revenue,
                   (CASE
                   WHEN year_num=2005 AND month_num=8 THEN 1
                   ELSE 0
                   END) AS Exclude
            FROM trnsact t
            WHERE t.stype='P' AND Exclude=0
            GROUP BY year_num, month_num, TStore
            HAVING NumSaleDates > 20) AS CleanedData
        ON MSAStore=TStore
GROUP BY MSAStore, Income, city, state;
-- Store | Income | State | City         | AvgDailyRev
-- 3902  | 56099  | AL    | Spanish Fort | 17884.08
-- 2707  | 16022  | TX    | McAllen      | 56601.99




-- Ex7
-- What is the brand of the sku with the greatest standard deviation in sprice?
-- Only examine skus that have been part of over 100 transactions.


-- Ex8
-- Examine all the transactions for the sku with the greatest standard deviation in sprice,
-- but only consider skus that are part of more than 100 transactions.


-- Ex9
-- What was the average daily revenue Dillard’s brought in during each month of the year?


-- Ex10
-- Which department, in which city and state of what store, had the greatest % increase in
-- average daily sales revenue from November to December? 


-- Ex11
-- What is the city and state of the store that had the greatest decrease in average daily revenue from August to September?


-- Ex12
-- Determine the month of maximum total revenue for each store.
-- Count the number of stores whose month of maximum total revenue was in each of the twelve months.
-- Then determine the month of maximum average daily revenue.
-- Count the number of stores whose month of maximum average daily revenue was in each of the twelve months.
