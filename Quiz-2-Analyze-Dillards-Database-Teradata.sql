-- Question 7
-- What was the highest original price in the Dillard’s database of the item with SKU 3631365?
SELECT orgprice
FROM trnsact
WHERE sku= 3631365
ORDER BY orgprice DESC;

-- Question 8
-- What is the color of the Liz Claiborne brand item with the highest SKU #
-- in the Dillard’s database (the Liz Claiborne brand is abbreviated “LIZ CLAI”
-- in the Dillard’s database)?
SELECT color, sku
FROM skuinfo
WHERE brand='LIZ CLAI'
ORDER BY sku DESC;

-- Question 10
-- What is the sku number of the item in the Dillard’s database that
-- had the highest original sales price?
SELECT TOP 10 sku, orgprice
FROM trnsact
ORDER BY orgprice DESC;

-- Question 11
-- According to the strinfo table, in how many states within the United States are Dillard’s
-- stores located?
SELECT DISTINCT state
FROM strinfo;

-- Question 12
-- How many Dillard’s departments start with the letter “e”?
SELECT DISTINCT deptdesc
FROM deptinfo
WHERE deptdesc LIKE 'e%';

-- Question 13
-- What was the date of the earliest sale in the database where the sale price of
-- the item did not equal the original price of the item, and what was the
-- largest margin (original price minus sale price) of an item sold on that earliest date?
SELECT saledate, orgprice, sprice
FROM trnsact
WHERE orgprice <> sprice
ORDER BY saledate ASC;

SELECT saledate, orgprice, sprice, (orgprice-sprice) AS margin
FROM trnsact
WHERE saledate='2004-08-01'
ORDER BY margin DESC;

-- Question 14
-- What register number made the sale with the highest original price and
-- highest sale price between the dates of August 1, 2004 and August 10, 2004?
-- Make sure to sort by original price first and sale price second.
SELECT register, orgprice, sprice
FROM trnsact
WHERE saledate BETWEEN '2004-08-01' AND '2004-08-10'
ORDER BY orgprice DESC, sprice DESC;

-- Question 15
-- Which of the following brand names with the word/letters “liz” in them
-- exist in the Dillard’s database?
SELECT DISTINCT brand
FROM skuinfo
WHERE brand LIKE '%liz%';

-- Question 16
-- What is the lowest store number of all the stores in the STORE_MSA table
-- that are in the city of “little rock”,”memphis”, or “tulsa”?
SELECT store, city
FROM store_msa
WHERE city in ('little rock', 'memphis', 'tulsa')
ORDER BY store ASC;
