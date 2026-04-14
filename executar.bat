@echo off
:: Configurações de Conexão (Ajuste conforme sua senha e banco)
set PGPASSWORD=senha123
set DB_NAME=postgres

:: Adiciona o binário do Postgres ao Path temporário
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

cls
echo ============================================================
echo         SISTEMA DE PROCESSAMENTO DE ESTOQUE (SQL)
echo ============================================================
echo.

echo [1/3] Criando estrutura de tabelas...
psql -U postgres -d %DB_NAME% -f sql/1_schema.sql

echo [2/3] Inserindo dados de teste (Pedidos e Estoque)...
psql -U postgres -d %DB_NAME% -f sql/2_carga.sql

echo [3/3] Executando Cursor de Processamento de Regras...
psql -U postgres -d %DB_NAME% -f sql/3_processamento.sql

echo.
echo ============================================================
echo             CONTEUDO FINAL DAS TABELAS
echo ============================================================

echo.
echo --- TABELA: ESTOQUE DE PRODUTOS ---
psql -U postgres -d %DB_NAME% -c "SELECT id, nome, estoque FROM produtos ORDER BY id;"

echo.
echo --- TABELA: STATUS DOS PEDIDOS ---
psql -U postgres -d %DB_NAME% -c "SELECT id, data_pedido, status FROM pedidos ORDER BY id;"

echo.
echo --- TABELA: ITENS DOS PEDIDOS ---
psql -U postgres -d %DB_NAME% -c "SELECT pedido_id, produto_id, quantidade FROM itens_pedido ORDER BY pedido_id;"

echo.
echo ============================================================
echo                  RESUMO DE OPERACAO
echo ============================================================
psql -U postgres -d %DB_NAME% -c "SELECT status as Status_Pedido, count(*) as Total FROM pedidos GROUP BY status;"

echo.
echo Processamento concluido!
pause