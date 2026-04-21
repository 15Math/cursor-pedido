@echo off
:: Configurações de Conexão (Ajuste conforme seu banco)
set PGPASSWORD=senha123
set DB_NAME=meu_banco
set DB_USER=postgres
set HOST=localhost
set PORT=5432
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin
    
:: Caminho dos arquivos SQL (Certifique-se que os nomes estão corretos)
set SQL_SCHEMA="sql/1_schema.sql"
set SQL_CARGA="sql/2_carga.sql"
set SQL_PROC="sql/3_processamento.sql"
set SQL_FORN="sql/4_reposicao_fornecedor.sql"

cls
echo ============================================================
echo          SISTEMA DE PROCESSAMENTO DE ESTOQUE (SQL)
echo ============================================================

echo.
echo [1/4] Criando estrutura de tabelas...
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -f %SQL_SCHEMA% -q

echo [1.5/4] Inicializando estoque...
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -f "sql/0_inicializa_estoque.sql" -q

echo [2/4] Carregando arquivo CSV do Marketplace...
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -f %SQL_CARGA% -q

echo [3/4] Executando Regras de Negocio e Priorizacao (Valor)...
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -f %SQL_PROC%

echo [4/4] Processando entrada de mercadoria do Fornecedor...
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -f %SQL_FORN% -q

echo.
echo ============================================================
echo              CONTEUDO FINAL DAS TABELAS
echo ============================================================

echo.
echo --- TABELA: ESTOQUE DE PRODUTOS ---
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT sku, nome, estoque FROM produtos ORDER BY sku;"

echo.
echo --- TABELA: STATUS DOS PEDIDOS (Ordenados por Valor) ---
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT order_id, cpf_cliente, valor_total, status FROM pedidos ORDER BY valor_total DESC;"

echo.
echo --- TABELA: MOVIMENTACAO DE ESTOQUE ---
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT sku, pedido_id, quantidade_debitada, saldo_atual, data_movimento FROM movimentacao_estoque;"

echo.
echo --- TABELA: NECESSIDADE DE COMPRAS (Faltas) ---
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT pedido_id, sku, quantidade_necessaria, status FROM compras;"

echo.
echo ============================================================
echo                  RESUMO DE OPERACAO
echo ============================================================
psql -h %HOST% -p %PORT% -U %DB_USER% -d %DB_NAME% -c "SELECT status, COUNT(*) as total FROM pedidos GROUP BY status;"

echo.
echo Processamento concluido com sucesso!
pause