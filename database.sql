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
    nome           VARCHAR(255)     NOT NULL,
    prezzoUnitario DOUBLE PRECISION NOT NULL,
    unitaMisura    VARCHAR(255)     NOT NULL,
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

insert into public.servizio (nome)
values  ('Lavanderia'),
        ('Gru nord'),
        ('Gru sud'),
        ('Bacino di carenaggio'),
        ('Falegnameria'),
        ('Officina'),
        ('Bar Aperto');

insert into periodoapertura (id, giorno, apertura, chiusura)
values (1, 'Lun', '08:00:00', '12:00:00'),
       (2, 'Mar', '08:00:00', '12:00:00'),
       (3, 'Mer', '08:00:00', '12:00:00'),
       (4, 'Gio', '08:00:00', '12:00:00'),
       (5, 'Ven', '08:00:00', '12:00:00'),
       (6, 'Sab', '08:00:00', '12:00:00'),
       (7, 'Lun', '13:00:00', '18:00:00'),
       (8, 'Mar', '13:00:00', '18:00:00'),
       (9, 'Mer', '13:00:00', '18:00:00'),
       (10, 'Gio', '13:00:00', '18:00:00'),
       (11, 'Ven', '13:00:00', '18:00:00');

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

insert into cliente (persona, id, cittadinanza, residenza, quantitasoste, scontopersonale)
values ('GLLGNN81A54G224W', 2, 'ita', 'Napoli', null, null),
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

insert into molo (id, occupato, profonditaminima, larghezza, lunghezza, prezzogiorno)
values (1, null, 10, 6, 14, 30),
       (2, null, 10, 6, 14, 30),
       (3, null, 10, 6, 14, 30),
       (4, null, 10, 6, 14, 30),
       (5, null, 10, 6, 14, 30),
       (6, null, 10, 6, 14, 30),
       (7, null, 10, 6, 14, 30),
       (8, null, 10, 6, 14, 30),
       (9, null, 10, 6, 14, 30),
       (10, null, 10, 6, 14, 30),
       (11, null, 10, 6, 14, 30),
       (12, null, 10, 6, 14, 30),
       (13, null, 10, 6, 14, 30),
       (14, null, 10, 6, 14, 30),
       (15, null, 10, 6, 14, 30),
       (16, null, 10, 6, 14, 30),
       (17, null, 10, 6, 14, 30),
       (18, null, 10, 6, 14, 30),
       (19, null, 10, 6, 14, 30),
       (20, null, 10, 6, 14, 30),
       (21, null, 10, 6, 14, 30),
       (22, null, 10, 6, 14, 30),
       (23, null, 10, 6, 14, 30),
       (24, null, 10, 6, 14, 30),
       (25, null, 10, 6, 14, 30),
       (26, null, 10, 6, 14, 30),
       (27, null, 10, 6, 14, 30),
       (28, null, 10, 6, 14, 30),
       (29, null, 10, 6, 14, 30),
       (30, null, 10, 6, 14, 30),
       (31, null, 10, 6, 14, 30),
       (32, null, 10, 6, 14, 30),
       (33, null, 10, 6, 14, 30),
       (34, null, 10, 6, 14, 30),
       (35, null, 10, 6, 14, 30),
       (36, null, 10, 6, 14, 30),
       (37, null, 10, 6, 14, 30),
       (38, null, 10, 6, 14, 30),
       (39, null, 10, 6, 14, 30),
       (40, null, 10, 6, 14, 30),
       (41, null, 10, 6, 14, 30),
       (42, null, 10, 6, 14, 30),
       (43, null, 10, 6, 14, 30),
       (44, null, 10, 6, 14, 30),
       (45, null, 10, 14, 30, 40),
       (46, null, 10, 14, 30, 40),
       (47, null, 10, 14, 30, 40),
       (48, null, 10, 14, 30, 40),
       (49, null, 10, 14, 30, 40),
       (50, null, 10, 14, 30, 40),
       (51, null, 10, 14, 30, 40),
       (52, null, 10, 14, 30, 40),
       (53, null, 10, 14, 30, 40),
       (54, null, 10, 14, 30, 40),
       (55, null, 10, 14, 30, 40),
       (56, null, 10, 14, 30, 40),
       (57, null, 10, 14, 30, 40),
       (58, null, 10, 14, 30, 40),
       (59, null, 10, 14, 30, 40),
       (60, null, 10, 14, 30, 40),
       (61, null, 10, 14, 30, 40),
       (62, null, 10, 14, 30, 40),
       (63, null, 10, 14, 30, 40),
       (64, null, 10, 14, 30, 40),
       (65, null, 10, 14, 30, 40),
       (66, null, 10, 14, 30, 40),
       (67, null, 10, 14, 30, 40),
       (68, null, 10, 14, 30, 40),
       (69, null, 15, 20, 40, 100),
       (70, null, 15, 20, 40, 100),
       (71, null, 15, 20, 40, 100),
       (72, null, 15, 20, 40, 100),
       (73, null, 15, 20, 40, 100),
       (74, null, 15, 20, 40, 100),
       (75, null, 15, 20, 40, 100),
       (76, null, 15, 20, 40, 100),
       (77, null, 15, 20, 40, 100),
       (78, null, 15, 20, 40, 100),
       (79, null, 15, 20, 40, 100),
       (80, null, 15, 20, 40, 100),
       (81, null, 15, 20, 40, 100),
       (82, null, 15, 20, 40, 100),
       (83, null, 15, 20, 40, 100),
       (84, null, 15, 20, 40, 100),
       (85, null, 15, 20, 40, 100),
       (86, null, 15, 20, 40, 100),
       (87, null, 15, 20, 40, 100),
       (88, null, 15, 20, 40, 100),
       (89, null, 15, 20, 40, 100),
       (90, null, 15, 20, 40, 100),
       (91, null, 15, 20, 40, 100),
       (92, null, 15, 20, 40, 100),
       (93, null, 15, 20, 40, 100),
       (94, null, 15, 20, 40, 100),
       (95, null, 15, 20, 40, 100),
       (96, null, 15, 20, 40, 100),
       (97, null, 15, 20, 40, 100),
       (98, null, 15, 20, 40, 100),
       (99, null, 15, 20, 40, 100),
       (100, null, 15, 20, 40, 100),
       (101, null, 15, 20, 40, 100),
       (102, null, 15, 20, 40, 100),
       (103, null, 15, 20, 40, 100),
       (104, null, 15, 20, 40, 100),
       (105, null, 15, 20, 40, 100),
       (106, null, 15, 20, 40, 100),
       (107, null, 15, 20, 40, 100),
       (108, null, 15, 20, 40, 100),
       (109, null, 15, 20, 40, 100),
       (110, null, 15, 20, 40, 100),
       (111, null, 15, 20, 40, 100),
       (112, null, 15, 20, 40, 100),
       (113, null, 15, 20, 40, 100),
       (114, null, 15, 20, 40, 100),
       (115, null, 15, 20, 40, 100),
       (116, null, 15, 20, 40, 100),
       (117, null, 15, 20, 40, 100),
       (118, null, 15, 20, 40, 100),
       (119, null, 15, 20, 40, 100),
       (120, null, 15, 20, 40, 100),
       (121, null, 15, 20, 40, 100),
       (122, null, 20, 40, 100, 2340),
       (123, null, 20, 40, 100, 2340),
       (124, null, 20, 40, 100, 2340),
       (125, null, 20, 40, 100, 2340);

insert into imbarcazione (mmsi, id, cliente, bandiera, nomecapitano, npostiletto, nome, pescaggio, larghezza, loa)
values ('8815920', 11, 'GLLGNN81A54G224W', 'ita', 'Marco', 6, 'ZENIT', 6, 11, 36),
       ('8814093', 1, 'SPSLRA03M70G224G', 'ita', 'Mirko', 14, 'CELESTINA', 6, 8, 42),
       ('9017575', 2, 'BRNRNS61D64G224W', 'ita', 'Luca', 18, 'NAUTILUS', 7, 9, 47),
       ('5217555', 3, 'FRIFME76P50G224A', 'ita', 'Sara', 22, 'ALA', 8, 9, 51),
       ('9112026', 4, 'PRSFNZ86H17G224I', 'ita', 'Filippo', 14, 'EUROFAST', 6, 9, 40),
       ('8877124', 5, 'GLLGNN81A54G224W', 'ita', 'Nicola', 9, 'AZZURRA SECONDA', 6, 7, 28),
       ('7945106', 6, 'SPSLRA03M70G224G', 'ita', 'Nunzio', 8, 'SEMPRE AVANTI T II', 5, 6, 27),
       ('8836340', 7, 'BRNRNS61D64G224W', 'ita', 'Gaetano', 9, 'GIORGIONE', 5, 6, 28),
       ('9212553', 8, 'FRIFME76P50G224A', 'ita', 'Marco', 10, 'MAZZORBO', 6, 6, 30),
       ('7945144', 9, 'PRSFNZ86H17G224I', 'ita', 'Mirko', 7, 'ERIDANO', 4, 6, 26),
       ('8745917', 10, 'GLLGNN81A54G224W', 'ger', 'Luca', 8, 'HORIZONT', 4, 6, 25),
       ('8745929', 27, 'SPSLRA03M70G224G', 'ger', 'Sara', 7, 'INSEL RUEGEN', 4, 7, 25),
       ('8745943', 28, 'BRNRNS61D64G224W', 'ger', 'Filippo', 6, 'NORDLICHT', 4, 6, 25),
       ('8745890', 29, 'FRIFME76P50G224A', 'ger', 'Nicola', 8, 'DANA', 4, 7, 25),
       ('5337771', 30, 'PRSFNZ86H17G224I', 'ger', 'Nunzio', 9, 'STADT KIEL', 5, 7, 28),
       ('9855288', 31, 'BRNRNS61D64G224W', 'spa', 'Mirko', 2, 'ECO TERRA', 6, 9, 28),
       ('9832236', 32, 'FRIFME76P50G224A', 'spa', 'Luca', 4, 'BENCHI EXPRESS', 5, 9, 26),
       ('9809631', 33, 'PRSFNZ86H17G224I', 'spa', 'Sara', 2, 'ESPALMADOR JET', 6, 9, 28),
       ('9264489', 34, 'FRIMRV60S67G224G', 'spa', 'Filippo', 5, 'AIGUES DE FORMENTERA', 5, 9, 27),
       ('9844239', 35, 'BTTDPE87L24G224C', 'spa', 'Nicola', 6, 'ECO LUX', 6, 9, 28),
       ('9850991', 36, 'FRIMRV60S67G224G', 'fra', 'Mirko', 4, 'TIGERS III', 4, 7, 20),
       ('9866897', 37, 'BTTDPE87L24G224C', 'fra', 'Luca', 2, 'MERCATOR', 4, 8, 19),
       ('9099391', 38, 'RSSCTN98M28G224B', 'fra', 'Sara', 3, 'BROCELIANDE', 5, 8, 18),
       ('8229212', 39, 'MTATSE95R28G224U', 'fra', 'Filippo', 2, 'LE VICOMTE', 4, 7, 16),
       ('9831581', 40, 'MRTSVN62M13G224Z', 'fra', 'Nicola', 2, 'LA TRINITE', 5, 8, 19),
       ('9868041', 41, 'MRTSVN62M13G224Z', 'nor', 'Luca', 3, 'FROY STADT', 8, 13, 20),
       ('9137765', 42, 'FRIMRV60S67G224G', 'nor', 'Sara', 2, 'VOLLEROSA', 7, 8, 20),
       ('9180322', 43, 'BTTDPE87L24G224C', 'nor', 'Filippo', 4, 'BERGEN KREDS', 6, 7, 20),
       ('8215510', 44, 'RSSCTN98M28G224B', 'nor', 'Nicola', 2, 'NCTB 7', 5, 9, 14),
       ('9921207', 45, 'MTATSE95R28G224U', 'nor', 'Nunzio', 2, 'FOX INSPECTOR', 5, 8, 14);

insert into prenotazione (cliente, molo, prevarrivo, prevpartenza, sosta)
values  (32, 45, '2022-05-21 09:00:00.903000 +00:00', '2022-05-25 12:01:00.161000 +00:00', null);