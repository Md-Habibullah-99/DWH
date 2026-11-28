USE DataWareHouse;

--====================================
------------- crm_cust_info
--====================================


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


-- ===============================================
-- ================ crm_prd_info =================
-- ===============================================



-- ===============================================
-- =============== inserting data ================
-- ===============================================

INSERT INTO silver.crm_prd_info (
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)
SELECT 
	prd_id ,
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
	DATEADD (
		DAY,
		-1,
		LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
		) AS prd_end_dt
FROM bronze.crm_prd_info;







-- ===============================================
-- ============== crm_sales_details ==============
-- ===============================================


-- ==========================================
-- ================ INSERTING DATA ==========
-- ==========================================


INSERT INTO silver.crm_sales_details (
	sls_ord_num ,
	sls_prd_key ,
	sls_cust_id ,
	sls_order_dt ,
	sls_ship_dt ,
	sls_due_dt ,
	sls_sales ,
	sls_quantity ,
	sls_price 
)
SELECT
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_order_dt,
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	CASE 
		WHEN csd.sls_sales IS NULL OR csd.sls_sales <= 0 OR csd.sls_sales != csd.sls_quantity * ABS(csd.sls_price)
			THEN csd.sls_quantity * ABS(csd.sls_price)
		ELSE csd.sls_sales 
	END AS sls_sales ,
	sls_quantity,
	CASE 
		WHEN csd.sls_price IS NULL OR csd.sls_price <= 0
			THEN csd.sls_sales / NULLIF(csd.sls_quantity, 0)
		ELSE csd.sls_price
	END AS sls_price
FROM bronze.crm_sales_details csd;


-- ===============================================
-- ================ erp_cust_az12 ================
-- ===============================================


-- ===============================================
-- ================== INSERTING ==================
-- ===============================================

INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
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



-- ===============================================
-- ================ erp_loc_a101 =================
-- ===============================================

-- ===============================================
-- ================== INSERTING ==================
-- ===============================================

WITH cleaned AS (
    SELECT
    	REPLACE(cid, '-', '') AS cid ,
        TRIM(REPLACE(REPLACE(cntry, CHAR(13), ''), CHAR(10), '')) AS clean_cntry
    FROM bronze.erp_loc_a101
)
INSERT INTO silver.erp_loc_a101 
(cid, cntry)
SELECT
	cl.cid ,
    CASE
        WHEN cl.clean_cntry = 'DE' THEN 'Germany'
        WHEN cl.clean_cntry IN ('US', 'USA') THEN 'United States'
        WHEN cl.clean_cntry = '' OR cl.clean_cntry IS NULL THEN 'n/a'
        ELSE cl.clean_cntry
    END AS cntry
FROM cleaned cl;

