CREATE OR REPLACE VIEW "vw_fact_inventory" AS 
SELECT
  product_id
, p.category
, i.warehouse_id
, i.stock_quantity
, i.reorder_level
, CAST(i.last_restock_date AS date) last_restock_date
, CAST(i.ingestion_date AS date) snapshot_date
, d.year
, d.month
, d.day
FROM
  ((supply_chain_db.inventory i
LEFT JOIN supply_chain_db.vw_dim_product p USING (product_id))
LEFT JOIN supply_chain_db.vw_dim_date d ON (CAST(i.ingestion_date AS date) = d.full_date))
