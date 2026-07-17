/*
==================================================================================================
Stored Procedure : Load Bronze Layer (Source -> Bronze)
==================================================================================================

Script Purpose: 
              This stored procedure loads data into the 'bronze' schema from external CSV files.
              It performs  the following actions :
              - Truncates the bronze tables before loading data.
              - Uses the 'BULK INSERT' command to load data from csv files to bronze tables .


Parameters:
          
         None 
         This stored procedure does not accept any parameters or return any values .

Usuage Example:
EXEC bronze.load_bronze ;

*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    Declare @start_time DATETIME, @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME ;
    BEGIN TRY

            PRINT '======================================'
            PRINT 'LOADING Bronze Layer'
            PRINT '======================================'


            PRINT '--------------------------------------'
            PRINT 'Loading CRM Tables '
            PRINT '--------------------------------------'

     
       PRINT '>> Truncating Table : bronze.crm_cust_info';

            SET @batch_start_time = GETDATE();

            SET @start_time = GETDATE() ;
            TRUNCATE TABLE bronze.crm_cust_info;

            BULK INSERT bronze.crm_cust_info
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
            WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK 
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';



            PRINT '>> Truncating Table : bronze.crm_prd_info';

            SET @start_time = GETDATE();
            TRUNCATE TABLE bronze.crm_prd_info;

            BULK INSERT bronze.crm_prd_info
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
            WITH (
                FIRSTROW = 2,
                FIELDTERMINATOR = ',',
                TABLOCK 
            );

            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';



            PRINT '>> Truncating Table : bronze.crm_sales_details';
            SET @start_time = GETDATE() ;
            TRUNCATE TABLE bronze.crm_sales_details

            BULK INSERT bronze.crm_sales_details
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
            WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK 
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';




            PRINT '--------------------------------------'
            PRINT 'Loading ERP Tables '
            PRINT '--------------------------------------'


            PRINT '>> Truncating Table : bronze.erp_cust_az12';

            SET @start_time = GETDATE() ;
            TRUNCATE TABLE bronze.erp_cust_az12;

            BULK INSERT bronze.erp_cust_az12
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
            WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK 
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';




            
            PRINT '>> Truncating Table : bronze.erp_loc_a101';
            SET @start_time = GETDATE() ;
            TRUNCATE TABLE bronze.erp_loc_a101;
            BULK INSERT bronze.erp_loc_a101
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
            WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK 
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';




            PRINT '>> Truncating Table : bronze.erp_px_cat_glv2';

            SET @start_time = GETDATE() ;
            TRUNCATE TABLE bronze.erp_px_cat_glv2;
            BULK INSERT bronze.erp_loc_a101
            FROM 'C:\Users\.m\Documents\SQL_files\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
            WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK 
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
            PRINT '>> --------------------------------------------';
            SET @batch_end_time  = GETDATE()
            PRINT '==============================================================================================='
            PRINT 'Loading Broze Layer is completed' ;
            PRINT ' - Total Load Duration: ' + CAST(DATEDIFF(SECOND , @batch_start_time  , @batch_end_time) AS NVARCHAR) + 'seconds'
    END TRY 
    BEGIN CATCH
            PRINT '==========================================================='
            PRINT 'Error Occured During loading BRONZE layer'
            PRINT 'Error Message' + Error_Message();
            PRINT 'Error Message' + CAST(Error_Number() AS NVARCHAR ) ; 
            PRINT 'Error Message' + CAST(Error_State() AS NVARCHAR ) ;


    END CATCH

END


 
