-- Tabelle inizializzate rispettando i riferimenti

-- Molo
-- Ha una chiave
DROP TABLE IF EXISTS Molo;
CREATE TABLE Molo
(
    id               SERIAL,
    occupato         BOOLEAN,
    profonditaMinima DOUBLE PRECISION,
    larghezza        DOUBLE PRECISION,
    lunghezza        DOUBLE PRECISION,
    prezzoGiorno     DECIMAL,
    PRIMARY KEY (id)
);

-- Servizio
-- Ha una chiave
DROP TABLE IF EXISTS Servizio;
CREATE TABLE Servizio
(
    nome VARCHAR,
    PRIMARY KEY (nome)
);

-- Persona
-- Ha una chiave
DROP TABLE IF EXISTS Persona;
CREATE TABLE Persona
(
    CF          CHAR(16) NOT NULL,
    dataNascita DATE     NOT NULL,
    nome        VARCHAR  NOT NULL,
    cognome     VARCHAR  NOT NULL,
    PRIMARY KEY (CF)
);

-- Addetto
-- Ha due chiavi
DROP TABLE IF EXISTS Addetto;
CREATE TABLE Addetto
(
    persona         CHAR(16) NOT NULL references Persona (CF),
    servizio        VARCHAR  NOT NULL,
    inizioContratto DATE     NOT NULL,
    fineContratto   DATE,

    PRIMARY KEY (persona),
    UNIQUE (servizio, inizioContratto)
);

-- Cliente
-- ha due chiavi
DROP TABLE IF EXISTS Cliente;
CREATE TABLE Cliente
(
    persona         CHAR(16) NOT NULL references Persona (CF),
    id              SERIAL,
    cittadinanza    VARCHAR  NOT NULL,
    residenza       VARCHAR  NOT NULL,
    quantitaSoste   INT,
    scontoPersonale DOUBLE PRECISION,
    PRIMARY KEY (persona),
    UNIQUE (id)
);

-- Allacciamento
-- ha una chiave
DROP TABLE IF EXISTS Allacciamento;
CREATE TABLE Allacciamento
(
    nome           VARCHAR(255),
    prezzoUnitario DOUBLE PRECISION,
    unitaMisura    VARCHAR(255),
    PRIMARY KEY (nome)
);

-- Fornitura
-- ha due chiavi
DROP TABLE IF EXISTS PeriodoApertura;
CREATE TABLE PeriodoApertura
(
    id       SERIAL  NOT NULL,
    giorno   VARCHAR NOT NULL,
    apertura TIME    NOT NULL,
    chiusura TIME    NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (giorno, apertura, chiusura)
);

-- Imbarcazione,
-- Ha due chiavi
DROP TABLE IF EXISTS Imbarcazione;
CREATE TABLE Imbarcazione
(
    MMSI         CHAR(9)          NOT NULL,
    id           SERIAL,
    cliente      CHAR(16) references Cliente (persona),
    bandiera     VARCHAR          NOT NULL,
    nomeCapitano VARCHAR          NOT NULL,
    nPostiLetto  INT              NOT NULL,
    nome         VARCHAR,
    pescaggio    DOUBLE PRECISION NOT NULL,
    larghezza    DOUBLE PRECISION NOT NULL,
    LOA          DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (MMSI),
    UNIQUE (id)
);

-- Fattura
-- Ha due chiavi
DROP TABLE IF EXISTS Fattura;
CREATE TABLE Fattura
(
    id       SERIAL,
    cliente  CHAR(16)  not null references Cliente (persona),
    scadenza date      not null,
    pagato   timestamp not null,
    primary key (id),
    unique (cliente, scadenza)
);

-- Sosta
-- Ha due chiavi
-- tabella sosta, non permette la sovrapposizione di soste in uguali orari
-- se la barca è già in un altra sosta oppure se il molo è già occupato
DROP TABLE IF EXISTS Sosta;
CREATE TABLE Sosta
(
    imbarcazione int         NOT NULL references Imbarcazione (id),
    molo         int         NOT NULL references Molo (id),
    arrivo       TIMESTAMPTZ NOT NULL,
    id           SERIAL,
    partenza     TIMESTAMPTZ NOT NULL default 'infinity',
    fattura      INT references Fattura (id),
    CHECK ( arrivo < partenza ),
    CONSTRAINT molo_gia_occupato EXCLUDE USING gist (
        int8range(molo, molo, '[]') WITH =,
        box(
                point(extract(epoch FROM arrivo at time zone 'UTC'), extract(epoch FROM arrivo at time zone 'UTC')),
                point(extract(epoch FROM partenza at time zone 'UTC'), extract(epoch FROM partenza at time zone 'UTC'))
            ) WITH &&
        ),
    CONSTRAINT imbarcazione_gia_in_molo EXCLUDE USING gist (
        int8range(imbarcazione, imbarcazione, '[]') WITH =,
        box(
                point(extract(epoch FROM arrivo at time zone 'UTC'), extract(epoch FROM arrivo at time zone 'UTC')),
                point(extract(epoch FROM partenza at time zone 'UTC'), extract(epoch FROM partenza at time zone 'UTC'))
            ) WITH &&
        ),
    PRIMARY KEY (molo, imbarcazione, arrivo),
    UNIQUE (id)
);

-- Prenotazione
-- Ha una chiave
DROP TABLE IF EXISTS Prenotazione;
CREATE TABLE Prenotazione
(
    cliente      INTEGER     NOT NULL references Cliente (id),
    molo         INTEGER     NOT NULL references Molo (id),
    prevArrivo   TIMESTAMPTZ NOT NULL,
    prevPartenza TIMESTAMPTZ NOT NULL default 'infinity',
    sosta        INT references sosta (id),
    CHECK ( prevArrivo < prevPartenza ),
    CONSTRAINT molo_gia_impegnato EXCLUDE USING GIST (
        int8range(molo, molo, '[]') WITH =,
        box(
                point(extract(epoch FROM prevArrivo at time zone 'UTC'),
                      extract(epoch FROM prevArrivo at time zone 'UTC')),
                point(extract(epoch FROM prevPartenza at time zone 'UTC'),
                      extract(epoch FROM prevPartenza at time zone 'UTC'))
            ) WITH &&
        ),
    CONSTRAINT imbarcazione_gia_prenotato_in_molo EXCLUDE USING GIST (
        int8range(cliente, cliente, '[]') WITH =,
        box(
                point(extract(epoch FROM prevArrivo at time zone 'UTC'),
                      extract(epoch FROM prevArrivo at time zone 'UTC')),
                point(extract(epoch FROM prevPartenza at time zone 'UTC'),
                      extract(epoch FROM prevPartenza at time zone 'UTC'))
            ) WITH &&
        ),
    PRIMARY KEY (molo, cliente, prevArrivo)
);

-- Fornitura
-- ha una chiave
DROP TABLE IF EXISTS Fornitura;
CREATE TABLE Fornitura
(
    allacciamento VARCHAR NOT NULL references Allacciamento (nome),
    molo          INT     NOT NULL
        constraint fornitura_molo__fk
            references Molo (id),
    PRIMARY KEY (allacciamento, molo)
);


-- AperturaServizio
-- ha una chiave
DROP TABLE IF EXISTS AperturaServizio;
CREATE TABLE AperturaServizio
(
    servizio        VARCHAR NOT NULL references Servizio (nome),
    periodoApertura INT     NOT NULL references PeriodoApertura (id),
    PRIMARY KEY (servizio, periodoApertura)
);

-- Consumo
-- ha una chiave
DROP TABLE IF EXISTS Consumo;
CREATE TABLE Consumo
(
    cliente       CHAR(16) references Cliente (persona),
    allacciamento varchar references Allacciamento (nome),
    inizio        timestamp,
    fine          int,
    quantita      decimal,
    fattura       int references Fattura (id),
    primary key (cliente, allacciamento, inizio)
);

-- Views
create view molo_occupato as
select molo, arrivo, partenza
from sosta
where partenza > now() AT TIME ZONE 'Europe/Rome'
  and arrivo < now() AT TIME ZONE 'Europe/Rome';

create view molo_libero_fino_a as
SELECT molo, arrivo as libero_fino_a
FROM sosta
WHERE molo NOT IN (select molo from molo_occupato)
  and arrivo > now() AT TIME ZONE 'Europe/Rome';

create view molo_libero_da as
SELECT molo, arrivo as libero_da
FROM sosta
WHERE molo NOT IN (select molo from molo_occupato)
  and partenza < now() AT TIME ZONE 'Europe/Rome';

create view libero_adesso as
select coalesce(molo_libero_da.molo, mlfa.molo) as molo,
       max(molo_libero_da.libero_da)            as libero_da,
       min(mlfa.libero_fino_a)                  as libero_fino_a
from molo_libero_da
         full join molo_libero_fino_a mlfa on molo_libero_da.molo = mlfa.molo
group by (molo_libero_da.molo, mlfa.molo);

-- Dati
----------------------------------------------------------------

insert into persona (cf, datanascita, nome, cognome)
values ('GLLGNN81A54G224W', '1981-01-14', 'Giovanna', 'Galli'),
       ('BRNRNS61D64G224W', '1961-04-24', 'Ortensia', 'Bernardi'),
       ('FRIFME76P50G224A', '1976-09-10', 'Eufemia', 'Fiore'),
       ('PRSFNZ86H17G224I', '1986-06-17', 'Fiorenzo', 'Parisi'),
       ('GTTMNL80D23G224S', '1980-04-23', 'Emanuel', 'Gatti'),
       ('FRIMRV60S67G224G', '1960-11-27', 'Marieva', 'Fiore'),
       ('BTTDPE87L24G224C', '1987-07-24', 'Edipo', 'Battaglia'),
       ('RSSCTN98M28G224B', '1998-08-28', 'Costanzo', 'Russo'),
       ('MTATSE95R28G224U', '1995-10-28', 'Teseo', 'Amato'),
       ('MRTSVN62M13G224Z', '1962-08-13', 'Silvano', 'Moretti'),
       ('FNTCGL78B08G224E', '1978-02-08', 'Caligola', 'Fontana'),
       ('MRTSRT91H55G224R', '1991-06-15', 'Sarita', 'Martinelli'),
       ('RZZPLP63L70G224M', '1963-07-30', 'Penelope', 'Rizzo'),
       ('SNNMRV74S45G224C', '1974-11-05', 'Marieva', 'Sanna'),
       ('MRNVNN00C58G224F', '2000-03-18', 'Vienna', 'Marini'),
       ('CTTTMS64B16G224U', '1964-02-16', 'Tommaso', 'Cattaneo'),
       ('CLMMNL00C10G224D', '2000-03-10', 'Manuele', 'Colombo'),
       ('LNELIA78E69G224J', '1978-05-29', 'Lia', 'Leone'),
       ('BNCRLA58A25G224U', '1958-01-25', 'Raoul', 'Bianco'),
       ('MRNMRP81S70G224W', '1981-11-30', 'Mariapia', 'Marino'),
       ('PLLGGR91P14G224J', '1991-09-14', 'Gregorio', 'Pellegrini'),
       ('BLLMRK80D29G224M', '1980-04-29', 'Mirko', 'Bellini'),
       ('MRCLRZ70B47G224O', '1970-02-07', 'Lucrezia', 'Marchetti'),
       ('FRILTT02A44G224C', '2002-01-04', 'Loretta', 'Fiore'),
       ('BNCCRI03T58G224W', '2003-12-18', 'Cira', 'Bianchi'),
       ('MSSLRZ73M57G224S', '1973-08-17', 'Lucrezia', 'Messina'),
       ('GLLSNA90A05G224V', '1990-01-05', 'Ausonio', 'Gallo'),
       ('BNDRMO78P17G224H', '1978-09-17', 'Romeo', 'Benedetti'),
       ('GRCMRP69L58G224Q', '1969-07-18', 'Mariapia', 'Greco'),
       ('BRNNIO80S51G224L', '1980-11-11', 'Ione', 'Barone'),
       ('VTLSSA77C53G224W', '1977-03-13', 'Assia', 'Vitali'),
       ('GRCBRM70T30G224L', '1970-12-30', 'Abramo', 'Greco'),
       ('RSSCRS82B05G224S', '1982-02-05', 'Cleros', 'Rossetti'),
       ('BLLLZR70E10G224M', '1970-05-10', 'Lazzaro', 'Bellini'),
       ('RZZMDE93B09G224Q', '1993-02-09', 'Emidio', 'Rizzo'),
       ('MRCLRD67S19G224K', '1967-11-19', 'Leonardo', 'Marchetti'),
       ('RGGLSI91D52G224R', '1991-04-12', 'Lisa', 'Ruggiero'),
       ('SNNBBN90R60G224N', '1990-10-20', 'Bibiana', 'Sanna'),
       ('MRNRMN65T28G224Y', '1965-12-28', 'Erminio', 'Marini'),
       ('PGNNRE69C59G224B', '1969-03-19', 'Neri', 'Pagano'),
       ('RVIMNL64L17G224Y', '1964-07-17', 'Emanuel', 'Riva'),
       ('PLMCSP65T61G224T', '1965-12-21', 'Cassiopea', 'Palmieri'),
       ('BNDFTN91A57G224P', '1991-01-17', 'Fortunata', 'Benedetti'),
       ('TSTMRA66L51G224O', '1966-07-11', 'Maria', 'Testa'),
       ('FRRSOE71T24G224G', '1971-12-24', 'Osea', 'Ferrari'),
       ('MRNWTR02E27G224F', '2002-05-27', 'Walter', 'Marino'),
       ('RCCMNT86T55G224P', '1986-12-15', 'Marianita', 'Ricci'),
       ('CRSGSM80R65G224C', '1980-10-25', 'Gelsomina', 'Caruso'),
       ('VTLNIO93T50G224P', '1993-12-10', 'Ione', 'Vitali'),
       ('RMNRSL64B50G224X', '1964-02-10', 'Ursula', 'Romano'),
       ('MZZMLE63T61G224Q', '1963-12-21', 'Emilia', 'Mazza'),
       ('CTTCDV88B42G224W', '1988-02-02', 'Clodovea', 'Cattaneo'),
       ('RSSCLE71T48G224V', '1971-12-08', 'Clea', 'Rossetti'),
       ('RGGDRH69S53G224N', '1969-11-13', 'Deborah', 'Ruggiero'),
       ('RNLCST86R49G224I', '1986-10-09', 'Cristyn', 'Rinaldi'),
       ('CSTRNR76T01G224U', '1976-12-01', 'Raniero', 'Costantini'),
       ('TSTLRS88E08G224E', '1988-05-08', 'Loris', 'Testa'),
       ('FRRFBN60A08G224J', '1960-01-08', 'Fabiano', 'Ferrari'),
       ('BTTCCT91C61G224K', '1991-03-21', 'Concetta', 'Battaglia'),
       ('GRCLRS80T10G224B', '1980-12-10', 'Loris', 'Greco'),
       ('SLAPBL72M16G224V', '1972-08-16', 'Pablo', 'Sala'),
       ('SLALSI78P55G224T', '1978-09-15', 'Lisa', 'Sala'),
       ('CSTQMD68H18G224A', '1968-06-18', 'Quasimodo', 'Costantini'),
       ('SPSLRA03M70G224G', '2003-08-30', 'Laura', 'Esposito'),
       ('CLMSBL90S63G224B', '1990-11-23', 'Isabel', 'Colombo'),
       ('RVIQMD76P27G224W', '1976-09-27', 'Quasimodo', 'Riva'),
       ('SRTLDN77L45G224L', '1977-07-05', 'Loredana', 'Sartori'),
       ('SLVRST98P02G224K', '1998-09-02', 'Oreste', 'Silvestri'),
       ('VTLMFR77R14G224J', '1977-10-14', 'Manfredi', 'Vitali'),
       ('DMCMHL84H59G224W', '1984-06-19', 'Michele', 'Damico'),
       ('MRNLRT73D29G224J', '1973-04-29', 'Alberto', 'Mariani'),
       ('NREFLC82P55G224R', '1982-09-15', 'Felicia', 'Neri'),
       ('CSTLIA92B43G224T', '1992-02-03', 'Lia', 'Costa'),
       ('FRRSSA82M64G224O', '1982-08-24', 'Assia', 'Ferrara'),
       ('NGRKST92P54G224H', '1992-09-14', 'Kristel', 'Negri'),
       ('FRRDMS98C30G224H', '1998-03-30', 'Demis', 'Ferrara'),
       ('MRTRMO92P30G224U', '1992-09-30', 'Romeo', 'Martini'),
       ('MZZMRN88T01G224G', '1988-12-01', 'Mariano', 'Mazza'),
       ('LMBMRM81H43G224O', '1981-06-03', 'Miriam', 'Lombardo'),
       ('NGRJRA92M16G224A', '1992-08-16', 'Jari', 'Negri'),
       ('CTTGNT80M17G224E', '1980-08-17', 'Giacinto', 'Cattaneo'),
       ('RSSMLE95S60G224V', '1995-11-20', 'Emilia', 'Rossi'),
       ('MRNFLC70P28G224Z', '1970-09-28', 'Folco', 'Marini'),
       ('BRNSRN65M66G224B', '1965-08-26', 'Soriana', 'Bernardi'),
       ('MZZNIO74A46G224T', '1974-01-06', 'Ione', 'Mazza'),
       ('VTLPCR58L61G224T', '1958-07-21', 'Piccarda', 'Vitale'),
       ('FRRZLD79H51G224K', '1979-06-11', 'Zelida', 'Ferraro'),
       ('RNLGLN97R10G224E', '1997-10-10', 'Giuliano', 'Rinaldi'),
       ('GRCGLN70S08G224A', '1970-11-08', 'Giuliano', 'Greco'),
       ('BLLPRM92A25G224H', '1992-01-25', 'Priamo', 'Bellini'),
       ('SRRMKA79P69G224Z', '1979-09-29', 'Maika', 'Sorrentino'),
       ('PLMNHO67T14G224O', '1967-12-14', 'Noah', 'Palumbo'),
       ('PRSKRA02T08G224E', '2002-12-08', 'Akira', 'Piras'),
       ('VTLGMN02L23G224E', '2002-07-23', 'Germano', 'Vitale'),
       ('LNGVLD69D14G224T', '1969-04-14', 'Valdo', 'Longo'),
       ('FRNMRV86M71G224H', '1986-08-31', 'Marieva', 'Farina'),
       ('NREMRN91R23G224K', '1991-10-23', 'Marino', 'Neri'),
       ('MZZMDA61M03G224S', '1961-08-03', 'Amedeo', 'Mazza'),
       ('MRTMRM92T65G224D', '1992-12-25', 'Miriam', 'Martinelli'),
       ('BRNLGU61S23G224M', '1961-11-23', 'Luigi', 'Bruno');

insert into public.cliente (persona, id, cittadinanza, residenza, quantitasoste, scontopersonale)
values  ('GLLGNN81A54G224W', 2, 'ita', 'Napoli', null, null),
        ('SPSLRA03M70G224G', 31, 'ita', 'Napoli', null, null),
        ('BRNRNS61D64G224W', 32, 'ita', 'Padova', null, null),
        ('FRIFME76P50G224A', 33, 'ita', 'Padova', null, null),
        ('PRSFNZ86H17G224I', 34, 'ita', 'Venezia', null, null),
        ('GTTMNL80D23G224S', 35, 'ita', 'Padova', null, null),
        ('FRIMRV60S67G224G', 36, 'ita', 'Venezia', null, null),
        ('BTTDPE87L24G224C', 37, 'ita', 'Venezia', null, null),
        ('RSSCTN98M28G224B', 38, 'ita', 'Padova', null, null),
        ('MTATSE95R28G224U', 39, 'ita', 'Napoli', null, null),
        ('MRTSVN62M13G224Z', 40, 'ita', 'Padova', null, null),
        ('FNTCGL78B08G224E', 41, 'ita', 'Roma', null, null),
        ('MRTSRT91H55G224R', 42, 'ita', 'Roma', null, null),
        ('RZZPLP63L70G224M', 43, 'ita', 'Padova', null, null),
        ('SNNMRV74S45G224C', 44, 'ita', 'Venezia', null, null),
        ('MRNVNN00C58G224F', 45, 'ita', 'Padova', null, null),
        ('CTTTMS64B16G224U', 46, 'ita', 'Padova', null, null),
        ('CLMMNL00C10G224D', 47, 'ita', 'Padova', null, null),
        ('LNELIA78E69G224J', 48, 'ita', 'Padova', null, null),
        ('BNCRLA58A25G224U', 49, 'ita', 'Venezia', null, null),
        ('MRNMRP81S70G224W', 50, 'ita', 'Napoli', null, null),
        ('PLLGGR91P14G224J', 51, 'ita', 'Roma', null, null),
        ('BLLMRK80D29G224M', 52, 'ita', 'Napoli', null, null),
        ('MRCLRZ70B47G224O', 53, 'ita', 'Venezia', null, null),
        ('FRILTT02A44G224C', 54, 'ita', 'Roma', null, null),
        ('BNCCRI03T58G224W', 55, 'ita', 'Venezia', null, null),
        ('MSSLRZ73M57G224S', 56, 'ita', 'Venezia', null, null),
        ('GRCMRP69L58G224Q', 57, 'ita', 'Roma', null, null),
        ('SLVRST98P02G224K', 58, 'ita', 'Roma', null, null),
        ('BNDRMO78P17G224H', 59, 'ita', 'Roma', null, null),
        ('GRCLRS80T10G224B', 60, 'ita', 'Roma', null, null);

UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 2
  AND imbarcazione = 1
  AND arrivo = '2022-05-13 14:07:34.567000 +00:00';
UPDATE sosta
SET partenza = '2022-09-13 14:07:45.045000 +00:00',
    fattura  = null
WHERE molo = 3
  AND imbarcazione = 2
  AND arrivo = '2022-05-13 14:07:43.412000 +00:00';
UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 4
  AND imbarcazione = 3
  AND arrivo = '2022-05-13 14:08:31.511000 +00:00';
UPDATE sosta
SET partenza = '2022-05-13 14:09:07.021000 +00:00',
    fattura  = null
WHERE molo = 1
  AND imbarcazione = 4
  AND arrivo = '2022-05-13 14:09:05.500000 +00:00';
UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 5
  AND imbarcazione = 5
  AND arrivo = '2022-05-13 14:09:14.724000 +00:00';
UPDATE sosta
SET partenza = '2022-07-13 14:09:33.949000 +00:00',
    fattura  = null
WHERE molo = 12
  AND imbarcazione = 6
  AND arrivo = '2022-05-13 14:09:32.154000 +00:00';
UPDATE sosta
SET partenza = '2022-09-13 14:09:44.057000 +00:00',
    fattura  = null
WHERE molo = 12
  AND imbarcazione = 7
  AND arrivo = '2022-08-13 14:09:40.042000 +00:00';
UPDATE sosta
SET partenza = '2022-11-13 14:09:55.211000 +00:00',
    fattura  = null
WHERE molo = 3
  AND imbarcazione = 8
  AND arrivo = '2022-10-13 14:09:52.883000 +00:00';
UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 6
  AND imbarcazione = 9
  AND arrivo = '2022-05-13 14:10:05.242000 +00:00';
UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 7
  AND imbarcazione = 10
  AND arrivo = '2022-05-13 14:10:09.739000 +00:00';
UPDATE sosta
SET partenza = 'infinity',
    fattura  = null
WHERE molo = 8
  AND imbarcazione = 11
  AND arrivo = '2022-05-13 14:10:12.938000 +00:00';
UPDATE sosta
SET partenza = '2022-05-13 14:14:09.626000 +00:00',
    fattura  = null
WHERE molo = 9
  AND imbarcazione = 12
  AND arrivo = '2022-05-13 14:14:07.612000 +00:00';
UPDATE sosta
SET partenza = '2022-05-13 14:36:36.969000 +00:00',
    fattura  = null
WHERE molo = 10
  AND imbarcazione = 13
  AND arrivo = '2022-05-13 14:36:23.224000 +00:00';
UPDATE sosta
SET partenza = '2022-05-13 14:37:27.138000 +00:00',
    fattura  = null
WHERE molo = 11
  AND imbarcazione = 13
  AND arrivo = '2022-05-13 14:37:24.210000 +00:00';
UPDATE sosta
SET partenza = '2022-06-13 18:00:07.710000 +00:00',
    fattura  = null
WHERE molo = 10
  AND imbarcazione = 13
  AND arrivo = '2022-06-13 15:00:04.257000 +00:00';
UPDATE sosta
SET partenza = '2022-05-13 21:14:00.000000 +00:00',
    fattura  = null
WHERE molo = 9
  AND imbarcazione = 14
  AND arrivo = '2022-05-13 21:13:23.027000 +00:00';
UPDATE sosta
SET partenza = '2022-05-14 12:10:32.141000 +00:00',
    fattura  = null
WHERE molo = 9
  AND imbarcazione = 15
  AND arrivo = '2022-05-14 12:10:28.597000 +00:00';
UPDATE sosta
SET partenza = '2022-06-14 12:10:32.141000 +00:00',
    fattura  = null
WHERE molo = 9
  AND imbarcazione = 15
  AND arrivo = '2022-06-14 12:10:28.597000 +00:00';
UPDATE sosta
SET partenza = '2022-06-12 12:30:41.913000 +00:00',
    fattura  = null
WHERE molo = 9
  AND imbarcazione = 15
  AND arrivo = '2022-05-14 12:30:35.244000 +00:00';
UPDATE sosta
SET partenza = '2022-07-19 14:17:51.564000 +00:00',
    fattura  = null
WHERE molo = 99
  AND imbarcazione = 16
  AND arrivo = '2022-06-19 14:17:40.101000 +00:00';
