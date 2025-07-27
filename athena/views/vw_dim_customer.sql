CREATE OR REPLACE VIEW "vw_dim_customer" AS 
SELECT DISTINCT customer_id
FROM
  supply_chain_db.orders
