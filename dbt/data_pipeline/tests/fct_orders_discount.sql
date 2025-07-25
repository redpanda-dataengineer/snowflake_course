select *
from {{ref('dct_orders')}}
where item_discount_amount > 0