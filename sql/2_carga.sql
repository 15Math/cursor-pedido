-- 1. Limpa dados anteriores (Respeitando a hierarquia de chaves estrangeiras)
TRUNCATE itens_pedido, pedidos, produtos CASCADE;

-- 2. Tabela persistente para que o próximo script (psql) consiga ler
DROP TABLE IF EXISTS temp_pedidos_dia;
CREATE UNLOGGED TABLE temp_pedidos_dia (
    codigoPedido TEXT,
    dataPedido TEXT,
    SKU TEXT,
    UPC TEXT,
    nomeProduto TEXT,
    qtd INTEGER,
    valor TEXT,
    frete TEXT,
    email TEXT,
    codigoComprador TEXT,
    nomeComprador TEXT,
    endereco TEXT,
    CEP TEXT,
    UF TEXT,
    pais TEXT
);

-- 3. Carga do arquivo
-- Dica: use barras normais (/) no caminho para evitar problemas de escape no Windows
\copy temp_pedidos_dia FROM 'C:/Users/Windows 11/Documents/Matheus/MyReps/ETL-Pedidos-Java/data/pedidos.txt' WITH (FORMAT CSV, DELIMITER ';', HEADER, ENCODING 'UTF8');

-- 4. Limpeza de decimais (Garante que o REPLACE funcione antes do cast para Numeric no script 3)
UPDATE temp_pedidos_dia SET 
    valor = REPLACE(valor, ',', '.'),
    frete = REPLACE(frete, ',', '.');

-- 5. Inserção de produtos conhecidos para os testes de sucesso
INSERT INTO produtos (id, nome, estoque) VALUES 
('roupa123rio', 'camisa', 10),
('brinq789rio', 'jogo', 5)
ON CONFLICT (id) DO NOTHING;

-- Feedback visual no terminal
SELECT 'Carga inicial concluída' as status;