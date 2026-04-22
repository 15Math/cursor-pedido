
INSERT INTO produtos (sku, nome, estoque)
VALUES 
('roupa123rio', 'Camisa', 10),
('brinq789rio', 'Jogo', 5),
('eletr101', 'Celular', 10)
ON CONFLICT (sku) DO UPDATE 
SET estoque = produtos.estoque + EXCLUDED.estoque;