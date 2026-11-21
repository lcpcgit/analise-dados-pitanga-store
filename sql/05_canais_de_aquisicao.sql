-- =====================================================
-- Situação 5: Qual canal traz os melhores clientes?
-- Pedido: comparar os canais de aquisição para o orçamento de Marketing de 2027.
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

with receita_pedido as (
    select pedido_id,
           round(sum(preco_unitario * quantidade * (1 - desconto_pct)), 2) as receita
    from itens_pedido
    group by pedido_id
),
por_cliente as (
    select clientes.cliente_id,
           clientes.canal_aquisicao,
           count(pedidos.pedido_id)                 as pedidos,
           coalesce(sum(receita_pedido.receita), 0) as receita
    from clientes
    left join pedidos
           on pedidos.cliente_id = clientes.cliente_id
          and pedidos.status = 'entregue'
    left join receita_pedido
           on receita_pedido.pedido_id = pedidos.pedido_id
    where clientes.data_cadastro <= '2025-12-31'
    group by clientes.cliente_id, clientes.canal_aquisicao
)
select canal_aquisicao,
       count(*)                              as clientes,
       round(100 * avg(pedidos >= 2), 1)     as pct_recompra,
       round(avg(pedidos), 2)                as pedidos_por_cliente,
       round(avg(receita), 2)                as receita_por_cliente,
       round(sum(receita) / sum(pedidos), 2) as ticket_medio
from por_cliente
group by canal_aquisicao
order by receita_por_cliente desc;
-- Só clientes cadastrados em 2025, para todos terem pelo menos 10 meses para comprar.
-- Resposta: Google Ads traz mais clientes (1.459), mas Indicação traz os melhores:
--           R$ 928,85 por cliente (cerca de 60% a mais que Google Ads, R$ 579,18) e 65,5% de recompra.
--           Recomendação: testar um programa de indicação e cruzar com o custo de aquisição (CAC) de cada canal.
