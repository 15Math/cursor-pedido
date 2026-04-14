DO $$
DECLARE
    -- Declara o cursor para buscar os pedidos pendentes
    cur_pedidos CURSOR FOR 
        SELECT id 
        FROM pedidos 
        WHERE status = 'Pendente' 
        ORDER BY data_pedido ASC 
        FOR UPDATE; -- Trava a linha para evitar concorrência

    v_pedido_id INT;
    v_pode_atender BOOLEAN;
    v_item RECORD;
BEGIN
    -- Abre o cursor
    OPEN cur_pedidos;

    LOOP
        -- Pega o próximo pedido da fila
        FETCH cur_pedidos INTO v_pedido_id;
        EXIT WHEN NOT FOUND;

        -- Verifica se TODOS os itens deste pedido têm estoque suficiente
        SELECT NOT EXISTS (
            SELECT 1
            FROM itens_pedido ip
            JOIN produtos p ON ip.produto_id = p.id
            WHERE ip.pedido_id = v_pedido_id
              AND p.estoque < ip.quantidade
        ) INTO v_pode_atender;

        -- Se puder atender, faz as atualizações
        IF v_pode_atender THEN
            
            -- Loop nos itens do pedido para debitar o estoque
            FOR v_item IN (SELECT produto_id, quantidade FROM itens_pedido WHERE pedido_id = v_pedido_id)
            LOOP
                UPDATE produtos
                SET estoque = estoque - v_item.quantidade
                WHERE id = v_item.produto_id;
            END LOOP;

            -- Marca o pedido como 'Atendido'
            UPDATE pedidos
            SET status = 'Atendido'
            WHERE id = v_pedido_id;

        END IF;
    END LOOP;

    -- Fecha o cursor
    CLOSE cur_pedidos;
    
    RAISE NOTICE 'Processamento finalizado com sucesso.';
END;
$$;