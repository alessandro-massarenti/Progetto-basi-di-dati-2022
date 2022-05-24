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
