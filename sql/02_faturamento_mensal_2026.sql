-- =====================================================
-- Situação 2: Faturamento mensal de 2026
-- Pedido: faturamento, pedidos e ticket médio mês a mês (jan–out/2026) e o total, para o Financeiro.
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

with receita_pedido as (
select pedido_id, sum(quantidade * preco_unitario * (1 - desconto_pct)) as receita 
	from itens_pedido
	group by pedido_id
)
select date_format(pedidos.data_pedido, '%Y-%m') as mes,
	count(*) as pedidos,
	round(sum(receita_pedido.receita), 2) as faturamento,
    round(avg(receita_pedido.receita), 2) as ticket_medio
 from pedidos
	left join receita_pedido
    on receita_pedido.pedido_id = pedidos.pedido_id
    where pedidos.status = 'entregue'
    and pedidos.data_pedido between '2026-01-01' and '2026-10-31'
    group by mes WITH ROLLUP
    ;
-- A linha com mes = NULL (WITH ROLLUP) é o total do período.
-- Resposta: jan–out/2026 = 11.546 pedidos entregues, R$ 3.139.420,61 de faturamento,
--           ticket médio de R$ 271,91. Melhor mês: agosto (R$ 374.646,75).
