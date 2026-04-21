DO $$
DECLARE
    r RECORD;
    v_estoque_atual NUMERIC;
    v_produto_existente BOOLEAN;
BEGIN
    RAISE NOTICE 'Iniciando processamento de pedidos...';

    -- Loop pelos registros da tabela que o Script 2 carregou
    FOR r IN (SELECT * FROM temp_pedidos_dia) LOOP
        
        -- 1. Verifica se o produto existe
        SELECT EXISTS(SELECT 1 FROM produtos WHERE id = r.sku) INTO v_produto_existente;

        -- 2. Se não existe, cadastra com estoque 0
        IF NOT v_produto_existente THEN
            INSERT INTO produtos (id, nome, estoque)
            VALUES (r.sku, r.nomeProduto, 0);
            v_estoque_atual := 0;
            RAISE NOTICE 'Produto % cadastrado automaticamente com estoque 0.', r.sku;
        ELSE
            SELECT estoque INTO v_estoque_atual FROM produtos WHERE id = r.sku;
        END IF;

        -- 3. Lógica de decisão
        IF v_estoque_atual >= r.qtd::NUMERIC AND r.qtd::NUMERIC > 0 THEN
            -- TEM ESTOQUE
            UPDATE produtos SET estoque = estoque - r.qtd::NUMERIC WHERE id = r.sku;

            -- CORREÇÃO: Insere o pedido, mas se ele já existir (ON CONFLICT), ignora e não faz nada
            INSERT INTO pedidos (id, data_pedido, status)
            VALUES (r.codigoPedido, r.dataPedido::DATE, 'PROCESSADO')
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO itens_pedido (pedido_id, produto_id, quantidade)
            VALUES (r.codigoPedido, r.sku, r.qtd::NUMERIC);

            RAISE NOTICE 'Pedido % (Item %): Processado.', r.codigoPedido, r.sku;
        ELSE
            -- SEM ESTOQUE
            -- CORREÇÃO: Se faltar estoque para este item, cria o pedido ou ATUALIZA um pedido existente para 'SEM ESTOQUE'
            INSERT INTO pedidos (id, data_pedido, status)
            VALUES (r.codigoPedido, r.dataPedido::DATE, 'SEM ESTOQUE')
            ON CONFLICT (id) DO UPDATE SET status = 'SEM ESTOQUE';

            RAISE NOTICE 'Pedido % (Item %): Sem estoque.', r.codigoPedido, r.sku;
        END IF;

    END LOOP;
END $$;

-- Limpa a tabela para a próxima rodada do .bat
TRUNCATE temp_pedidos_dia;