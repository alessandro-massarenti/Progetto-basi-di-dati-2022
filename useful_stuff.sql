select * from sosta;

create view libero_ora as
(
select *
from molo
where occupato = false);


-- robba2
select id, loa,larghezza,pescaggio
from imbarcazione
where id NOT IN (SELECT imbarcazione from sosta)
order by loa,larghezza,pescaggio
limit 1;

--      robba
WITH barca as (select id, loa,larghezza,pescaggio
from imbarcazione
where id NOT IN (SELECT imbarcazione from sosta)
order by loa,larghezza,pescaggio
limit 1)

select libero_ora.*
from libero_ora, barca
where lunghezza > (select loa from barca)
and  libero_ora.larghezza > (select larghezza from barca)
and profonditaminima > (select pescaggio from barca)
and libero_ora.id not in (SELECT molo from sosta)
order by lunghezza,libero_ora.larghezza,profonditaminima;

with o as(select molo from molo_occupato)

UPDATE molo
SET occupato = true
WHERE molo.id in (select molo from o) ;




select * from imbarcazione;

select * from libero_ora;




---Cose per sistemare il db

select from sosta,imbarcazione where imbarcazione.id = sosta.imbarcazione;



with o as(select molo from molo_occupato)

UPDATE molo
SET occupato = true
WHERE molo.id in (select molo from o) ;

--Trovare un cliente che non ha fatto soste

with s as (select imbarcazione from sosta)

select * from imbarcazione where id in (select s.imbarcazione from s);

with i as (select cliente from imbarcazione)
select * from cliente where persona not in (select i.cliente from i);


with c as (select max(id) as max from cliente)

SELECT setval('cliente_id_seq', (select c.max from c), true);


select from sosta,imbarcazione where imbarcazione.id = sosta.imbarcazione;



with o as(select molo from molo_occupato_rid)

UPDATE molo
SET occupato = true
WHERE molo.id in (select molo from o) ;

--Trovare un cliente che non ha fatto soste

with s as (select imbarcazione from sosta)

select * from imbarcazione where id in (select s.imbarcazione from s);

with i as (select cliente from imbarcazione)
select * from cliente
join persona p on p.cf = cliente.persona
where persona not in (select i.cliente from i) ;

select * from persona
where cf not in (select persona from cliente union distinct  select persona from addetto);

select persona from cliente union distinct  select persona from addetto;

with c as (select max(id) as max from cliente)

SELECT setval('cliente_id_seq', (select c.max from c), true);

select * from libero_adesso;



with a as (SELECT molo from sosta union distinct select id as molo from Molo
WHERE molo NOT IN (select molo from molo_occupato))

select * from a,sosta where a.molo = sosta.molo;

with a as (SELECT id from molo where occupato=false)
select * from a left join sosta on a.id;

select * from libero_adesso_rid;


select id as molo , libero_da,libero_fino_a, molo.occupato as occupato_ora from molo left join libero_adesso_rid on libero_adesso_rid.molo = molo.id;

select * from moli_liberi;

with o as(select molo from molo_occupato_rid)

UPDATE molo
SET occupato = true
WHERE molo.id in (select molo from o) ;



-- Views utili
-- Le views con *_rid sono views che utilizzano solamente la ridondanza per calcolare le risposte

create view molo_occupato_rid as
select molo, arrivo, partenza
from sosta
where partenza > now() AT TIME ZONE 'Europe/Rome'
and arrivo < now() AT TIME ZONE 'Europe/Rome';

create view molo_occupato as
select id from Molo
where occupato = true;

create view molo_libero_fino_a_rid as
SELECT molo, arrivo as libero_fino_a
FROM sosta
WHERE molo NOT IN (select molo from molo_occupato_rid)
  and arrivo > now() AT TIME ZONE 'Europe/Rome';

create view molo_libero_da_rid as
SELECT molo, arrivo as libero_da
FROM sosta
WHERE molo NOT IN (select molo from molo_occupato_rid)
  and partenza < now() AT TIME ZONE 'Europe/Rome';

create view libero_adesso_rid as
select coalesce(molo_libero_da_rid.molo, mlfa.molo) as molo,
       max(molo_libero_da_rid.libero_da)            as libero_da,
       min(mlfa.libero_fino_a)                  as libero_fino_a
from molo_libero_da_rid
full join molo_libero_fino_a_rid mlfa on molo_libero_da_rid.molo = mlfa.molo
group by (molo_libero_da_rid.molo, mlfa.molo);

create view moli_liberi as
select id as molo , libero_da,libero_fino_a, molo.occupato as occupato_ora
from molo left join libero_adesso_rid on libero_adesso_rid.molo = molo.id;
