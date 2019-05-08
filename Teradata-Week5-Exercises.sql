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
            HAVING NumSaleDates > 20
           ) AS CleanedData
      ON MSAStore=TStore
GROUP BY MSAStore, Income, city, state;
-- Store | Income | State | City         | AvgDailyRev
-- 3902  | 56099  | AL    | Spanish Fort | 17884.08
-- 2707  | 16022  | TX    | McAllen      | 56601.99


-- Ex7
-- What is the brand of the sku with the greatest standard deviation in sprice?
-- Only examine skus that have been part of over 100 transactions.
SELECT s.brand AS Brand, t.sku AS sku, COUNT(t.sku) AS NumTransact, STDDEV_SAMP(t.sprice) AS StdDevSPrice
FROM trnsact t JOIN skuinfo s ON t.sku=s.sku
WHERE t.stype='P'
GROUP BY s.brand, t.sku
HAVING NumTransact > 100
ORDER BY StdDevSPrice DESC
-- Brand    | SKU     | NumTransact | Stddev
-- HART SCH | 2762683 | 106         | 175.8


-- Ex8
-- Examine all the transactions for the sku with the greatest standard deviation in sprice,
-- but only consider skus that are part of more than 100 transactions.
SELECT t.sku, COUNT(t.sku) AS NumTransact, STDDEV_SAMP(t.sprice) AS StdDevSPrice
FROM trnsact t
WHERE t.stype='P'
GROUP BY t.sku
HAVING NumTransact > 100
ORDER BY StdDevSPrice DESC
-- SKU = 2762683
SELECT *
FROM trnsact t
WHERE sku = 2762683
ORDER BY sprice DESC;


-- Ex9
-- What was the average daily revenue Dillard’s brought in during each month of the year?
SELECT year_num, month_num, SUM(Revenue)/AVG(NumSaleDates) AS AvgDailyRev
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
GROUP BY year_num, month_num
ORDER BY AvgDailyRev DESC
-- Best: 2004/12 11.3M, 2005/2 7.37M 
-- Worst: 2004/08 5.63M, 2004/09 5.69M


-- Ex10
-- Which department, in which city and state of what store, had the greatest % increase in
-- average daily sales revenue from November to December? 
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=11 THEN t.amt END) AS SaleNov,
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=12 THEN t.amt END) AS SaleDec,
       COUNT(DISTINCT (CASE WHEN EXTRACT(MONTH FROM t.saledate)=11 THEN t.saledate END)) AS NumDatesNov,
       COUNT(DISTINCT (CASE WHEN EXTRACT(MONTH FROM t.saledate)=12 THEN t.saledate END)) AS NumDatesDec,
       SaleNov/NumDatesNov AS AvgDailyRevNov,
       SaleDec/NumDatesDec AS AvgDailyRevDec,
       (AvgDailyRevDec-AvgDailyRevNov)/AvgDailyRevNov *100 AS PercentIncrease,
       (CASE
           WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
           ELSE 0
           END) AS Exclude
FROM trnsact t JOIN strinfo ON t.store=strinfo.store
               JOIN skuinfo ON t.sku=skuinfo.sku
               JOIN deptinfo ON deptinfo.dept=skuinfo.dept
WHERE t.stype='P' AND Exclude=0
                  AND t.store||EXTRACT(YEAR FROM t.saledate)||EXTRACT(MONTH from t.saledate)
                  IN  (SELECT store || EXTRACT(YEAR FROM saledate)|| EXTRACT(MONTH from saledate)
                       FROM trnsact
                       GROUP BY store, EXTRACT(YEAR FROM saledate), EXTRACT(MONTH from saledate) 
                       HAVING COUNT(DISTINCT saledate) > 20
                      )
GROUP BY Department, strinfo.city, strinfo.state, t.store, Exclude
HAVING SaleNov > 1000 AND SaleDec > 1000
ORDER BY PercentIncrease DESC
-- LOUISVL SALINA KS

-- Ex11
-- What is the city and state of the store that had the greatest decrease in average daily revenue from August to September?
SELECT strinfo.city, strinfo.state, TStore, DailyRevDecrease
FROM (SELECT TStore,
             SUM(CASE WHEN month_num=8 THEN Revenue END) AS SaleAug,
             SUM(CASE WHEN month_num=9 THEN Revenue END) AS SaleSep,
             SUM(CASE WHEN month_num=8 THEN NumSaleDates END) AS NumDatesAug,
             SUM(CASE WHEN month_num=9 THEN NumSaleDates END) AS NumDatesSep,
             SaleAug/NumDatesAug AS AvgDailyRevAug,
             SaleSep/NumDatesSep AS AvgDailyRevSep,
             AvgDailyRevAug-AvgDailyRevSep AS DailyRevDecrease 
      FROM  (SELECT EXTRACT(YEAR FROM t.saledate) AS year_num,
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
             HAVING NumSaleDates > 20
            ) AS CleanedData
      GROUP BY TStore
     ) AS SaleSummary JOIN strinfo ON strinfo.store=TStore
ORDER BY DailyRevDecrease DESC
-- City            | State | Store | Decrease 
-- WEST DES MOINES | IA    | 4003  | 6479.60
SELECT strinfo.city, strinfo.state, t.store,
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=8 THEN t.amt END) AS SaleAug,
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=9 THEN t.amt END) AS SaleSep,
       COUNT(DISTINCT (CASE WHEN EXTRACT(MONTH FROM t.saledate)=8 THEN t.saledate END)) AS NumDatesAug,
       COUNT(DISTINCT (CASE WHEN EXTRACT(MONTH FROM t.saledate)=9 THEN t.saledate END)) AS NumDatesSep,
       SaleAug/NumDatesAug AS AvgDailyRevAug,
       SaleSep/NumDatesSep AS AvgDailyRevSep,
       AvgDailyRevAug-AvgDailyRevSep AS Dip,
       (CASE
           WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
           ELSE 0
           END) AS Exclude
FROM trnsact t JOIN strinfo ON t.store=strinfo.store
WHERE t.stype='P' AND Exclude=0
                  AND t.store||EXTRACT(YEAR FROM t.saledate)||EXTRACT(MONTH from t.saledate)
                  IN  (SELECT store || EXTRACT(YEAR FROM saledate)|| EXTRACT(MONTH from saledate)
                       FROM trnsact
                       GROUP BY store, EXTRACT(YEAR FROM saledate), EXTRACT(MONTH from saledate)
                       HAVING COUNT(DISTINCT saledate) > 20
                      )
GROUP BY strinfo.city, strinfo.state, t.store, Exclude
ORDER BY Dip DESC
-- City            | State | Store | Decrease 
-- WEST DES MOINES | IA    | 4003  | 6479.60


-- Ex12
-- Determine the month of maximum total revenue for each store.
SELECT t.store AS TStore,
       EXTRACT(YEAR FROM t.saledate) AS year_num,
       EXTRACT(MONTH FROM t.saledate) AS month_num,
       COUNT(DISTINCT t.saledate) AS NumDates,
       SUM(t.amt) AS Revenue,
       ROW_NUMBER () over (PARTITION BY store ORDER BY Revenue DESC) AS month_rank,
       (CASE
            WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
            ELSE 0
            END) AS Exclude
FROM trnsact t
WHERE t.stype='P' AND Exclude=0
                  AND t.store||EXTRACT(YEAR FROM t.saledate)||EXTRACT(MONTH from t.saledate)
                        IN  (SELECT store || EXTRACT(YEAR FROM saledate)|| EXTRACT(MONTH from saledate)
                             FROM trnsact
                             GROUP BY store, EXTRACT(YEAR FROM saledate), EXTRACT(MONTH from saledate)
                             HAVING COUNT(DISTINCT saledate) > 20
                            )
GROUP BY t.store, year_num, month_num, Exclude
HAVING NumDates > 20 QUALIFY month_rank=1
ORDER BY month_num ASC
-- Count the number of stores whose month of maximum total revenue was in each of the twelve months.
SELECT month_num, COUNT(TStore) AS NumStores
FROM (SELECT t.store AS TStore,
             EXTRACT(YEAR FROM t.saledate) AS year_num,
             EXTRACT(MONTH FROM t.saledate) AS month_num,
             COUNT(DISTINCT t.saledate) AS NumDates,
             SUM(t.amt) AS Revenue,
             ROW_NUMBER () over (PARTITION BY store ORDER BY Revenue DESC) AS month_rank,
             (CASE
                 WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
                 ELSE 0
                 END) AS Exclude
      FROM trnsact t
      WHERE t.stype='P' AND Exclude=0
                        AND t.store||EXTRACT(YEAR FROM t.saledate)||EXTRACT(MONTH from t.saledate)
                        IN  (SELECT store || EXTRACT(YEAR FROM saledate)|| EXTRACT(MONTH from saledate)
                             FROM trnsact
                             GROUP BY store, EXTRACT(YEAR FROM saledate), EXTRACT(MONTH from saledate)
                             HAVING COUNT(DISTINCT saledate) > 20
                            )
      GROUP BY t.store, year_num, month_num, Exclude
      HAVING NumDates > 20 QUALIFY month_rank=1
     ) AS MonthSales
GROUP BY month_num
ORDER BY NumStores DESC;
-- December with 321 stores
-- Then determine the month of maximum average daily revenue.
-- Count the number of stores whose month of maximum average daily revenue was in each of the twelve months.
SELECT month_num, COUNT(TStore) AS NumStores
FROM (SELECT t.store AS TStore,
             EXTRACT(YEAR FROM t.saledate) AS year_num,
             EXTRACT(MONTH FROM t.saledate) AS month_num,
             COUNT(DISTINCT t.saledate) AS NumDates,
             SUM(t.amt) AS Revenue,
             Revenue/NumDates AS AvgDailyRev,
             ROW_NUMBER () over (PARTITION BY store ORDER BY AvgDailyRev DESC) AS month_rank,
             (CASE
                 WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
                 ELSE 0
                 END) AS Exclude
      FROM trnsact t
      WHERE t.stype='P' AND Exclude=0
                        AND t.store||EXTRACT(YEAR FROM t.saledate)||EXTRACT(MONTH from t.saledate)
                        IN  (SELECT store || EXTRACT(YEAR FROM saledate)|| EXTRACT(MONTH from saledate)
                             FROM trnsact
                             GROUP BY store, EXTRACT(YEAR FROM saledate), EXTRACT(MONTH from saledate)
                             HAVING COUNT(DISTINCT saledate) > 20
                            )
      GROUP BY t.store, year_num, month_num, Exclude
      HAVING NumDates > 20 QUALIFY month_rank=1
     ) AS MonthSales
GROUP BY month_num
ORDER BY NumStores DESC;
-- December with 317 stores
