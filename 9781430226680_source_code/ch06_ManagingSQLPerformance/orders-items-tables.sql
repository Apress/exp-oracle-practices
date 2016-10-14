drop table items ;
drop table orders ;

create table orders 
        (
         order_no        		integer    constraint orders_pk primary key	
        ,cust_no         		integer	
        ,order_date      		date not null
        ,total_order_price     	number(7,2)
        ,deliver_date    		date          
        ,deliver_time    		varchar2(7)
        ,payment_method 		varchar2(2)	not null 
        ,emp_no         		integer 	
        ,deliver_name   		varchar2(35)
        ,gift_message   		varchar2(100)
         );        

create index orders_orddt_idx on orders (order_date) ;

create table items 
        (
         order_no       		integer 
        ,product_id     		integer 	
        ,quantity       		number(4,0)
        ,item_price          	number(7,2)
		,total_order_item_price	number(9,2)
        ,constraint items_pk primary key (order_no ,product_id)
        );

create index items_ordno_fk on items (order_no) ;

prompt Inserting records into customer2, orders, items
set echo off

@orders-data

@items-data

set echo on

exec dbms_stats.gather_table_stats(user,'orders',method_opt=>'FOR ALL COLUMNS SIZE 1',cascade=>TRUE)
exec dbms_stats.gather_table_stats(user,'items',method_opt=>'FOR ALL COLUMNS SIZE 1',cascade=>TRUE)
