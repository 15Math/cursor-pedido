DO $$
DECLARE
    -- Declaração dos cursores para iteração de pedidos pendentes e seus respectivos itens
    c_pedidos CURSOR FOR 
        SELECT order_id, valor_total 
        FROM pedidos 
        WHERE status = 'NOVO' 
        ORDER BY valor_total DESC;
        
    c_itens CURSOR (p_order_id VARCHAR) FOR 
        SELECT sku, quantidade 
        FROM itens_pedido 
        WHERE order_id = p_order_id;

    v_pedido RECORD;
    v_item RECORD;
    v_estoque_atual NUMERIC;
    v_atende_total BOOLEAN;
BEGIN
    RAISE NOTICE '--- INICIANDO MIGRAÇÃO DOS DADOS ---';

    -- Carga e normalização dos dados. Insere clientes, produtos, pedidos (agrupados) e itens 
    -- a partir da tabela de staging, respeitando a hierarquia de chaves estrangeiras 
    -- do modelo relacional e ignorando registros que já existem na base.
    
    INSERT INTO clientes (cpf, nome, email, telefone)
    SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number 
    FROM temp_carga WHERE cpf IS NOT NULL AND cpf <> ''
    ON CONFLICT (cpf) DO NOTHING;

    INSERT INTO produtos (sku, nome, estoque)
    SELECT DISTINCT sku, product_name, 0 
    FROM temp_carga WHERE sku IS NOT NULL
    ON CONFLICT (sku) DO NOTHING;

    INSERT INTO pedidos (order_id, cpf_cliente, data_compra, valor_total, status)
    SELECT order_id, MAX(cpf), MAX(purchase_date::TIMESTAMP), SUM(quantity_purchased::NUMERIC * item_price::NUMERIC), 'NOVO'
    FROM temp_carga
    GROUP BY order_id
    ON CONFLICT (order_id) DO NOTHING;

    INSERT INTO itens_pedido (order_item_id, order_id, sku, quantidade, preco_unitario)
    SELECT order_item_id, order_id, sku, quantity_purchased::NUMERIC, item_price::NUMERIC
    FROM temp_carga
    ON CONFLICT (order_item_id) DO NOTHING;


    RAISE NOTICE '--- INICIANDO REGRA DE NEGÓCIO (ESTOQUE) ---';

    -- Processamento de estoque e avaliação dos pedidos prioritários (maior valor), 
    -- aplicando rigorosamente a regra de atendimento total ou direcionamento para fila de compras.
    
    OPEN c_pedidos;
    LOOP
        FETCH c_pedidos INTO v_pedido;
        EXIT WHEN NOT FOUND;
        
        v_atende_total := TRUE;
        
        -- Validação prévia de disponibilidade de estoque para todos os itens do pedido atual.
        OPEN c_itens(v_pedido.order_id);
        LOOP
            FETCH c_itens INTO v_item;
            EXIT WHEN NOT FOUND;
            
            SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
            IF v_estoque_atual < v_item.quantidade THEN
                v_atende_total := FALSE;
                EXIT;
            END IF;
        END LOOP;
        CLOSE c_itens;

        IF v_atende_total THEN
            
            -- Efetivação do pedido com baixa no estoque e auditoria de movimentação 
            -- para os pedidos que possuem saldo suficiente em sua totalidade.
            OPEN c_itens(v_pedido.order_id);
            LOOP
                FETCH c_itens INTO v_item;
                EXIT WHEN NOT FOUND;
                
                SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
                UPDATE produtos SET estoque = estoque - v_item.quantidade WHERE sku = v_item.sku;
                
                INSERT INTO movimentacao_estoque (sku, pedido_id, quantidade_debitada, saldo_anterior, saldo_atual)
                VALUES (v_item.sku, v_pedido.order_id, v_item.quantidade, v_estoque_atual, v_estoque_atual - v_item.quantidade);
            END LOOP;
            CLOSE c_itens;
            
            UPDATE pedidos SET status = 'PROCESSADO' WHERE order_id = v_pedido.order_id;
            RAISE NOTICE 'Pedido % (R$ %): PROCESSADO.', v_pedido.order_id, v_pedido.valor_total;
            
        ELSE
            
            -- Registro de pendência na tabela de compras calculando apenas o déficit 
            -- de estoque de cada item, marcando o pedido para aguardar reposição do fornecedor.
            OPEN c_itens(v_pedido.order_id);
            LOOP
                FETCH c_itens INTO v_item;
                EXIT WHEN NOT FOUND;
                
                SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
                IF v_estoque_atual < v_item.quantidade THEN
                    INSERT INTO compras (pedido_id, sku, quantidade_necessaria)
                    VALUES (v_pedido.order_id, v_item.sku, v_item.quantidade - v_estoque_atual);
                END IF;
            END LOOP;
            CLOSE c_itens;
            
            UPDATE pedidos SET status = 'PENDENTE_COMPRA' WHERE order_id = v_pedido.order_id;
            RAISE NOTICE 'Pedido % (R$ %): PENDENTE_COMPRA.', v_pedido.order_id, v_pedido.valor_total;
            
        END IF;

    END LOOP;
    CLOSE c_pedidos;
    
    -- Limpeza da tabela de staging temporária para liberar espaço e preparar para futuras cargas.
    TRUNCATE temp_carga;
END $$;