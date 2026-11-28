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




-- ===============================================
-- ================ crm_prd_info =================
-- ===============================================


SELECT * FROM bronze.crm_prd_info;

-- checking nulls and duplicates in primary key 
SELECT 
	prd_id ,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- expectation: no result
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistincy
SELECT DISTINCT prd_line 
FROM bronze.crm_prd_info;

-- Check for Invalid Date Orders
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- fix invalid date
SELECT 
	prd_id ,
	prd_key ,
	prd_nm ,
	prd_start_dt ,
	prd_end_dt ,
	DATEADD (
		DAY,
		-1,
		LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
		) AS prd_end_dt_test 
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509', 'AC-HE-HL-U509-R')




-- CHECKING AFTER INSERTING

SELECT * FROM silver.crm_prd_info;

-- checking nulls and duplicates in primary key 
SELECT 
	prd_id ,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- expectation: no result
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization & Consistincy
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;

-- Check for Invalid Date Orders
-- expectation: no result
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;



-- ===============================================
-- ============== crm_sales_details ==============
-- ===============================================
SELECT * FROM bronze.crm_sales_details;

-- unwanted space
SELECT
	sls_ord_num
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- product key is connected or not
SELECT
	sls_prd_key
FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- customer info is connected or not
SELECT
	sls_cust_id
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- check for Invalid Dates
SELECT
	NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <=  0 OR LEN(sls_order_dt) != 8;

-- also checking Invalid Dates but only between buiseness start date and current date
SELECT
	NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt > 20261123 OR sls_order_dt < 19000101;



-- SHIP DATE
-- check for Invalid Dates
SELECT
	NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <=  0 OR LEN(sls_ship_dt) != 8;

-- also checking Invalid Dates but only between buiseness start date and current date
SELECT
	NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt > 20261123 OR sls_ship_dt < 19000101;


-- Check for Invalid Date Orders
SELECT *
FROM bronze.crm_sales_details csd 
WHERE csd.sls_order_dt > csd.sls_ship_dt OR csd.sls_order_dt > csd.sls_due_dt ;


-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
SELECT DISTINCT 
	csd.sls_sales ,
	csd.sls_quantity ,
	csd.sls_price 
FROM bronze.crm_sales_details csd 
WHERE csd.sls_sales != csd.sls_quantity * csd.sls_price
OR csd.sls_sales IS NULL OR csd.sls_quantity IS NULL OR csd.sls_price IS NULL
OR csd.sls_sales <= 0 OR csd.sls_quantity <= 0 OR csd.sls_price <= 0
ORDER BY csd.sls_sales , csd.sls_quantity , csd.sls_price ;

-- fixing
SELECT DISTINCT 
	csd.sls_sales AS old_sls_sales,
	csd.sls_quantity ,
	csd.sls_price AS old_sls_price,
	CASE 
		WHEN csd.sls_sales IS NULL OR csd.sls_sales <= 0 OR csd.sls_sales != csd.sls_quantity * ABS(csd.sls_price)
			THEN csd.sls_quantity * ABS(csd.sls_price)
		ELSE csd.sls_sales 
	END AS sls_sales ,
	CASE 
		WHEN csd.sls_price IS NULL OR csd.sls_price <= 0
			THEN csd.sls_sales / NULLIF(csd.sls_quantity, 0)
		ELSE csd.sls_price
	END AS sls_price
FROM bronze.crm_sales_details csd 
WHERE csd.sls_sales != csd.sls_quantity * csd.sls_price
OR csd.sls_sales IS NULL OR csd.sls_quantity IS NULL OR csd.sls_price IS NULL
OR csd.sls_sales <= 0 OR csd.sls_quantity <= 0 OR csd.sls_price <= 0
ORDER BY csd.sls_sales , csd.sls_quantity , csd.sls_price ;


-- ===============================================
-- =========== CECK AFTER INSERTING ==============
-- ===============================================
SELECT * FROM silver.crm_sales_details;

-- unwanted space
SELECT
	sls_ord_num
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- product key is connected or not
SELECT
	sls_prd_key
FROM silver.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

-- customer info is connected or not
SELECT
	sls_cust_id
FROM silver.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- check for Invalid Dates
SELECT
	NULLIF(sls_order_dt, 0) sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <=  0 OR LEN(sls_order_dt) != 8;

-- also checking Invalid Dates but only between buiseness start date and current date
SELECT
	NULLIF(sls_order_dt, 0) sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt>'2026-11-23' OR sls_order_dt<'1900-01-01';


-- SHIP DATE
-- check for Invalid Dates
SELECT
	NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <=  0 OR LEN(sls_ship_dt) != 8;

-- also checking Invalid Dates but only between buiseness start date and current date
SELECT
	NULLIF(sls_ship_dt, 0) sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt > '2026-11-23' OR sls_ship_dt < '1900-01-01';


-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_sales_details csd 
WHERE csd.sls_order_dt > csd.sls_ship_dt OR csd.sls_order_dt > csd.sls_due_dt ;


-- Check Data Consistency: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.
SELECT DISTINCT 
	csd.sls_sales ,
	csd.sls_quantity ,
	csd.sls_price 
FROM silver.crm_sales_details csd 
WHERE csd.sls_sales != csd.sls_quantity * csd.sls_price
OR csd.sls_sales IS NULL OR csd.sls_quantity IS NULL OR csd.sls_price IS NULL
OR csd.sls_sales <= 0 OR csd.sls_quantity <= 0 OR csd.sls_price <= 0
ORDER BY csd.sls_sales , csd.sls_quantity , csd.sls_price ;




-- ===============================================
-- ================ erp_cust_az12 ================
-- ===============================================


-- cid issue
SELECT 
	eca.cid 
FROM bronze.erp_cust_az12 eca 
WHERE eca.cid LIKE 'NAS%';

-- date of birth issue
SELECT DISTINCT 
	eca.bdate 
FROM bronze.erp_cust_az12 eca 
WHERE bdate > GETDATE();

-- gender consistency
SELECT DISTINCT
    eca.gen,
    CASE
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'M%' THEN 'Male'
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'F%' THEN 'Female'
	    ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12 AS eca;

-- fix all of them
SELECT 
	CASE 
		WHEN eca.cid LIKE 'NAS%' THEN SUBSTRING(eca.cid, 4, LEN(eca.cid))
		ELSE eca.cid
	END AS cid ,
	CASE 
		WHEN eca.bdate > GETDATE() THEN NULL
		ELSE eca.bdate  
	END AS bdate ,
	CASE
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'M%' THEN 'Male'
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'F%' THEN 'Female'
	    ELSE 'n/a'
	END AS gen
FROM bronze.erp_cust_az12 eca ; 


-- check after inserting


-- cid issue
SELECT 
	eca.cid 
FROM silver.erp_cust_az12 eca 
WHERE eca.cid LIKE 'NAS%';

-- date of birth issue
SELECT DISTINCT 
	eca.bdate 
FROM silver.erp_cust_az12 eca 
WHERE bdate > GETDATE();

-- gender consistency
SELECT DISTINCT
    eca.gen,
    CASE
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'M%' THEN 'Male'
	    WHEN UPPER(TRIM(eca.gen)) LIKE 'F%' THEN 'Female'
	    ELSE 'n/a'
	END AS gen
FROM silver.erp_cust_az12 AS eca;





-- ===============================================
-- ================ erp_loc_a101 =================
-- ===============================================

-- check foreign key
SELECT 
	REPLACE(ela.cid, '-', '') AS cid ,
	ela.cntry 
FROM bronze.erp_loc_a101 ela 
WHERE REPLACE(ela.cid, '-', '') NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- Data Standardization & Consistency
SELECT DISTINCT
	ela.cntry ,
	CASE 
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'UNITED STATES%' OR UPPER(TRIM(ela.cntry)) LIKE 'US%' THEN 'United States'
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'UNITED KINGDOM%' OR UPPER(TRIM(ela.cntry)) LIKE 'UK%' THEN 'United Kingdom'
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'GERMANY%' OR UPPER(TRIM(ela.cntry)) LIKE 'DE%' THEN 'Germany'
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'AUSTRALIA%' THEN 'Australia'
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'CANADA%' THEN 'Canada'
		WHEN UPPER(TRIM(ela.cntry)) LIKE 'FRANCE%' THEN 'France'
		ELSE 'n/a'
	END AS cntrya
FROM bronze.erp_loc_a101 ela;

-- or
-- this script is not working in my machine , because of hidden line breaks , so use the next script
SELECT
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

SELECT DISTINCT
    CASE
        WHEN NULLIF(UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))), '') IS NULL
            THEN 'n/a'
        WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))) = 'DE'
            THEN 'Germany'
        WHEN UPPER(TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))) IN ('US', 'USA')
            THEN 'United States'
        ELSE TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), ''))
    END AS cntry
FROM bronze.erp_loc_a101;

-- or
WITH cleaned AS (
    SELECT
        TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) AS clean_cntry
    FROM bronze.erp_loc_a101
)
SELECT DISTINCT 
    CASE
        WHEN cl.clean_cntry = 'DE' THEN 'Germany'
        WHEN cl.clean_cntry IN ('US', 'USA') THEN 'United States'
        WHEN cl.clean_cntry = '' OR cl.clean_cntry IS NULL THEN 'n/a'
        ELSE cl.clean_cntry
    END AS cntry
FROM cleaned cl;

-- ====================================
-- check after inserting
-- ====================================

SELECT DISTINCT cntry
FROM silver.erp_loc_a101 ela 
ORDER BY cntry ;

SELECT 
*
FROM silver.erp_loc_a101 ela



-- ===============================================
-- ============== erp_px_cat_g1v2 ================
-- ===============================================

SELECT 
	epcgv.id ,
	epcgv.cat ,
	epcgv.subcat ,
	epcgv.maintenance 
FROM bronze.erp_px_cat_g1v2 epcgv

-- Check for unwanted Spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency 
SELECT DISTINCT 
	cat
FROM bronze.erp_px_cat_g1v2 epcgv ;

SELECT DISTINCT 
	subcat
FROM bronze.erp_px_cat_g1v2 epcgv ;

SELECT DISTINCT 
	TRIM(REPLACE(REPLACE(epcgv.maintenance , CHAR(13), ''), CHAR(10), '')) AS maintenance 
FROM bronze.erp_px_cat_g1v2 epcgv ;

-- check for hidden text
SELECT * FROM bronze.erp_px_cat_g1v2 epcgv
WHERE cat != TRIM(REPLACE(REPLACE(epcgv.cat , CHAR(13), ''), CHAR(10), '')) 
OR subcat != TRIM(REPLACE(REPLACE(epcgv.subcat , CHAR(13), ''), CHAR(10), '')) 
OR maintenance != TRIM(REPLACE(REPLACE(epcgv.maintenance , CHAR(13), ''), CHAR(10), ''));

-- with id
SELECT 
epcgv.id 
FROM bronze.erp_px_cat_g1v2 epcgv
WHERE epcgv.id != TRIM(REPLACE(REPLACE(epcgv.id , CHAR(13), ''), CHAR(10), '')); 



-- check after inserting

SELECT * FROM silver.erp_px_cat_g1v2 epcgv
WHERE cat != TRIM(REPLACE(REPLACE(epcgv.cat , CHAR(13), ''), CHAR(10), '')) 
OR subcat != TRIM(REPLACE(REPLACE(epcgv.subcat , CHAR(13), ''), CHAR(10), '')) 
OR maintenance != TRIM(REPLACE(REPLACE(epcgv.maintenance , CHAR(13), ''), CHAR(10), ''));

SELECT DISTINCT 
	TRIM(REPLACE(REPLACE(epcgv.maintenance , CHAR(13), ''), CHAR(10), '')) AS maintenance 
FROM silver.erp_px_cat_g1v2 epcgv ;

SELECT 
	epcgv.maintenance 
FROM silver.erp_px_cat_g1v2 epcgv 
WHERE TRIM(REPLACE(REPLACE(epcgv.maintenance , CHAR(13), ''), CHAR(10), '')) != epcgv.maintenance ;