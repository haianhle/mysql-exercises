-- Question 3
-- On what day was Dillard’s income based on total sum of purchases the greatest
SELECT t.saledate, SUM(t.amt) AS TotalPurchaseAmt
FROM trnsact t
WHERE t.stype='P'
GROUP BY t.saledate
ORDER BY TotalPurchaseAmt DESC;
-- 04/12/18 $19,813,655.17 

-- Question 4
-- What is the deptdesc of the departments that have the top 3 greatest numbers of skus from the skuinfo table associated with them?
SELECT d.dept, d.deptdesc, COUNT(s.sku) AS NumSKUs
FROM deptinfo d JOIN skuinfo s ON d.dept=s.dept
GROUP BY d.dept, d.deptdesc
ORDER BY NumSKUs DESC;
-- (dept, deptdesc, NumSKUs) = (6006, INVEST,150815), (4505,POLOMEN,142108), (7106,BRIOSO,131106)

-- Question 5
-- Which table contains the most distinct sku numbers?
SELECT COUNT(DISTINCT sku)
FROM skstinfo;
-- 760,212
SELECT COUNT(DISTINCT sku)
FROM skuinfo;
-- 1,564,178
SELECT COUNT(DISTINCT sku)
FROM trnsact;
-- 714499

-- Question 6
-- How many skus are in the skstinfo table, but NOT in the skuinfo table?
SELECT skuinfo.sku, skstinfo.sku
FROM skuinfo RIGHT JOIN skstinfo ON skuinfo.sku=skstinfo.sku
WHERE skuinfo.sku IS NULL;
-- No data. All skus in skstinfo are in skuinfo.

-- Question 7
-- What is the average amount of profit Dillard’s made per day?
SELECT SUM(t.amt-s.cost*t.quantity)/COUNT(DISTINCT t.saledate) AS AvgDailyProfit
FROM trnsact t JOIN skstinfo s ON t.sku=s.sku AND t.store=s.store
WHERE t.stype='P'
ORDER BY AvgDailyProfit;
-- 1,527,903.46

-- Question 8
-- The store_msa table provides population statistics about the geographic location around a store.
-- Using one query to retrieve your answer, how many MSAs are there within the state of North Carolina
-- (abbreviated “NC”), and within these MSAs, what is the lowest population level (msa_pop)
-- and highest income level (msa_income)?
SELECT COUNT(store) AS NumStores, MIN(msa_pop) AS LowestPop, MAX(msa_income) AS HighestIncome
FROM store_msa
WHERE state='NC';
-- 16 339511 36151

-- Question 9
-- What department (with department description), brand, style, and color brought in the greatest total amount of sales?
SELECT d.dept, d.deptdesc, s.brand, s.style, s.color, SUM(t.amt) AS SalesAmt
FROM deptinfo d JOIN skuinfo s ON s.dept=d.dept JOIN trnsact t ON t.sku=s.sku
WHERE t.stype='P'
GROUP BY d.dept, d.deptdesc, s.brand, s.style, s.color
ORDER BY SalesAmt DESC;
-- 800 CLINIQUE CLINIQUE 6142 DDML 6350866.72

-- Question 10
-- How many stores have more than 180,000 distinct skus associated with them in the skstinfo table?
SELECT store, COUNT(DISTINCT sku) AS NumSKUs
FROM skstinfo
GROUP BY store
HAVING NumSKUs > 180000
ORDER BY NumSKUs DESC;
-- 12 rows

-- Question 11
-- Look at the data from all the distinct skus in the “cop” department with a “federal” brand and
-- a “rinse wash” color. You'll see that these skus have the same values in some of the columns,
-- meaning that they have some features in common.
-- In which columns do these skus have different values from one another, meaning that their features
-- differ in the categories represented by the columns?
SELECT *
FROM skuinfo s JOIN deptinfo d ON s.dept=d.dept
WHERE d.deptdesc='cop' AND s.brand='federal' AND s.color='rinse wash'
ORDER BY s.sku DESC
-- Vendor=0816344 PackSize=1 ARE SAME

-- Question 12
-- How many skus are in the skuinfo table, but NOT in the skstinfo table?
SELECT skuinfo.sku, skstinfo.sku
FROM skuinfo LEFT JOIN skstinfo ON skuinfo.sku=skstinfo.sku
WHERE skstinfo.sku IS NULL;
-- 803,966 rows

-- Question 13
-- In what city and state is the store that had the greatest total sum of sales?
SELECT s.state, s.city, s.zip, SUM(t.amt) AS TotalRevenue
FROM strinfo s JOIN trnsact t ON s.store=t.store
WHERE t.stype='P'
GROUP BY s.state, s.city, s.zip
ORDER BY TotalRevenue DESC;
-- LA Metairie
-- but note how the query below
SELECT s.state, s.city, SUM(t.amt) AS TotalRevenue
FROM strinfo s JOIN trnsact t ON s.store=t.store
WHERE t.stype='P'
GROUP BY s.state, s.city
ORDER BY TotalRevenue DESC;
-- gives TX Houston

-- Question 15
-- How many states have more than 10 Dillards stores in them?
SELECT state, COUNT(store) AS NumStores
FROM strinfo
GROUP BY state
HAVING NumStores > 10
ORDER BY NumStores DESC;
-- 15 rows (TX has 79 stores)


-- Question 16
-- What is the suggested retail price of all the skus in the “reebok” department with the
-- “skechers” brand and a “wht/saphire” color?
SELECT DISTINCT skuinfo.dept, d.deptdesc, skuinfo.brand, skuinfo.color, skstinfo.sku, skstinfo.retail
FROM deptinfo d JOIN skuinfo ON d.dept=skuinfo.dept JOIN skstinfo ON skstinfo.sku=skuinfo.sku
WHERE d.deptdesc='reebok' AND skuinfo.brand='skechers' AND skuinfo.color='wht/saphire'
ORDER BY skstinfo.sku DESC;
-- 29.00
