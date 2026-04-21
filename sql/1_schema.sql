-- Limpa o ambiente para novos testes
DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;

-- Tabela de Produtos: O ID é o SKU (Texto)
CREATE TABLE produtos (
    id VARCHAR(50) PRIMARY KEY, 
    nome VARCHAR(100) NOT NULL,
    estoque NUMERIC(10, 2) NOT NULL DEFAULT 0,
    CONSTRAINT chk_estoque_positivo CHECK (estoque >= 0)
);

-- Tabela de Pedidos: O ID é o Código do Pedido do CSV
CREATE TABLE pedidos (
    id TEXT PRIMARY KEY,
    data_pedido TIMESTAMP,
    status TEXT CHECK (status IN ('PROCESSADO', 'SEM ESTOQUE', 'PENDENTE', 'CANCELADO')), -- Adicione aqui
    valor_total NUMERIC DEFAULT 0
);

-- Tabela de Itens: Faz a ponte entre Pedido e SKU
CREATE TABLE itens_pedido (
    id SERIAL PRIMARY KEY,
    pedido_id VARCHAR(50) NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
    produto_id VARCHAR(50) NOT NULL REFERENCES produtos(id),
    quantidade NUMERIC(10, 2) NOT NULL,
    CONSTRAINT chk_quantidade_positiva CHECK (quantidade > 0)
);