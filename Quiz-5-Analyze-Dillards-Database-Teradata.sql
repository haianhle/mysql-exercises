-- Question 2
-- How many distinct skus have the brand “Polo fas”, and are either size “XXL” or “black” in color?
SELECT COUNT(DISTINCT sku)
FROM skuinfo
WHERE (brand='Polo fas') AND (color='black' OR size='XXL');
-- 13623


-- Question 3
-- Where was one store in the database which had only 11 days in one of its months
-- (in other words, that store/month/year combination only contained 11 days of transaction data).
-- In what city and state was this store located?
SELECT strinfo.store, strinfo.city, strinfo.state, NumSaleDates
FROM strinfo JOIN (
                   SELECT EXTRACT(YEAR FROM saledate) AS year_num,
                   EXTRACT(MONTH from saledate) AS month_num,
                   store,
                   COUNT(DISTINCT saledate) AS NumSaleDates
                   FROM trnsact
                   GROUP BY year_num, month_num, store
                  ) AS StoreSales ON strinfo.store=StoreSales.store
WHERE NumSaleDates=11;
-- 6402  | Atlanta | GA


-- Question 4
-- Which sku number had the greatest increase in total sales revenue from November to December?
SELECT TOP 1 sku,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate)=11 AND stype='P' THEN amt END) AS SalesNov,
             SUM(CASE WHEN EXTRACT(MONTH FROM saledate)=12 AND stype='P' THEN amt END) AS SalesDec,
             SalesDec-SalesNov AS SalesIncrease
FROM trnsact
GROUP BY sku
ORDER BY SalesIncrease DESC;
-- 3949538 from 121176.70 (Nov) to 936256.91 (Dec) = 815080.21 increase


-- Question 5
-- What vendor has the greatest number of distinct skus in the transaction table that do not exist
-- in the skstinfo table? (Remember that vendors are listed as distinct numbers in our data set).
SELECT skuinfo.vendor, COUNT(DISTINCT TSku) AS NumSkus
FROM (SELECT DISTINCT t.sku AS TSku
      FROM trnsact t LEFT JOIN skstinfo s ON t.sku=s.sku
      WHERE s.sku IS NULL) AS SkuTable JOIN skuinfo ON skuinfo.sku=TSku
GROUP BY skuinfo.vendor
ORDER BY NumSkus DESC
-- Vendor 5715232 with 16024 skus


-- Question 6
-- What is the brand of the sku with the greatest standard deviation in sprice?
-- Only examine skus which have been part of over 100 transactions.
SELECT s.brand AS Brand, t.sku AS sku, COUNT(t.sku) AS NumTransact, STDDEV_SAMP(t.sprice) AS StdDevSPrice
FROM trnsact t JOIN skuinfo s ON t.sku=s.sku
WHERE t.stype='P'
GROUP BY s.brand, t.sku
HAVING NumTransact > 100
ORDER BY StdDevSPrice DESC
-- Brand    | SKU     | NumTransact | Stddev
-- HART SCH | 2762683 | 106         | 175.8

-- Question 7
-- What is the city and state of the store which had the greatest increase in average daily revenue
-- from November to December?
SELECT strinfo.city, strinfo.state, TStore, DailyRevIncrease
FROM (SELECT TStore,
             SUM(CASE WHEN month_num=11 THEN Revenue END) AS SaleNov,
             SUM(CASE WHEN month_num=12 THEN Revenue END) AS SaleDec,
             SUM(CASE WHEN month_num=11 THEN NumSaleDates END) AS NumDatesNov,
             SUM(CASE WHEN month_num=12 THEN NumSaleDates END) AS NumDatesDec,
             SaleNov/NumDatesNov AS AvgDailyRevNov,
             SaleDec/NumDatesDec AS AvgDailyRevDec,
             AvgDailyRevDec-AvgDailyRevNov AS DailyRevIncrease
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
ORDER BY DailyRevIncrease DESC
-- METAIRIE LA 8402 by $41423.30


-- Question 8
-- Compare the average daily revenue of the store with the highest msa_income and the store with the lowest
-- median msa_income (according to the msa_income field).
-- In what city and state were these two stores, and which store had a higher average daily revenue?
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


-- Question 9
-- Divide the msa_income groups up so that msa_incomes between 1 and 20,000 are labeled 'low',
-- msa_incomes between 20,001 and 30,000 are labeled 'med-low', msa_incomes between 30,001 and 40,000 are labeled 'med-high',
-- and msa_incomes between 40,001 and 60,000 are labeled 'high'.
-- Which of these groups has the highest average daily revenue (as defined in Teradata Week 5 Exercise Guide) per store?
SELECT IncomeRange, SUM(Revenue)/SUM(NumSaleDates) AS AvgDailyRev
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
  JOIN
     (SELECT (CASE
                WHEN msa_income <= 20000 THEN 'Low'
                WHEN msa_income > 20000 AND msa_income <= 30000 THEN 'Medium-Low'
                WHEN msa_income > 30000 AND msa_income <= 40000 THEN 'Medium-High'
                WHEN msa_income > 40000 AND msa_income < 60000 THEN 'High'
                END) AS IncomeRange,
             store_msa.store AS SStore
      FROM store_msa) AS CleanedStores ON SStore=TStore
GROUP BY IncomeRange
ORDER BY AvgDailyRev DESC
-- Income   | AvgDailyRev
-- Low      |  34159.76
-- Med-High |  21999.69
-- Med-Low  |  19312.10
-- High     |  18129.42


-- Question 10
-- Divide stores up so that stores with msa populations between 1 and 100,000 are labeled 'very small',
-- stores with msa populations between 100,001 and 200,000 are labeled 'small',
-- stores with msa populations between 200,001 and 500,000 are labeled 'med_small',
-- stores with msa populations between 500,001 and 1,000,000 are labeled 'med_large',
-- stores with msa populations between 1,000,001 and 5,000,000 are labeled “large”,
-- and stores with msa_population greater than 5,000,000 are labeled “very large”.
-- What is the average daily revenue for a store in a “very large” population msa?
SELECT PopRange, SUM(Revenue)/SUM(NumSaleDates) AS AvgDailyRev
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
  JOIN
     (SELECT (CASE
                WHEN msa_pop <= 100000 THEN 'very_small'
                WHEN msa_pop > 100000 AND msa_pop <= 200000 THEN 'small'
                WHEN msa_pop > 200000 AND msa_pop <= 500000 THEN 'med_small'
                WHEN msa_pop > 500000 AND msa_pop <= 1000000 THEN 'med_large'
                WHEN msa_pop > 1000000 AND msa_pop <= 5000000 THEN 'large'
                WHEN msa_pop > 5000000 THEN 'very_large'
                END) AS PopRange,
             store_msa.store AS SStore
      FROM store_msa) AS CleanedStores ON SStore=TStore
GROUP BY PopRange
ORDER BY AvgDailyRev DESC
-- very_large | 25451.53
-- med_large  | 24341.59
-- large      | 22107.57
-- med_small  | 21208.43
-- small      | 16355.16
-- very_small | 12688.25 


-- Question 11
-- Which department in which store had the greatest percent increase in average daily sales revenue from November to December,
-- and what city and state was that store located in? Only examine departments whose total sales were
-- at least $1,000 in both November and December.
SELECT deptinfo.deptdesc AS Department, strinfo.city, strinfo.state, t.store,
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


-- Question 12
-- Which department within a particular store had the greatest decrease in average daily sales revenue from August to September,
-- and in what city and state was that store located?
SELECT deptinfo.deptdesc AS Department, strinfo.city, strinfo.state, t.store,
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
ORDER BY Dip DESC
-- CLINIQUE LOUISVILLE KY 9103


-- Question 13
-- Identify which department, in which city and state of what store, had the greatest DECREASE in the number of items
-- sold from August to September. How many fewer items did that department sell in September compared to August?
SELECT deptinfo.deptdesc AS Department, strinfo.city, strinfo.state, t.store,
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=8 THEN t.quantity END) AS SaleAug,
       SUM(CASE WHEN EXTRACT(MONTH FROM t.saledate)=9 THEN t.quantity END) AS SaleSep,
       SaleAug-SaleSep AS Dip,
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
ORDER BY Dip DESC
-- CLINIQUE LOUISVILLE KY 9103 from 17644 to 4153 so 13491 fewer items sold


-- Question 14
-- For each store, determine the month with the minimum average daily revenue.
-- For each of the twelve months of the year, count how many stores' minimum average daily revenue was in that month.
-- During which month(s) did over 100 stores have their minimum average daily revenue?
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
      HAVING NumDates > 20 QUALIFY month_rank=12 --lowest rank on the AvgDailyRev for each store
     ) AS MonthSales
GROUP BY month_num
ORDER BY NumStores DESC;
-- August with most stores 120

-- Question 15
-- Write a query that determines the month in which each store had its maximum number of sku units returned.
-- During which month did the greatest number of stores have their maximum number of sku units returned?
SELECT month_num, COUNT(TStore) AS NumStores
FROM (SELECT t.store AS TStore,
             EXTRACT(YEAR FROM t.saledate) AS year_num,
             EXTRACT(MONTH FROM t.saledate) AS month_num,
             COUNT(DISTINCT t.saledate) AS NumDates,
             SUM(t.quantity) AS TotalReturned,
             ROW_NUMBER () over (PARTITION BY store ORDER BY TotalReturned DESC) AS month_rank,
             (CASE
                 WHEN EXTRACT(YEAR FROM t.saledate)=2005 AND EXTRACT(MONTH FROM t.saledate)=8 THEN 1
                 ELSE 0
                 END) AS Exclude
      FROM trnsact t
      WHERE t.stype='R' AND Exclude=0
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
-- December with 296 stores with maximum number items returned
-- Writing  COUNT(t.sku) AS TotalReturned, Instead of SUM(t.quantity) AS TotalReturned gives the same result

