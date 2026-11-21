-- =====================================================
-- Situação 1: Conhecendo a base
-- Pedido: resumo da base para a gestora (clientes, produtos, pedidos, período e status).
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

-- Quantidade de clientes na empresa?
select count(distinct cliente_id) as total_clientes from clientes;
-- Resultado:10.000

-- Quantidade de produtos na empresa? 
select count(distinct nome_produto) as total_produtos from produtos;
-- Resultado:54

-- Quantidade de pedidos na empresa?
select count(distinct pedido_id) as total_pedidos from pedidos; 
-- Resultado:20004

-- Data inicio e fim dos dados?
select min(data_pedido) as primeira_data, max(data_pedido) as ultima_data from pedidos;
-- Resposta: inicio: 2025-01-04 / fim : 2026-10-31

-- Pedidos por status:
select status, 
	count(*) as qtd_pedidos from pedidos
group by status
order by qtd_pedidos desc;
-- Resposta: Entregue:18313 / Cancelado:1104 / Devolvido:587


-- Itens vendidos por produto e status (cada linha de item conta 1):
with produtos_por_status as (
    select pedidos.*,itens_pedido.produto_id
    from pedidos
    left join itens_pedido
           on pedidos.pedido_id = itens_pedido.pedido_id
),
 produtos_por_status_categoria as (
	select produtos_por_status.*, produtos.nome_produto 
	from produtos_por_status 
    left join produtos
			on produtos_por_status.produto_id = produtos.produto_id
)
select nome_produto,
       SUM(status = 'entregue')  as entregues,
       SUM(status = 'cancelado') as cancelados,
       SUM(status = 'devolvido') as devolvidos,
       COUNT(*)                  as total
from produtos_por_status_categoria
group by nome_produto
order by total desc;
-- Resposta: Carregador Turbo 30W lidera (2.697 itens entregues, 170 cancelados, 85 devolvidos)

-- Quantidade de clientes que se cadastraram mas nunca compraram nada? 
with clientes_sem_compras as( 
	select clientes.* , pedidos.pedido_id from clientes
    left join pedidos
    on clientes.cliente_id = pedidos.cliente_id
    )
select count(*) from clientes_sem_compras 
	where pedido_id is null;
-- Resposta: 225

-- Mensagem para a gestora:
-- A base tem 10.000 clientes, 54 produtos e 20.004 pedidos, de 04/01/2025 a 31/10/2026.
-- 91,5% dos pedidos foram entregues, 5,5% cancelados e 2,9% devolvidos.
-- 225 clientes se cadastraram e nunca fizeram pedido.
