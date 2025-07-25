select * from {{ref('stg_tpch_orders')}} as orders
join {{ref('int_order_items_summary')}} as order_item_summary
    on orders.order_key = order_item_summary.order_key
order by order_date