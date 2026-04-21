@echo off
:: ============================================================
:: CONFIGURAÇÕES DE CONEXÃO
:: ============================================================
set PGPASSWORD=senha123
set DB_NAME=postgres
set DB_USER=postgres
set DB_HOST=localhost
set DB_PORT=5432

:: Adiciona o binário do Postgres ao Path temporário 
:: (Verifique se a versão 18 é a que está instalada no seu diretório)
set PATH=%PATH%;C:\Program Files\PostgreSQL\18\bin

cls
echo ============================================================
echo          SISTEMA DE PROCESSAMENTO DE ESTOQUE (SQL)
echo ============================================================
echo.

:: [1/3] Criando estrutura de tabelas
echo [1/3] Criando estrutura de tabelas...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql/1_schema.sql
if %ERRORLEVEL% neq 0 GOTO :ERROR

:: [2/3] Inserindo dados de teste
echo [2/3] Inserindo dados de teste (Pedidos e Estoque)...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql/2_carga.sql
if %ERRORLEVEL% neq 0 GOTO :ERROR

:: [3/3] Executando Cursor de Processamento
echo [3/3] Executando Cursor de Processamento de Regras...
psql -h %DB_HOST% -p %DB_PORT% -U %DB_USER% -d %DB_NAME% -f sql/3_processamento.sql
if %ERRORLEVEL% neq 0 GOTO :ERROR

echo.
echo ============================================================
echo              CONTEUDO FINAL DAS TABELAS
echo ============================================================

echo.
echo --- TABELA: ESTOQUE DE PRODUTOS ---
psql -U %DB_USER% -d %DB_NAME% -c "SELECT id, nome, estoque FROM produtos ORDER BY id;"

echo.
echo --- TABELA: STATUS DOS PEDIDOS ---
psql -U %DB_USER% -d %DB_NAME% -c "SELECT id, data_pedido, status FROM pedidos ORDER BY id;"

echo.
echo --- TABELA: ITENS DOS PEDIDOS ---
psql -U %DB_USER% -d %DB_NAME% -c "SELECT pedido_id, produto_id, quantidade FROM itens_pedido ORDER BY pedido_id;"

echo.
echo ============================================================
echo                   RESUMO DE OPERACAO
echo ============================================================
psql -U %DB_USER% -d %DB_NAME% -c "SELECT status as Status_Pedido, count(*) as Total FROM pedidos GROUP BY status;"

echo.
echo Processamento concluido com sucesso!
pause
exit

:ERROR
echo.
echo ############################################################
echo              ERRO DURANTE O PROCESSAMENTO
echo ############################################################
echo Ocorreu um erro ao executar um dos scripts SQL.
pause