DO $$
BEGIN
    RAISE NOTICE '--- INICIANDO REPOSIÇÃO DO FORNECEDOR ---';
END $$;

-- Cria a tabela temporária para receber os dados do fornecedor
DROP TABLE IF EXISTS temp_fornecedor;
CREATE UNLOGGED TABLE temp_fornecedor (
    sku TEXT,
    quantidade_recebida TEXT
);

\copy temp_fornecedor FROM 'C:/Users/Windows 11/Documents/Matheus/MyReps/cursor-pedido/data/fornecedor.csv' WITH (FORMAT CSV, DELIMITER ';', HEADER, ENCODING 'UTF8');

-- Atualiza o estoque dos produtos que já existem
UPDATE produtos p
SET estoque = p.estoque + f.quantidade_recebida::NUMERIC
FROM temp_fornecedor f
WHERE p.sku = f.sku;

-- Insere produtos que por ventura o fornecedor mandou mas não existiam no banco de dados
INSERT INTO produtos (sku, nome, estoque)
SELECT f.sku, 'Produto ' || f.sku, f.quantidade_recebida::NUMERIC
FROM temp_fornecedor f
ON CONFLICT (sku) DO NOTHING;

-- Limpa a tabela temporária
TRUNCATE temp_fornecedor;

DO $$
BEGIN
    RAISE NOTICE '--- REPOSIÇÃO CONCLUÍDA ---';
END $$;