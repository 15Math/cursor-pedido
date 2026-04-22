DO $$
BEGIN
    RAISE NOTICE '--- INICIANDO REPOSIÇÃO DO FORNECEDOR ---';
END $$;

DROP TABLE IF EXISTS temp_fornecedor;
CREATE UNLOGGED TABLE temp_fornecedor (
    sku TEXT,
    quantidade_recebida TEXT
);

\copy temp_fornecedor FROM 'C:/Users/Windows 11/Documents/Matheus/MyReps/cursor-pedido/data/fornecedor.csv' WITH (FORMAT CSV, DELIMITER ';', HEADER, ENCODING 'UTF8');

UPDATE produtos p
SET estoque = p.estoque + f.quantidade_recebida::NUMERIC
FROM temp_fornecedor f
WHERE p.sku = f.sku;

INSERT INTO produtos (sku, nome, estoque)
SELECT f.sku, 'Produto ' || f.sku, f.quantidade_recebida::NUMERIC
FROM temp_fornecedor f
ON CONFLICT (sku) DO NOTHING;

TRUNCATE temp_fornecedor;

DO $$
BEGIN
    RAISE NOTICE '--- REPOSIÇÃO CONCLUÍDA ---';
END $$;