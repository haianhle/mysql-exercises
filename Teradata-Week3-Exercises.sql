-- Ex1
-- Use COUNT and DISTINCT to determine how many distinct skus there are in pairs of the
-- skuinfo, skstinfo, and trnsact tables
SELECT COUNT(DISTINCT skstinfo.sku), COUNT(DISTINCT skuinfo.sku)
FROM skstinfo JOIN skuinfo
    ON skstinfo.sku= skuinfo.sku;
-- 760212

SELECT COUNT(DISTINCT skstinfo.sku), COUNT(DISTINCT trnsact.sku)
FROM skstinfo JOIN trnsact
    ON skstinfo.sku= trnsact.sku;
-- 542513

SELECT COUNT(DISTINCT skuinfo.sku), COUNT(DISTINCT trnsact.sku)
FROM skuinfo JOIN trnsact
    ON skuinfo.sku= trnsact.sku;
-- 714499

SELECT COUNT(DISTINCT skstinfo.sku)
FROM skstinfo;
-- 760212

SELECT COUNT(DISTINCT skuinfo.sku)
FROM skuinfo;
-- 1564178

SELECT COUNT(DISTINCT trnsact.sku)
FROM trnsact;
-- 714499

--  Use COUNT to determine how many instances there are of each sku associated with each store
-- in the skstinfo table and the trnsact table
SELECT store, COUNT(DISTINCT sku)
FROM trnsact
GROUP BY store;
-- 332 rows

SELECT store, COUNT(DISTINCT sku)
FROM skstinfo
GROUP BY store;
-- 357 rows

SELECT DISTINCT store, sku, COUNT(sku)
FROM skstinfo
GROUP BY store, sku;
-- 39230146 rows 1 instance each

SELECT DISTINCT store, sku, COUNT(sku)
FROM trnsact
GROUP BY store, sku;
-- 36099491 rows multiple instances each

-- Ex2
-- Use COUNT and DISTINCT to determine how many distinct stores there are in the
-- strinfo, store_msa, skstinfo, and trnsact tables.

SELECT COUNT(DISTINCT store)
FROM strinfo;
-- 453
SELECT COUNT(DISTINCT store)
FROM store_msa;
-- 333
SELECT COUNT(DISTINCT store)
FROM skstinfo;
-- 357
SELECT COUNT(DISTINCT store)
FROM trnsact;
-- 332

-- Note how the number of distinct stores are different
-- strinfo > skstinfo > store_msa < trnsact

--  Which stores are common to all four tables, or unique to specific tables?
--
-- Below: common stores between strinfo and skstinfo?
SELECT strinfo.store, skstinfo.store
FROM strinfo JOIN skstinfo ON strinfo.store= skstinfo.store
-- 357 rows
-- All stores in skstinfo are in strinfo and 96 stores in strinfo aren't in skstinfo

-- Below: any stores in strinfo and not in skstinfo?
SELECT strinfo.store, skstinfo.store
FROM strinfo LEFT JOIN skstinfo ON strinfo.store= skstinfo.store
WHERE skstinfo.store IS NULL;
--96 rows

SELECT skstinfo.store, store_msa.store
FROM skstinfo JOIN store_msa ON skstinfo.store=store_msa.store;
-- 38855192 rows

-- Below: common stores between skstinfo and store_msa?
SELECT DISTINCT skstinfo.store, store_msa.store
FROM skstinfo JOIN store_msa ON skstinfo.store=store_msa.store;
-- 328 rows

-- Below: any stores in skstinfo but not in store_msa?
SELECT DISTINCT skstinfo.store, store_msa.store
FROM skstinfo LEFT JOIN store_msa ON skstinfo.store=store_msa.store
WHERE store_msa.store IS NULL;
-- 29 rows

-- Below: any stores in store_msa but not skstinfo?
SELECT DISTINCT skstinfo.store, store_msa.store
FROM skstinfo RIGHT JOIN store_msa ON skstinfo.store=store_msa.store
WHERE skstinfo.store IS NULL;
-- 5 rows: 8304, 7203, 1704, 9906, 1804
SELECT skstinfo.store, store_msa.store
FROM skstinfo RIGHT JOIN store_msa ON skstinfo.store=store_msa.store
WHERE skstinfo.store IS NULL;
-- Same 5 rows: 8304, 7203, 1704, 9906, 1804

-- Below: any stores in trnsact but not skstinfo?
SELECT DISTINCT skstinfo.store, trnsact.store
FROM skstinfo RIGHT JOIN trnsact ON skstinfo.store=trnsact.store
WHERE skstinfo.store IS NULL;
-- takes a long time didn't finish

-- Below: any stores in store_msa but not in strinfo?
SELECT DISTINCT strinfo.store, store_msa.store
FROM strinfo RIGHT JOIN store_msa ON strinfo.store=store_msa.store
WHERE strinfo.store IS NULL;
-- None. All stores in store_msa and trnsact are in strinfo

-- Below:
SELECT DISTINCT store_msa.store, trnsact.store
FROM store_msa RIGHT JOIN trnsact ON store_msa.store=trnsact.store
WHERE store_msa.store IS NULL;
-- None. All stores in trnsact are in store_msa.
SELECT DISTINCT store_msa.store, trnsact.store
FROM store_msa LEFT JOIN trnsact ON store_msa.store=trnsact.store
WHERE trnsact.store IS NULL;
-- Only 1 store is in store_msa and not in trnsact: 104
-- Conclusion: the 5 stores that are in store_msa but not skstinfo are in trnsact

-- Ex3
-- It turns out there are many skus in the trnsact table that are not in the skstinfo table.
-- Examine some of the rows in the trnsact table that are not in the skstinfo table
-- to find any common features that could explain why the cost information is missing.
SELECT trnsact.*
FROM trnsact LEFT JOIN skstinfo ON trnsact.sku=skstinfo.sku AND trnsact.store=skstinfo.store
WHERE skstinfo.sku IS NULL;
-- 52338840 rows

-- Ex4
-- What is Dillard’s average profit per day?

-- Below: number of distinct registers in trnsact = 300
SELECT COUNT(DISTINCT register)
FROM trnsact;

-- Below: Daily profit per register (299 rows)
SELECT t.register, SUM(t.amt-s.cost*t.quantity)/COUNT(DISTINCT t.saledate) AS AvgDailyProfit
FROM trnsact t JOIN skstinfo s ON t.sku=s.sku AND t.store=s.store
WHERE t.stype='P'
GROUP BY t.register
ORDER BY AvgDailyProfit DESC, t.register ASC;
-- Highest: register 300 with $21,673.45

-- Below: daily profit per store (325 rows)
SELECT t.store, SUM(t.amt-s.cost*t.quantity)/COUNT(DISTINCT t.saledate) AS AvgDailyProfit
FROM trnsact t JOIN skstinfo s ON t.sku=s.sku AND t.store=s.store
WHERE t.stype='P'
GROUP BY t.store
ORDER BY AvgDailyProfit DESC, t.store ASC;
-- Higest: $17,055.78 at store 9806

-- daily profit total
SELECT SUM(t.amt-s.cost*t.quantity)/COUNT(DISTINCT t.saledate) AS AvgDailyProfit
FROM trnsact t JOIN skstinfo s ON t.sku=s.sku AND t.store=s.store
WHERE t.stype='P'
ORDER BY AvgDailyProfit;
-- $1,527,903.46 per day for Dillard's. Does that make sense???

-- Ex5
-- On what day was the total value (in $) of returned goods the greatest?
-- On what day was the total number of individual returned items the greatest?
SELECT t.saledate, SUM(t.amt) AS TotalReturnedAmt
FROM trnsact t
WHERE t.stype='R'
GROUP BY t.saledate
ORDER BY TotalReturnedAmt DESC;
-- 389 rows: Highest on 04/12/27 with $3,030,259.76 and Lowest on 04/09/05 with $421,809.30 
-- Note that second highest on 04/12/26 with $2,665,283.86. I guess it makes sense the 2 days with
-- highest $$ in returned goods are 2 days after Xmas
SELECT t.saledate, SUM(t.quantity) AS TotalReturnedGoods
FROM trnsact t JOIN skstinfo s ON t.sku=s.sku AND t.store=s.store
WHERE t.stype='R'
GROUP BY t.saledate
ORDER BY TotalReturnedGoods DESC;
-- 389 rows: Higest on 05/07/30 with 36984 items returned and Lowest on 04/09/05 with 3549 items

-- Ex 6
-- What is the maximum price paid for an item in our database?
-- What is the minimum price paid for an item in our database?
SELECT MIN(amt/quantity), MAX(amt/quantity)
FROM trnsact;
-- Min = $0 and Max = $6017.00

SELECT *
FROM trnsact
WHERE amt <= 0;
-- 1205238 rows
-- I find it very surprising that there are these many entries with zero $ paid. Are these all
-- voided entries?

-- Ex 7
-- How many departments have more than 100 brands associated with them, and what are their descriptions?

SELECT COUNT(DISTINCT dept)
FROM skuinfo;
-- 60
SELECT COUNT(DISTINCT dept)
FROM dept;
-- 60
SELECT DISTINCT deptinfo.dept, skuinfo.dept
FROM deptinfo JOIN skuinfo ON deptinfo.dept=skuinfo.dept;
-- 60, so department seems to be correctly populated in both skuinfo and deptinfo

SELECT d.dept, d.deptdesc COUNT(DISTINCT s.brand) AS NumBrands
FROM deptinfo d JOIN skuinfo s ON d.dept=s.dept
GROUP BY d.dept, d.deptdesc
HAVING NumBrands > 100
ORDER BY NumBrands DESC;
-- Looks like only 3 departments have more than 100 brands: 4407 (389 brands), 5203 (118 brands), 7104 (109 brands)

-- Ex8
-- Write a query that retrieves the department descriptions of each of the skus in the skstinfo table.
SELECT DISTINCT skstinfo.sku, skuinfo.dept, deptinfo.deptdesc
FROM (skstinfo LEFT JOIN skuinfo ON skstinfo.sku=skuinfo.sku) JOIN deptinfo ON skuinfo.dept=deptinfo.dept
-- 39,230,146 rows

-- Ex9
--  What department (with department description), brand, style, and color had the greatest total value of returned items?

-- Below: First see which brand, style, color have the greatest total value of returned items
SELECT s.brand, s.style, s.color, SUM(t.amt) AS ReturnedValue
FROM trnsact t JOIN skuinfo s ON t.sku=s.sku
WHERE t.stype='R'
GROUP BY s.brand, s.style, s.color
ORDER BY ReturnedValue DESC;
-- Result: Brand:POLO Style:FAS 4GZ 782633 Color:U KHAKI Amount: $216633.59
SELECT d.dept, d.deptdesc, s.brand, s.style, s.color, SUM(t.amt) AS ReturnedValue
FROM deptinfo d JOIN skuinfo s ON s.dept=d.dept JOIN trnsact t ON t.sku=s.sku
WHERE t.stype='R'
GROUP BY d.dept, d.deptdesc, s.brand, s.style, s.color
ORDER BY ReturnedValue DESC;
-- Result: Dept:4505 deptdesc:POLOMEN Brand:POLO Style:FAS 4GZ 782633 Color:U KHAKI Amt:216633.59

-- Ex10
-- In what state and zip code is the store that had the greatest total revenue during the time period
-- monitored in our dataset?
SELECT s.state, s.city, s.zip, SUM(t.amt) AS TotalRevenue
FROM strinfo s JOIN trnsact t ON s.store=t.store
WHERE t.stype='P'
GROUP BY s.state, s.city, s.zip
ORDER BY TotalRevenue DESC;
-- Highest total sales: State:LA City:METAIRIE Zip:70002 Amt:24171426.58
-- So this query gives me the correct 10th highest that is TX, Hurst, also in agreement with the
-- instruction to join 2 tables. If we want profit instead, we would need 3 tables (skstinfo as well)
-- for the cost using the following query:
SELECT s.state, s.city, s.zip, SUM(t.amt-skstinfo.cost*t.quantity) AS TotalProfit
FROM strinfo s JOIN trnsact t ON s.store=t.store JOIN skstinfo ON t.store=skstinfo.store AND t.sku=skstinfo.sku
WHERE t.stype='P'
GROUP BY s.state, s.city, s.zip
ORDER BY TotalProfit DESC;
-- With this, the 10th highest is LA Baton Rouge and the highest:
-- State:AR City:MABELVALE Zip:72103 Profit:6088912.79
