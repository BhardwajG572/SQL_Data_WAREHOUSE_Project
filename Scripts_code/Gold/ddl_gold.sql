/*
================================================================================================================4

DDL Script : Create Gold Views 

================================================================================================================

Script Purpose : 
     This script creates views for the Gold Layer in the data warehouse.   
     The Gold layer represents the final dimensions and fact tables (star schema)

     Each view performs tranformations and combines data from the silver layer
to produce a clean , enriched , and business - ready data set .


Usuage : 
       - These views can be queried directly for analytics and reporting .

==========================================================================================================
*/


-- =======================================================================================================
-- Create Dimension : gold.dim_customers 
--  ======================================================================================================

IF OBJECT_ID('gold.dim_customers','V') IS NOT NULL
    DROP VIEW gold.dim_customers;

GO
