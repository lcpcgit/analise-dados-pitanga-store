-- =====================================================
-- Situação 6: Curva ABC de produtos
-- Pedido: classificar os produtos em A, B e C pela receita de 2026, para Compras/Estoque.
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

with receita_produto as (
    select produtos.produto_id,
           produtos.nome_produto,
           sum(itens_pedido.quantidade * itens_pedido.preco_unitario * (1 - itens_pedido.desconto_pct)) as receita
    from itens_pedido
    join pedidos  on pedidos.pedido_id   = itens_pedido.pedido_id
    join produtos on produtos.produto_id = itens_pedido.produto_id
    where pedidos.status = 'entregue'
      and pedidos.data_pedido >= '2026-01-01'
    group by produtos.produto_id, produtos.nome_produto
),
acumulado as (
    select *,
           sum(receita) over (order by receita desc rows unbounded preceding)
             / sum(receita) over () as pct_acum
    from receita_produto
),
curva_abc as (
    select *,
           case when pct_acum <= 0.80 then 'A'
                when pct_acum <= 0.95 then 'B'
                else 'C'
           end as classe
    from acumulado
)
select nome_produto,
       round(receita, 2)        as receita,
       round(100 * pct_acum, 1) as pct_acumulada,
       classe
from curva_abc
order by receita desc;
-- Regra: até 80% da receita acumulada = A; até 95% = B; o resto = C.
-- Resposta: A = 25 produtos (79,1% da receita), B = 15 (15,3%), C = 14 (5,6%).
--           A regra "20/80" não vale aqui: com 54 produtos e preços de R$ 30 a R$ 1.300,
--           são 46% dos produtos para chegar a 80% da receita.
