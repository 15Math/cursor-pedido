DO $$
DECLARE
    v_pedido RECORD;
    v_item RECORD;
    v_estoque_atual NUMERIC;
    v_atende_total BOOLEAN;
BEGIN
    RAISE NOTICE '--- INICIANDO MIGRAÇÃO DOS DADOS ---';

    -- CLIENTES: Inserir novos clientes
    INSERT INTO clientes (cpf, nome, email, telefone)
    SELECT DISTINCT cpf, buyer_name, buyer_email, buyer_phone_number 
    FROM temp_carga WHERE cpf IS NOT NULL AND cpf <> ''
    ON CONFLICT (cpf) DO NOTHING;

    -- PRODUTOS: Inserir novos produtos vendidos (estoque inicial zero)
    INSERT INTO produtos (sku, nome, estoque)
    SELECT DISTINCT sku, product_name, 0 
    FROM temp_carga WHERE sku IS NOT NULL
    ON CONFLICT (sku) DO NOTHING;

    -- PEDIDOS: Agrupar por order_id e calcular valor total do pedido
    INSERT INTO pedidos (order_id, cpf_cliente, data_compra, valor_total, status)
    SELECT 
        order_id, 
        MAX(cpf), 
        MAX(purchase_date::TIMESTAMP), 
        SUM(quantity_purchased::NUMERIC * item_price::NUMERIC),
        'NOVO'
    FROM temp_carga
    GROUP BY order_id
    ON CONFLICT (order_id) DO NOTHING;

    -- ITENS DO PEDIDO: Transferir dados linha a linha
    INSERT INTO itens_pedido (order_item_id, order_id, sku, quantidade, preco_unitario)
    SELECT 
        order_item_id, order_id, sku, quantity_purchased::NUMERIC, item_price::NUMERIC
    FROM temp_carga
    ON CONFLICT (order_item_id) DO NOTHING;

    RAISE NOTICE '--- INICIANDO REGRA DE NEGÓCIO (ESTOQUE) ---';

    -- LÓGICA DE NEGÓCIO: Processar pedidos ordenados pelo MAIOR valor (DESC)
    FOR v_pedido IN (
        SELECT order_id, valor_total 
        FROM pedidos 
        WHERE status = 'NOVO' 
        ORDER BY valor_total DESC
    ) LOOP
        
        v_atende_total := TRUE;
        
        -- VERIFICAÇÃO DE ESTOQUE TOTAL
        FOR v_item IN (SELECT sku, quantidade FROM itens_pedido WHERE order_id = v_pedido.order_id) LOOP
            SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
            IF v_estoque_atual < v_item.quantidade THEN
                v_atende_total := FALSE;
                EXIT; -- Sai do loop, pois já sabemos que falta estoque
            END IF;
        END LOOP;

        --AÇÃO BASEADA NO ESTOQUE
        IF v_atende_total THEN
            -- TEM ESTOQUE PARA TUDO: Deduzir estoque e registrar movimentação
            FOR v_item IN (SELECT sku, quantidade FROM itens_pedido WHERE order_id = v_pedido.order_id) LOOP
                
                -- Pega o saldo antes do débito
                SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
                
                -- Debita da tabela de produtos
                UPDATE produtos SET estoque = estoque - v_item.quantidade WHERE sku = v_item.sku;
                
                -- Registra auditoria
                INSERT INTO movimentacao_estoque (sku, pedido_id, quantidade_debitada, saldo_anterior, saldo_atual)
                VALUES (v_item.sku, v_pedido.order_id, v_item.quantidade, v_estoque_atual, v_estoque_atual - v_item.quantidade);
                
            END LOOP;
            
            UPDATE pedidos SET status = 'PROCESSADO' WHERE order_id = v_pedido.order_id;
            RAISE NOTICE 'Pedido % (R$ %): PROCESSADO.', v_pedido.order_id, v_pedido.valor_total;
            
        ELSE
            -- NÃO TEM ESTOQUE PARA TUDO: Enviar itens faltantes para Compras
            FOR v_item IN (SELECT sku, quantidade FROM itens_pedido WHERE order_id = v_pedido.order_id) LOOP
                SELECT estoque INTO v_estoque_atual FROM produtos WHERE sku = v_item.sku;
                
                -- Descobre se ESSE item específico falta no estoque
                IF v_estoque_atual < v_item.quantidade THEN
                    INSERT INTO compras (pedido_id, sku, quantidade_necessaria)
                    VALUES (v_pedido.order_id, v_item.sku, v_item.quantidade - v_estoque_atual);
                END IF;
            END LOOP;
            
            UPDATE pedidos SET status = 'PENDENTE_COMPRA' WHERE order_id = v_pedido.order_id;
            RAISE NOTICE 'Pedido % (R$ %): PENDENTE_COMPRA.', v_pedido.order_id, v_pedido.valor_total;
        END IF;

    END LOOP;
    
    TRUNCATE temp_carga;
END $$;