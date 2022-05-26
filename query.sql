-- stampa la fattura di un cliente
with intestazione_fattura as(
select fattura.*, p.nome, p.cognome from fattura
join cliente c on c.persona = fattura.cliente
join persona p on c.persona = p.cf
where cliente = 'GLLGNN81A54G224W'),

spese as(
    select sosta.fattura,
           i.cliente,
           'sosta' as tipo,
           ROUND((tstzrange_subdiff(sosta.partenza,sosta.arrivo)/86400.0 * m.prezzogiorno)::numeric,2)  as prezzo
    from sosta
    join imbarcazione i on i.id = sosta.imbarcazione
    join molo m on sosta.molo = m.id
    where partenza != 'infinity'

    union all
    select consumo.fattura,
           consumo.cliente,
           'consumo' as tipo,
           ROUND((consumo.quantita * a2.prezzounitario)::numeric,2) as prezzo
    from consumo
    join fornitura f on consumo.allacciamento = f.allacciamento
    join allacciamento a2 on consumo.allacciamento = a2.nome
)

select distinct id, scadenza, pagato, nome, cognome, intestazione_fattura.cliente, tipo, prezzo
from spese, intestazione_fattura
where spese.fattura = intestazione_fattura.id;
-----------------------------------------------------

--controllo dei posti disponibili per una certa imbarcazione
select distinct molo.id as id_molo,molo.prezzogiorno,molo.profonditaminima,molo.larghezza,molo.lunghezza, molo.occupato
from molo,imbarcazione
where occupato=false
and molo.larghezza > imbarcazione.larghezza
and molo.profonditaminima > imbarcazione.pescaggio
and molo.lunghezza > imbarcazione.loa
and imbarcazione.mmsi = '8836340'
order by prezzogiorno
limit 5;
-----------------------------------------------------

--Conteggia le soste di un'imbarcazione
select count(imbarcazione) as qt_soste, imbarcazione.nome, mmsi,p.nome as nome_proprietario,p.cognome as cognome_proprietario
from sosta
join imbarcazione on sosta.imbarcazione = imbarcazione.id
join cliente c on imbarcazione.cliente = c.persona
join persona p on c.persona = p.cf
group by sosta.imbarcazione, imbarcazione.nome, mmsi,p.nome,p.cognome
order by qt_soste desc;

--Ritorna i clienti con più di 2 di prenotazioni che iniziano nel quinquiennio 2020->2025
--Questa query è utile in ottica di creazione di uno sconto per chi fa molte prenotazioni
select count(cliente) as conteggio, p.nome, p.cognome, c.persona
from prenotazione
join cliente c on prenotazione.cliente = c.id
join persona p on c.persona = p.cf
where prevarrivo between '01-01-2020' and '12-31-2025'
group by c.persona,p.nome, p.cognome
having count(cliente) >= 2
order by conteggio desc;

--Calcola consumi del marina nel mese indicato
select allacciamento,
       sum(quantita) as quantita_consumata,
       a.unitamisura, a.prezzounitario,
       sum(quantita) * a.prezzounitario as totale_bollette
from consumo
join allacciamento a on consumo.allacciamento = a.nome
where inizio between '05-01-2020' and '05-31-2025'
group by allacciamento, unitamisura, prezzounitario;



--
--Altro
--

--Calcolo fattura
with conteggio_sosta as(
with fatture_giorni as(
with tempo_sosta as(
select tstzrange_subdiff(case when sosta.partenza = 'infinity' then '' else sosta.partenza end,sosta.arrivo)/86400.0 as giorni,fattura from sosta)

select distinct sosta.fattura, tempo_sosta.giorni * m.prezzogiorno as totale_euro,tempo_sosta.giorni as giorni_sosta
from sosta
join molo m on m.id = sosta.molo
join tempo_sosta on tempo_sosta.fattura = sosta.fattura
where sosta.fattura is not null)

--select * from fatture_giorni
select fattura,sum(totale_euro) as totale_euro, sum(giorni_sosta) as giorni_soste from fatture_giorni group by (fattura)
)

select id,cliente,scadenza,ROUND((totale_euro)::numeric,2) as totale_euro,round(conteggio_sosta.giorni_soste::numeric,2)as giorni_soste,pagato
from fattura
join conteggio_sosta on conteggio_sosta.fattura = fattura.id;
-- select tstzrange_subdiff(case when sosta.partenza = 'infinity' then now() else sosta.partenza end,sosta.arrivo)/86400.0,fattura from sosta;
------------------------------------------------------------------------------------------------