USE DataWareHouse;

-- for windows
BULK INSERT bronze.crm_cust_info
FROM 'dir/to/csv/file.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);

-- for linux 
/* in terminal
 * cp "/to/csv/dir/source_crm/cust_info.csv" /tmp/cust_info.csv
 * chmod 644 /tmp/cust_info.csv
 * or
 * cp "/to/csv/dir/source_crm/*.csv" /tmp/cust_info.csv    */
 * chmod 644 /tmp/*.csv   */ 
 */

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	PRINT '=============================================='
	PRINT 'Loading Bronze Layer'
	PRINT '=============================================='
	
	PRINT '------------------------------'
	PRINT 'Loading crm table'
	PRINT '------------------------------'
	
	PRINT '-> Truncating Table: bronze.crm_cust_info'
	TRUNCATE TABLE bronze.crm_cust_info;

	PRINT '-> Inserting data into: bronze.crm_cust_info'
	BULK INSERT bronze.crm_cust_info
	FROM '/tmp/cust_info.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);

	PRINT '-> Truncating Table: bronze.crm_prd_info'
	TRUNCATE TABLE bronze.crm_prd_info;

	PRINT '-> Inserting data into: bronze.crm_prd_info'
	BULK INSERT bronze.crm_prd_info
	FROM '/tmp/prd_info.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);
	
	PRINT '-> Truncating Table: bronze.crm_sales_details'
	TRUNCATE TABLE bronze.crm_sales_details;

	PRINT '-> Inserting data into: bronze.crm_sales_details'
	BULK INSERT bronze.crm_sales_details
	FROM '/tmp/sales_details.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);
	
	PRINT '------------------------------'
	PRINT 'Loading erp tables'
	PRINT '------------------------------'
	
	PRINT '-> Truncating Table: bronze.erp_cust_az12'	
	TRUNCATE TABLE bronze.erp_cust_az12;

	PRINT '-> Inserting data into: bronze.erp_cust_az12'
	BULK INSERT bronze.erp_cust_az12
	FROM '/tmp/CUST_AZ12.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);
	
	PRINT '-> Truncating Table: bronze.erp_loc_a101'
	TRUNCATE TABLE bronze.erp_loc_a101;

	PRINT '-> Inserting data into: bronze.erp_loc_a101'
	BULK INSERT bronze.erp_loc_a101
	FROM '/tmp/LOC_A101.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);
	
	PRINT '-> Truncating Table: bronze.erp_px_cat_g1v2'
	TRUNCATE TABLE bronze.erp_px_cat_g1v2;

	PRINT '-> Inserting data into: bronze.erp_px_cat_g1v2'
	BULK INSERT bronze.erp_px_cat_g1v2
	FROM '/tmp/PX_CAT_G1V2.csv'
	WITH (
	    FIRSTROW = 2,
	    FIELDTERMINATOR = ',',
	    ROWTERMINATOR = '\n',
	    TABLOCK
	);
END;



EXEC bronze.load_bronze;



SELECT COUNT(*) FROM bronze.crm_cust_info;
SELECT COUNT(*) 
FROM bronze.crm_cust_info cci
WHERE cci.cst_gndr IS NOT NULL;