USE DataWareHouse;

--====================================
------------- crm_cust_info
--====================================

-- Check duplicates
WITH extract_duplicate AS (
	SELECT 
	cst_id, 
	cst_create_date ,
	COUNT(*) OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
)
SELECT * FROM extract_duplicate
WHERE flag_last = 1;

-- Check for unwanted spaces
SELECT cst_firstname 
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname );



-- Insert the clean data to crm_cust_info table
INSERT INTO silver.crm_cust_info (
	cst_id ,
	cst_key ,
	cst_firstname ,
	cst_lastname ,
	cst_marital_status ,
	cst_gndr ,
	cst_create_date
)
SELECT 
	cst_id ,
	cst_key ,
	TRIM(cst_firstname) AS cst_firstname , 
	TRIM(cst_lastname) AS cst_lastname ,
	CASE
		WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
		WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
		ELSE 'n/a'
	END AS cst_marital_status ,
	CASE
		WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
		WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
		ELSE 'n/a'
	END AS cst_gndr ,
	cst_create_date 
FROM(
	SELECT 
	* ,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
)t
WHERE t.flag_last = 1;



-- crm_prd_info
SELECT * FROM bronze.crm_prd_info;
-- checking nulls and duplicates in primary key 
SELECT 
	prd_id ,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

SELECT 
	prd_id ,
	prd_key ,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_key ,
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key ,
	prd_nm ,
	ISNULL(prd_cost, 0) AS prd_cost ,
	CASE
		WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
		WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
		WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
		WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
		ELSE 'n/a'
	END AS prd_line ,
	prd_start_dt ,
	prd_end_dt
FROM bronze.crm_prd_info;