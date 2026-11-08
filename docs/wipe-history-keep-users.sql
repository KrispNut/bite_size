-- Clears every month's activity and keeps only the users.
-- Run in the Supabase SQL editor (project bite-size).
-- Everything is copied into the private schema `shot_backup` first, so it can be restored.
begin;
create schema if not exists shot_backup;
create table shot_backup.all_sessions           as select * from public.sessions;
create table shot_backup.all_entries            as select * from public.entries;
create table shot_backup.all_extra_orders       as select * from public.extra_orders;
create table shot_backup.all_extra_order_shares as select * from public.extra_order_shares;
create table shot_backup.all_transactions       as select * from public.transactions;
create table shot_backup.all_pings              as select * from public.pings;

delete from public.transactions;
delete from public.extra_order_shares;
delete from public.extra_orders;
delete from public.entries;
delete from public.pings;
delete from public.sessions;
commit;

-- expect: 0 0 0 0 0 and users = 3
select (select count(*) from public.sessions)     sessions,
       (select count(*) from public.entries)      entries,
       (select count(*) from public.extra_orders) shared_meals,
       (select count(*) from public.pings)        pings,
       (select count(*) from public.transactions) transactions,
       (select count(*) from public.users)        users;

-- Once you're sure you don't need it back:
-- drop schema shot_backup cascade;
