/*
====================================================================
Create Database and Schemas
====================================================================
Script Purpose:
	This script creates a new database named 'DataWareHouse' after checking if it already exist.
	If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
	within the database: 'bronze', 'silver', and 'gold'.

WARNING:
	Running this script will drop the entire 'DataWareHouse' database if it exist.
	All data in the database will be permently deleted. Proceed with caution and ensure you have proper backups before running this script.
 */



USE master;

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'datawarehouse')
BEGIN
	ALTER DATABASE DataWareHouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWareHouse;
END;


CREATE DATABASE DataWareHouse;

USE DataWareHouse;

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

SELECT 1 FROM sys.databases d WHERE d.name = 'datawareHouse';