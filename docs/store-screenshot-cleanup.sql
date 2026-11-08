-- Restores the Bite Size database after the store-screenshot dummy data
-- (2026-10-19). Safe to run once; it reverses exactly what was added.
-- October 2026 had ZERO sessions before (recorded in shot_backup.meta), so
-- every October session is dummy data.
begin;

-- 1. Remove everything hanging off the dummy October sessions.
delete from public.transactions where session_id like '%2026-10-%';
delete from public.extra_orders where session_id like '%2026-10-%';   -- shares cascade
delete from public.entries where session_id like '%2026-10-%';
delete from public.sessions where id like '%2026-10-%';

-- 2. Remove the 11 dummy users (anything still referencing them cascades).
delete from public.transactions
 where from_id in (select id from public.users where email like '%@shot.bitesize.invalid')
    or to_id   in (select id from public.users where email like '%@shot.bitesize.invalid');
delete from public.users where email like '%@shot.bitesize.invalid';

-- 3. Restore the three real users' names and roles exactly.
update public.users u
   set name = b.name, role = b.role, is_ping_target = b.is_ping_target, is_active = b.is_active
  from shot_backup.users b
 where b.id = u.id;

commit;

-- 4. Verify, then drop the backup.
select u.name, u.role,
       (u.name = b.name and u.role = b.role) as restored
  from public.users u join shot_backup.users b using (id)
 order by u.name;
-- expect 3 rows, all restored = true, and:
select (select count(*) from public.users)                                   as users_total,   -- 3
       (select count(*) from public.sessions where id like '%2026-10-%')     as oct_sessions; -- 0

drop schema shot_backup cascade;
