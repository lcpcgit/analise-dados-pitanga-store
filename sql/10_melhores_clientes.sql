-- =====================================================
-- Situação 10: Os melhores clientes
-- Pedido: lista dos melhores clientes para enviar um brinde de fim de ano.
-- Regras: receita = quantidade * preco_unitario * (1 - desconto_pct),
--         só pedidos com status 'entregue', frete fora.
-- Ferramenta: MySQL 8
-- =====================================================

with receita_produtos as (
select pedido_id, round(sum(preco_unitario * quantidade * (1- desconto_pct)), 2) as receita 
from itens_pedido
group by pedido_id
)
,
receita_pedidos as (
select pedidos.* , receita_produtos.receita, clientes.nome, clientes.email , clientes.cidade, clientes.estado, clientes.data_cadastro , clientes.canal_aquisicao
from pedidos
join clientes 
on pedidos.cliente_id = clientes.cliente_id
join receita_produtos 
on pedidos.pedido_id = receita_produtos.pedido_id
where pedidos.status = 'entregue' and pedidos.data_pedido >= '2026-01-01'

)
select nome , email , cidade , estado , data_cadastro , canal_aquisicao,
		count(cliente_id) as compras_realizadas,
        round(sum(receita), 2) as receita
from receita_pedidos
group by cliente_id, nome, email, cidade, estado, data_cadastro, canal_aquisicao
having compras_realizadas >= 3
order by receita desc 
limit 50 
;
-- Definição usada: clientes com 3 ou mais pedidos entregues em 2026 (jan–out),
-- ordenados pelo valor gasto no período. 1.143 clientes atendem o critério.
-- Resposta: os 3 primeiros são Letícia Nascimento (18 compras, R$ 5.127,12),
--           Bruno Martins (7 compras, R$ 4.967,80) e Rodrigo Martins (7 compras, R$ 4.903,90).
