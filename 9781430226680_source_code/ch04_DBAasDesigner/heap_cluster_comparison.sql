-- This script can be used for testing the code and results outlined in the section called "Heaps of Trouble".
-- Melanie Caffrey - November 29, 2009


drop table t_tables;


drop table t_indexes;


drop table users_tables;


drop table users_indexes;


drop cluster user_items_cluster_btree;


drop table users_tables_heap;


drop table users_indexes_heap;


create cluster user_items_cluster_btree (
               table_name varchar2 (30)) size 1024;


create index user_items_idx
    on cluster user_items_cluster_btree;


create table t_tables
    (table_name varchar2(30), owner varchar2(30));


create table t_indexes
    (index_name varchar2(30), index_owner varchar2(30), table_name varchar2(30),
     table_owner varchar2(30));


create table users_tables
    (table_name varchar2(30), owner varchar2(30))
     cluster user_items_cluster_btree(table_name);


create table users_indexes
    (index_name varchar2(30), index_owner varchar2(30), table_name varchar2(30),
     table_owner varchar2(30))
    cluster user_items_cluster_btree(table_name);


create table users_tables_heap
    (table_name varchar2(30), owner varchar2(30));


create table users_indexes_heap
    (index_name varchar2(30), index_owner varchar2(30), table_name varchar2(30),
     table_owner varchar2(30));


create index users_tables_tablename_idx on users_tables_heap(table_name);


create index users_indexes_tablename_idx on users_indexes_heap(table_name);


insert into t_tables (table_name, owner)
    select table_name,
           owner
      from dba_tables;


insert into t_indexes( index_name, index_owner, 
                       table_name, table_owner)
    select index_name,
           owner,
           table_name,
           table_owner
      from dba_indexes
     where (table_name, table_owner) in
           (select table_name, table_owner from t_tables)
   order by dbms_random.random;


insert into users_tables (table_name, owner)
    select table_name,
           owner
      from t_tables;


insert into users_indexes (index_name, index_owner,
                           table_name, table_owner)
    select index_name,
           index_owner,
           table_name,
           table_owner
      from t_indexes
     where (table_name, table_owner) in 
           (select table_name, table_owner from users_tables)
   order by dbms_random.random;


insert into users_tables_heap (table_name, owner)
    select table_name,
           owner
      from t_tables;


insert into users_indexes_heap (index_name, index_owner,
                                table_name, table_owner)
    select index_name,
           index_owner,
           table_name,
           table_owner
      from t_indexes
     where (table_name, table_owner) in 
           (select table_name, table_owner from users_tables_heap)
   order by dbms_random.random;


commit;


analyze cluster user_items_cluster_btree compute statistics;


exec dbms_stats.gather_table_stats( user, 'USERS_TABLES',
   method_opt => 'for all indexed columns', estimate_percent => 100 );


exec dbms_stats.gather_table_stats( user, 'USERS_INDEXES',
   method_opt => 'for all indexed columns', estimate_percent => 100 );


exec dbms_stats.gather_table_stats( user, 'USERS_TABLES_HEAP',
   method_opt => 'for all indexed columns', estimate_percent => 100 );


exec dbms_stats.gather_table_stats( user, 'USERS_INDEXES_HEAP',
   method_opt => 'for all indexed columns', estimate_percent => 100 );


alter system flush buffer_cache;


alter session set sql_trace=true;


-- The below methodology of setting a session variable can generally only be used with SQL*Plus.


variable BIND1 varchar2(30)


exec :BIND1 := 'WFS_FEATURETYPE$'


select a.table_name, b.index_name /* CLUSTER_TEST */
      from users_tables a, users_indexes b
     where a.table_name  = b.table_name
       and a.owner       = b.table_owner
       and a.table_name  = :BIND1
    order by a.table_name, b.index_name;


select a.table_name, b.index_name /* HEAP_TEST */
      from users_tables_heap a, users_indexes_heap b
     where a.table_name  = b.table_name
       and a.owner       = b.table_owner
       and a.table_name  = :BIND1
    order by a.table_name, b.index_name;


alter session set sql_trace=false;