CREATE OR REPLACE VIEW "vw_dim_supplier" AS 
SELECT
  supplier_id
, supplier_name
, contact_name
, phone
, email
, location
FROM
  supply_chain_db.suppliers
