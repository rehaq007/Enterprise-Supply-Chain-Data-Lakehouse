CREATE OR REPLACE VIEW "vw_dim_date" AS 
WITH
  dates AS (
   SELECT ingestion_date full_date
   FROM
     supply_chain_db.inventory
UNION    SELECT CAST(order_date AS date) full_date
   FROM
     supply_chain_db.orders
UNION    SELECT CAST(shipment_date AS date) full_date
   FROM
     supply_chain_db.shipments
UNION    SELECT CAST(status_date AS date) full_date
   FROM
     supply_chain_db.warehouses
) 
SELECT
  full_date
, year(full_date) year
, month(full_date) month
, day(full_date) day
, day_of_week(full_date) day_of_week
FROM
  dates
