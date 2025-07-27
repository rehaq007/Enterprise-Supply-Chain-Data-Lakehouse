CREATE OR REPLACE VIEW "vw_fact_orders" AS 
SELECT
  o.order_id
, o.customer_id
, p.product_id
, o.order_quantity qty_ordered
, o.order_status
, w.warehouse_id
, CAST(o.order_date AS date) order_date
, d.year
, d.month
, d.day
FROM
  (((supply_chain_db.orders o
LEFT JOIN supply_chain_db.vw_dim_product p ON (o.product_id = p.product_id))
LEFT JOIN supply_chain_db.vw_dim_warehouse w ON (o.warehouse_id = w.warehouse_id))
LEFT JOIN supply_chain_db.vw_dim_date d ON (CAST(o.order_date AS date) = d.full_date))
