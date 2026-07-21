/*USE DataWareHouse;


==============================================================================================
Stored Procedure : Load Silver Layer (Bronze -> Silver) 
==============================================================================================

Script Purpose : 
    This stored procedure  performs the ETL (Extract , Transform , Load) Process to populate the 'silver'
    schema tables from the 'bronze' schema
Actions Performed : 

 - Truncate Silver Tables 
 - Inserts transformed and cleansed data from Bronze into Silver tables .


Parameters : 
None .
  This stored procedure does not accept any parameters or return any values.


Usuage examples: 
EXEC Silver.load_silver ;

*/

CREATE  OR ALTER PROCEDURE silver.load_silver AS 
BEGIN 
    Declare @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time DATETIME;

    BEGIN TRY
    
    SET @batch_start_time = GETDATE();


    PRINT '============================================='
    PRINT ' LOADING SILVER LAYER '
    PRINT '============================================='



    PRINT '--------------------------------------------------'
    PRINT 'Loading CRM Tables'
    PRINT '--------------------------------------------------'



    PRINT '>> Truncating Table : Silver.crm_cust_info ' ;
    
    SET @start_time = GETDATE()

    TRUNCATE TABLE silver.crm_cust_info; 
    PRINT '>> Inserting Data Info : Silver.crm_cust_info' ; 

    INSERT INTO Silver.crm_cust_info (
        cst_id, 
        cst_key, 
        cst_firstname, 
        cst_lastname, 
        cst_marital_status, 
        cst_gndr, 
        cst_create_date
    )
    SELECT 
          cst_id , 
          cst_key , 
          TRIM(cst_firstname) AS cst_firstname , 
          TRIM(cst_lastname) AS cst_lastname , 
          CASE 
              WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
              WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
              ELSE 'n/a'
          END AS cst_marital_status,

           CASE 
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' 
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' 
            ELSE 'n/a' 
        END AS cst_gndr,
        cst_create_date
    
        FROM (
              SELECT 
                    * , ROW_NUMBER() OVER (partition by cst_id order by cst_create_date DESC ) AS Flag_last
                    FROM bronze.crm_cust_info
                    WHERE cst_id IS NOT NULL
             ) t 

             where flag_last  = 1

        SET @end_time = GETDATE()
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
        PRINT '>> --------------------------------------------';


    

    PRINT '>> Truncating Table : Silver.crm_prd_info ' ;
    SET @start_time = GETDATE();
    TRUNCATE TABLE silver.crm_prd_info; 
    PRINT '>> Inserting Data Info : Silver.crm_prd_info' ; 

    INSERT INTO silver.crm_prd_info(
    prd_id,
    cat_id , 
    prd_key,
    prd_nm,
    prd_cost,
    prd_line , 
    prd_start_dt,
    prd_end_dt
    )
    SELECT 
          prd_id , 
          REPLACE(SUBSTRING(prd_key,1,5),'-','_') as  cat_id,  -- Extract category ID (Derived COlumns)

          SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,        -- Extract Product Key (Derived Columns)

          prd_nm ,

          ISNULL(prd_cost,0) AS prd_cost ,                     -- Transformation of DATA (TOD)

          CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain' 
               WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road' 
               WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
               WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring' 
          ELSE 'n/a'                                             -- Handling Missing values
          END AS prd_line,

          CAST(prd_start_dt AS DATE) AS prd_start_dt ,             -- TOD

          CAST(LEAD(prd_start_dt) OVER (partition by prd_key order by prd_start_dt ASC) - 1 AS DATE) as prd_end_dt
          -- we here derive the end date from the start date
    FROM bronze.crm_prd_info ;

    SET @end_time = GETDATE()

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';




    PRINT '>> Truncating Table : silver.crm_sales_details';
    SET @start_time = GETDATE()
    TRUNCATE TABLE silver.crm_sales_details;
    PRINT 'Inserting Data Into silver.crm_sales_details from bronze.crm_sales_details ';
    INSERT INTO silver.crm_sales_details(
    sls_ord_num , 
    sls_prd_key , 
    sls_cust_id , 
    sls_order_dt ,
    sls_ship_dt ,
    sls_due_dt,
    sls_sales ,
    sls_quantity,
    sls_price
    )

    SELECT 
    sls_ord_num , 
    sls_prd_key , 
    sls_cust_id , 

    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) !=8 THEN NULL
         ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
    END AS sls_order_dt , 

    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) !=8 THEN NULL
         ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) 
         END AS sls_ship_dt ,

    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) !=8 THEN NULL
         ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
         END AS sls_due_dt,

    CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales   -- Recalculates sales if original value is missing or incorrect 
    END AS sls_sales ,

    sls_quantity,

    CASE WHEN sls_price IS NULL OR SLS_price < 0
              THEN sls_sales / NULLIF(sls_quantity,0)
         ELSE sls_price
    END AS sls_price
      -- Derive price if original value is invalid .

    from bronze.crm_sales_details;
    SET @end_time = GETDATE()

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';



    PRINT '>> Truncating Table : Silver.erp_cust_az12';
    SET @start_time = GETDATE()
    TRUNCATE TABLE silver.erp_cust_az12;
    PRINT 'Inserting Data Into Silver.erp_cust_az12 from bronze.erp_cust_az12 ';
    INSERT INTO silver.erp_cust_az12(
    cid,
    bdate ,
    gen
    )
    SELECT 
    
         CASE WHEN cid LIKE 'NAS%' Then SUBSTRING(cid,4,len(cid)) 
              ELSE cid 
         END AS cid ,  -- Handled invalid values

         CASE WHEN bdate > GETDATE() then NULL 
              ELSE bdate 
         END as bdate,  -- Handled invalid values such as future birthdates to NULL 

         CASE WHEN UPPER(TRIM(gen)) IN ('F','Female') THEN 'Female'
              WHEN UPPER(TRIM(gen)) IN ('M','Male') THEN 'Male'
              ELSE 'n/a'
         END as gen -- perform Data Normalization and handled missing values information.

    from bronze.erp_cust_az12;

    SET @end_time = GETDATE()

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';





    PRINT '>> Truncating Table : Silver.erp_loc_a101';

    SET @start_time = GETDATE()

    TRUNCATE TABLE silver.erp_loc_a101;
    PRINT 'Inserting Data Into Silver.erp_loc_a101 from bronze.erp_loc_a101 ';
    INSERT INTO silver.erp_loc_a101
    (cid ,cntry)
    SELECT 
    RePlace(cid,'-','') as cid , -- Handled 
     CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'               -- removing unwanted space
          WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
          WHEN TRIM(cntry)  = '' OR cntry IS NULL THEN 'n/a'
          ELSE TRIM(cntry) -- Data Normalization.
    END AS cntry
    from bronze.erp_loc_a101;

    SET @end_time = GETDATE()

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';




    PRINT '>> Truncating Table : Silver.erp_px_cat_g1v2'

    SET @start_time = GETDATE()
    TRUNCATE TABLE silver.erp_px_cat_glv2

    PRINT 'Inserting Data Into silver.erp_px_cat_g1v2 from bronze.erp_px_cat_g1v2 ) '
    INSERT INTO silver.erp_px_cat_glv2
    (id,cat,subcat,maintenance)
    SELECT 
    id , 
    cat , 
    subcat ,
    maintenance 
    from bronze.erp_px_cat_g1v2;

    SET @end_time = GETDATE()

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @start_time,@end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';

    SET @batch_end_time = GETDATE();

    PRINT '>> Load Duration: ' + CAST(DATEDIFF(second , @batch_start_time,@batch_end_time) AS NVARCHAR) + 'seconds';
    PRINT '>> --------------------------------------------';

END TRY 

BEGIN CATCH
           PRINT '====================================================================='
           PRINT 'Error Occured during loading Silver Layer'
           PRINT 'Error Message' + Error_Message();
           PRINT 'Error Message' + CAST(Error_Number() AS NVARCHAR ) ;
           PRINT 'Error Message' + CAST(Error_State() aS NVARCHAR ) ;

END CATCH

END 
