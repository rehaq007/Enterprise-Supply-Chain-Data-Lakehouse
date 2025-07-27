CREATE OR REPLACE VIEW "vw_dim_warehouse" AS 
SELECT
  warehouse_id
, status_date last_status_date
, temperature
, humidity
, operational_status
FROM
  supply_chain_db.warehouses
