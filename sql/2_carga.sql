DROP TABLE IF EXISTS temp_carga;
CREATE UNLOGGED TABLE temp_carga (
    order_id TEXT,
    order_item_id TEXT,
    purchase_date TEXT,
    payments_date TEXT,
    buyer_email TEXT,
    buyer_name TEXT,
    cpf TEXT,
    buyer_phone_number TEXT,
    sku TEXT,
    upc TEXT,
    product_name TEXT,
    quantity_purchased TEXT,
    currency TEXT,
    item_price TEXT,
    ship_service_level TEXT,
    ship_address_1 TEXT,
    ship_address_2 TEXT,
    ship_address_3 TEXT,
    ship_city TEXT,
    ship_state TEXT,
    ship_postal_code TEXT,
    ship_country TEXT
);

\copy temp_carga FROM 'C:/Users/Windows 11/Documents/Matheus/MyReps/cursor-pedido/data/pedidos_marketplace.csv' WITH (FORMAT CSV, DELIMITER ';', HEADER, ENCODING 'UTF8');

UPDATE temp_carga 
SET 
    cpf = REPLACE(REPLACE(cpf, '.', ''), '-', ''),
    item_price = REPLACE(item_price, ',', '.'),
    quantity_purchased = REPLACE(quantity_purchased, ',', '.');