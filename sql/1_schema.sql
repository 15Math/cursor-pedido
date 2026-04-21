-- 1. Limpa ambiente
DROP TABLE IF EXISTS compras CASCADE;
DROP TABLE IF EXISTS movimentacao_estoque CASCADE;
DROP TABLE IF EXISTS itens_pedido CASCADE;
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS produtos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- 2. Clientes
CREATE TABLE clientes (
    cpf VARCHAR(20) PRIMARY KEY,
    nome VARCHAR(150),
    email VARCHAR(150),
    telefone VARCHAR(50)
);

-- 3. Produtos
CREATE TABLE produtos (
    sku VARCHAR(50) PRIMARY KEY,
    nome VARCHAR(150),
    estoque NUMERIC(10,2) DEFAULT 0
);

-- 4. Pedidos 
CREATE TABLE pedidos (
    order_id VARCHAR(50) PRIMARY KEY,
    cpf_cliente VARCHAR(20) REFERENCES clientes(cpf),
    data_compra TIMESTAMP,
    valor_total NUMERIC(15,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'NOVO' CHECK (status IN ('NOVO', 'PROCESSADO', 'PENDENTE_COMPRA'))
);

-- 5. Itens do Pedido 
CREATE TABLE itens_pedido (
    order_item_id VARCHAR(50) PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL REFERENCES pedidos(order_id) ON DELETE CASCADE,
    sku VARCHAR(50) NOT NULL REFERENCES produtos(sku),
    quantidade NUMERIC(10,2) NOT NULL,
    preco_unitario NUMERIC(15,2) NOT NULL
);

-- 6. Histórico de Movimentação de Estoque
CREATE TABLE movimentacao_estoque (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) REFERENCES produtos(sku),
    pedido_id VARCHAR(50) REFERENCES pedidos(order_id),
    quantidade_debitada NUMERIC(10,2),
    saldo_anterior NUMERIC(10,2),
    saldo_atual NUMERIC(10,2),
    data_movimento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. Compras (Produtos que faltaram para fechar pedidos)
CREATE TABLE compras (
    id SERIAL PRIMARY KEY,
    pedido_id VARCHAR(50) REFERENCES pedidos(order_id),
    sku VARCHAR(50) REFERENCES produtos(sku),
    quantidade_necessaria NUMERIC(10,2),
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'PENDENTE'
);