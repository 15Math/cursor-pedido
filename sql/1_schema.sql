-- Limpa as tabelas na ordem correta para evitar erros de chave estrangeira
DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;

-- Tabela de Produtos
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    estoque NUMERIC(10, 2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_estoque_positivo CHECK (estoque >= 0)
);

-- Tabela de Pedidos
CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Pendente',
    CONSTRAINT chk_status_pedido CHECK (status IN ('Pendente', 'Atendido', 'Cancelado'))
);

-- Tabela de Itens do Pedido
CREATE TABLE itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id INT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id INT NOT NULL REFERENCES produtos(id),
    quantidade NUMERIC(10, 2) NOT NULL,
    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0)
);