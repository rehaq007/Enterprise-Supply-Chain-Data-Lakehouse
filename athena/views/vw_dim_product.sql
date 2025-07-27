CREATE OR REPLACE VIEW "vw_dim_product" AS 
SELECT DISTINCT
  product_id
, product_name
, category
, supplier_id
FROM
  supply_chain_db.inventory
