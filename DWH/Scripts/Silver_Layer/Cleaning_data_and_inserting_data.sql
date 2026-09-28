USE DataWareHouse;

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
