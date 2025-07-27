-- Run this script only after running all scripts from the directory athena/views

CREATE OR REPLACE VIEW "supply_chain_db"."vw_dashboard_master" AS

WITH
  orders_flat AS (
    SELECT
      order_id,
      CAST(order_date AS date)   AS order_date,
      order_status,
      qty_ordered,
      product_id,
      customer_id,
      warehouse_id,
      snapshot_date
    FROM "supply_chain_db"."vw_fact_orders"
  ),

  shipments_flat AS (
    SELECT
      shipment_id,
      order_id,
      CAST(shipment_date AS date) AS shipment_date,
      delivery_status,
      carrier
    FROM "supply_chain_db"."vw_fact_shipments"
  ),

  inventory_flat AS (
    SELECT
      product_id,
      warehouse_id,
      stock_quantity,
      reorder_level,
      CAST(snapshot_date AS date) AS inventory_date
    FROM "supply_chain_db"."vw_fact_inventory"
  )

SELECT
  o.order_id,
  o.order_date,
  o.order_status,
  o.qty_ordered,

  -- Product & Supplier context
  p.product_id,
  p.product_name,
  p.category,
  p.supplier_id,
  s.supplier_name,
  s.location               AS supplier_location,

  -- Customer context
  c.customer_id,

  -- Warehouse context
  w.warehouse_id,
  w.last_status_date       AS warehouse_status_date,
  w.temperature,
  w.humidity,
  w.operational_status,

  -- Shipment details
  sh.shipment_id,
  sh.shipment_date,
  sh.delivery_status,
  sh.carrier,

  -- Inventory snapshot
  inv.stock_quantity,
  inv.reorder_level,
  inv.inventory_date       AS inventory_snapshot_date,

  -- Date dimensions
  d.full_date,
  d.year,
  d.month,
  d.day,
  d.day_of_week

FROM orders_flat o

LEFT JOIN shipments_flat sh
  ON o.order_id = sh.order_id

LEFT JOIN inventory_flat inv
  ON o.product_id   = inv.product_id
 AND o.warehouse_id = inv.warehouse_id
 AND o.order_date   = inv.inventory_date

LEFT JOIN "supply_chain_db"."vw_dim_product" p
  ON o.product_id = p.product_id

LEFT JOIN "supply_chain_db"."vw_dim_supplier" s
  ON p.supplier_id = s.supplier_id

LEFT JOIN "supply_chain_db"."vw_dim_customer" c
  ON o.customer_id = c.customer_id

LEFT JOIN "supply_chain_db"."vw_dim_warehouse" w
  ON o.warehouse_id = w.warehouse_id

LEFT JOIN "supply_chain_db"."vw_dim_date" d
  ON o.order_date = d.full_date
;
