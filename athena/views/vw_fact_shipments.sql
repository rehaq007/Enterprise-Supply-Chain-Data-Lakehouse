CREATE OR REPLACE VIEW "vw_fact_shipments" AS 
SELECT
  s.shipment_id
, s.order_id
, s.carrier
, s.delivery_status
, warehouse_id
, CAST(s.shipment_date AS date) shipment_date
, d.year
, d.month
, d.day
FROM
  ((supply_chain_db.shipments s
LEFT JOIN supply_chain_db.vw_dim_warehouse w USING (warehouse_id))
LEFT JOIN supply_chain_db.vw_dim_date d ON (CAST(s.shipment_date AS date) = d.full_date))
