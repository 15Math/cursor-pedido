-- Inserindo Produtos no Estoque
INSERT INTO produtos (nome, estoque) VALUES 
('Notebook', 10),
('Mouse', 50),
('Teclado', 2);

-- Criando 3 Pedidos (Todos começam como 'Pendente')
INSERT INTO pedidos (status) VALUES ('Pendente'); -- Pedido 1 (Vai ser atendido)
INSERT INTO pedidos (status) VALUES ('Pendente'); -- Pedido 2 (NÃO vai ser atendido, falta teclado)
INSERT INTO pedidos (status) VALUES ('Pendente'); -- Pedido 3 (Vai ser atendido)

-- Itens do Pedido 1 (Tem estoque de tudo)
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade) VALUES 
(1, 1, 2),  -- Quer 2 Notebooks (Tem 10)
(1, 2, 5);  -- Quer 5 Mouses (Tem 50)

-- Itens do Pedido 2 (FALTA ESTOQUE)
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade) VALUES 
(2, 1, 1),  -- Quer 1 Notebook (Tem)
(2, 3, 5);  -- Quer 5 Teclados (Só tem 2 no estoque!)

-- Itens do Pedido 3 (Tem estoque)
INSERT INTO itens_pedido (pedido_id, produto_id, quantidade) VALUES 
(3, 2, 10); -- Quer 10 Mouses (Tem 45 restantes após o Pedido 1)