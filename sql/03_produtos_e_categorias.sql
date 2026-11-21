-- =====================================================
-- Situação 3: O que vende e o que dá lucro
-- Pedido: top 10 produtos por receita em 2026 e o peso e a margem bruta de cada categoria, para o Comercial.
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

-- Top 10 produtos que mais faturaram em 2026
with top_produtos as (
    select itens_pedido.*,
           produtos.nome_produto,
           pedidos.status,
           pedidos.data_pedido
    from itens_pedido
    join produtos on itens_pedido.produto_id = produtos.produto_id
    join pedidos on itens_pedido.pedido_id  = pedidos.pedido_id
)
select nome_produto,
       SUM(quantidade) as unidades,
       ROUND(SUM(preco_unitario * quantidade * (1 - desconto_pct)), 2) as receita
from top_produtos
where status = 'entregue'
  and data_pedido >= '2026-01-01'
group by nome_produto
order by receita desc
limit 10
;
-- Resposta: Tablet 10 pol (R$ 218.964,37) e Carregador Turbo 30W (R$ 218.550,18) quase empatam,
--           mas o carregador vendeu 2.790 unidades contra 173 do tablet.

-- Receita, % do total e margem bruta por categoria (2026)
with base as (
    select produtos.categoria,
           itens_pedido.quantidade * itens_pedido.preco_unitario * (1 - itens_pedido.desconto_pct) as receita,
           itens_pedido.quantidade * produtos.custo_unitario as custo
    from itens_pedido
    join produtos on itens_pedido.produto_id = produtos.produto_id
    join pedidos on itens_pedido.pedido_id  = pedidos.pedido_id
    where pedidos.status = 'entregue'
      and pedidos.data_pedido >= '2026-01-01'
)
select categoria,
       round(sum(receita), 2) as receita,
       round(100 * sum(receita) / sum(sum(receita)) over (), 1) as pct_receita,
       round(sum(receita) - sum(custo), 2) as margem_bruta,
       round(100 * (sum(receita) - sum(custo)) / sum(receita), 1) as margem_pct
from base
group by categoria
order by receita desc
;
-- Resposta: Eletrônicos faz 35,1% da receita, mas tem a menor margem (21,5%).
--           Casa fatura menos da metade e deixa quase a mesma margem em reais (R$ 223 mil x R$ 237 mil).
--           Beleza tem a maior margem (49,7%).
