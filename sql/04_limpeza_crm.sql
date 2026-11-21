-- =====================================================
-- Situação 4: Limpeza do export do CRM
-- Pedido: deixar o export de clientes limpo e contar os clientes únicos e os sem e-mail.
-- Regra: nunca alterar a tabela bruta; o resultado vai para uma tabela nova.
-- Ferramenta: MySQL 8
-- =====================================================

DROP TABLE IF EXISTS clientes_crm_limpo;

CREATE TABLE clientes_crm_limpo AS
SELECT * FROM (
    -- Passo 1: padronizar textos, datas e canais + tirar a linha de teste
    WITH padronizado AS (
        SELECT CAST(cliente_id AS UNSIGNED) AS cliente_id,
               TRIM(nome)                   AS nome,
               LOWER(TRIM(email))           AS email,
               TRIM(cidade)                 AS cidade_bruta,
               UPPER(TRIM(estado))          AS estado,
               CASE WHEN data_cadastro LIKE '__/__/____'
                    THEN STR_TO_DATE(data_cadastro, '%d/%m/%Y')
                    ELSE STR_TO_DATE(data_cadastro, '%Y-%m-%d')
               END                          AS data_cadastro,
               CASE WHEN canal_aquisicao IN ('insta', 'instagram') THEN 'Instagram'
                    WHEN canal_aquisicao IN ('google ads')         THEN 'Google Ads'
                    WHEN canal_aquisicao IN ('organico')           THEN 'Orgânico'
                    WHEN canal_aquisicao IN ('indicacao')          THEN 'Indicação'
                    WHEN canal_aquisicao IN ('email', 'e-mail')    THEN 'E-mail'
               END                          AS canal_aquisicao
        FROM clientes_crm_export_bruto
        WHERE COALESCE(email, '') <> 'teste@teste.com'
    ),
    -- Passo 2: trocar a cidade "suja" pelo nome oficial
    com_cidade AS (
        SELECT p.*, c.cidade
        FROM padronizado p
        LEFT JOIN (SELECT DISTINCT cidade FROM clientes) c
               ON c.cidade = p.cidade_bruta
    ),
    -- Passo 3: numerar as repetições de cada e-mail
    numerado AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY email ORDER BY cliente_id) AS repeticao
        FROM com_cidade
    )
    -- Passo 4: ficar só com a 1ª ocorrência (e com quem não tem e-mail)
    SELECT cliente_id, nome, email, cidade, estado, data_cadastro, canal_aquisicao
    FROM numerado
    WHERE email IS NULL OR repeticao = 1
) AS limpo;

-- Conferência: 2391 clientes, 95 sem e-mail
SELECT COUNT(*) AS clientes, SUM(email IS NULL) AS sem_email
FROM clientes_crm_limpo;
-- Resposta: o arquivo bruto tinha 2.535 linhas. Saíram 1 linha de teste e 143 duplicatas.
--           Ficaram 2.391 clientes únicos, dos quais 95 estão sem e-mail.
--           Padronizados: cidades, estados, datas (dois formatos), canais (10 grafias -> 5) e e-mails.
