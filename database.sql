-- Tabelle inizializzate rispettando i riferimenti

-- Molo
-- Ha una chiave
DROP TABLE IF EXISTS Molo;
CREATE TABLE Molo
(
    id               SERIAL           NOT NULL,
    occupato         BOOLEAN          NOT NULL,
    profonditaMinima DOUBLE PRECISION NOT NULL,
    larghezza        DOUBLE PRECISION NOT NULL,
    lunghezza        DOUBLE PRECISION NOT NULL,
    prezzoGiorno     DECIMAL          NOT NULL,
    PRIMARY KEY (id)
);

-- Servizio
-- Ha una chiave
DROP TABLE IF EXISTS Servizio;
CREATE TABLE Servizio
(
    nome VARCHAR NOT NULL,
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
    servizio        VARCHAR  NOT NULL references Servizio(nome),
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
    id              SERIAL   NOT NULL,
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
    id           SERIAL           NOT NULL,
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
    id       SERIAL   NOT NULL,
    cliente  CHAR(16) NOT NULL references Cliente (persona),
    scadenza date     NOT NULL,
    pagato   timestamp,

    check ( pagato > scadenza ),
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
    id           SERIAL      NOT NULL,
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
    CONSTRAINT molo_gia_prenotato EXCLUDE USING GIST (
        int8range(molo, molo, '[]') WITH =,
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
    cliente       CHAR(16)  NOT NULL references Cliente (persona),
    allacciamento varchar   NOT NULL references Allacciamento (nome),
    inizio        timestamp NOT NULL,
    fine          timestamp,
    quantita      decimal   NOT NULL,
    fattura       int references Fattura (id),
    check (inizio < fine),
    primary key (cliente, allacciamento, inizio)
);

--Indice
CREATE INDEX idx_molo
    ON Molo (id);

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

insert into molo (id, occupato, profonditaminima, larghezza, lunghezza, prezzogiorno)
values (6, false, 10, 6, 14, 30),
       (45, true, 10, 14, 30, 40),
       (52, true, 10, 14, 30, 40),
       (7, true, 10, 6, 14, 30),
       (41, true, 10, 6, 14, 30),
       (15, false, 10, 6, 14, 30),
       (16, false, 10, 6, 14, 30),
       (17, false, 10, 6, 14, 30),
       (18, false, 10, 6, 14, 30),
       (19, false, 10, 6, 14, 30),
       (20, false, 10, 6, 14, 30),
       (21, false, 10, 6, 14, 30),
       (22, false, 10, 6, 14, 30),
       (24, false, 10, 6, 14, 30),
       (25, false, 10, 6, 14, 30),
       (26, false, 10, 6, 14, 30),
       (27, false, 10, 6, 14, 30),
       (28, false, 10, 6, 14, 30),
       (29, false, 10, 6, 14, 30),
       (30, false, 10, 6, 14, 30),
       (31, false, 10, 6, 14, 30),
       (32, false, 10, 6, 14, 30),
       (33, false, 10, 6, 14, 30),
       (34, false, 10, 6, 14, 30),
       (35, false, 10, 6, 14, 30),
       (36, false, 10, 6, 14, 30),
       (37, false, 10, 6, 14, 30),
       (38, false, 10, 6, 14, 30),
       (39, false, 10, 6, 14, 30),
       (40, false, 10, 6, 14, 30),
       (42, false, 10, 6, 14, 30),
       (43, false, 10, 6, 14, 30),
       (44, false, 10, 6, 14, 30),
       (57, false, 10, 14, 30, 40),
       (58, false, 10, 14, 30, 40),
       (59, false, 10, 14, 30, 40),
       (60, false, 10, 14, 30, 40),
       (61, false, 10, 14, 30, 40),
       (62, false, 10, 14, 30, 40),
       (63, false, 10, 14, 30, 40),
       (64, false, 10, 14, 30, 40),
       (65, false, 10, 14, 30, 40),
       (66, false, 10, 14, 30, 40),
       (67, false, 10, 14, 30, 40),
       (68, false, 10, 14, 30, 40),
       (70, false, 15, 20, 40, 100),
       (71, false, 15, 20, 40, 100),
       (72, false, 15, 20, 40, 100),
       (73, false, 15, 20, 40, 100),
       (74, false, 15, 20, 40, 100),
       (75, false, 15, 20, 40, 100),
       (76, false, 15, 20, 40, 100),
       (77, false, 15, 20, 40, 100),
       (78, false, 15, 20, 40, 100),
       (79, false, 15, 20, 40, 100),
       (80, false, 15, 20, 40, 100),
       (81, false, 15, 20, 40, 100),
       (82, false, 15, 20, 40, 100),
       (83, false, 15, 20, 40, 100),
       (84, false, 15, 20, 40, 100),
       (85, false, 15, 20, 40, 100),
       (86, false, 15, 20, 40, 100),
       (87, false, 15, 20, 40, 100),
       (88, false, 15, 20, 40, 100),
       (89, false, 15, 20, 40, 100),
       (90, false, 15, 20, 40, 100),
       (91, false, 15, 20, 40, 100),
       (92, false, 15, 20, 40, 100),
       (93, false, 15, 20, 40, 100),
       (94, false, 15, 20, 40, 100),
       (95, false, 15, 20, 40, 100),
       (96, false, 15, 20, 40, 100),
       (97, false, 15, 20, 40, 100),
       (98, false, 15, 20, 40, 100),
       (99, false, 15, 20, 40, 100),
       (100, false, 15, 20, 40, 100),
       (101, false, 15, 20, 40, 100),
       (102, false, 15, 20, 40, 100),
       (103, false, 15, 20, 40, 100),
       (104, false, 15, 20, 40, 100),
       (105, false, 15, 20, 40, 100),
       (106, false, 15, 20, 40, 100),
       (107, false, 15, 20, 40, 100),
       (108, false, 15, 20, 40, 100),
       (109, false, 15, 20, 40, 100),
       (110, false, 15, 20, 40, 100),
       (111, false, 15, 20, 40, 100),
       (112, false, 15, 20, 40, 100),
       (113, false, 15, 20, 40, 100),
       (114, false, 15, 20, 40, 100),
       (115, false, 15, 20, 40, 100),
       (116, false, 15, 20, 40, 100),
       (117, false, 15, 20, 40, 100),
       (118, false, 15, 20, 40, 100),
       (119, false, 15, 20, 40, 100),
       (120, false, 15, 20, 40, 100),
       (121, false, 15, 20, 40, 100),
       (124, false, 20, 40, 100, 2340),
       (125, false, 20, 40, 100, 2340),
       (123, false, 20, 40, 100, 2340),
       (8, true, 10, 6, 14, 30),
       (9, true, 10, 6, 14, 30),
       (51, true, 10, 14, 30, 40),
       (54, true, 10, 14, 30, 40),
       (53, true, 10, 14, 30, 40),
       (48, true, 10, 14, 30, 40),
       (47, true, 10, 14, 30, 40),
       (13, true, 10, 6, 14, 30),
       (49, true, 10, 14, 30, 40),
       (10, true, 10, 6, 14, 30),
       (46, true, 10, 14, 30, 40),
       (4, true, 10, 6, 14, 30),
       (3, true, 10, 6, 14, 30),
       (55, true, 10, 14, 30, 40),
       (56, true, 10, 14, 30, 40),
       (11, true, 10, 6, 14, 30),
       (12, true, 10, 6, 14, 30),
       (5, true, 10, 6, 14, 30),
       (50, true, 10, 14, 30, 40),
       (23, true, 10, 6, 14, 30),
       (69, true, 15, 20, 40, 100),
       (14, true, 10, 6, 14, 30),
       (1, true, 10, 6, 14, 30),
       (2, true, 10, 6, 14, 30),
       (122, true, 20, 40, 100, 2340);

insert into servizio (nome)
values ('Lavanderia'),
       ('Gru nord'),
       ('Gru sud'),
       ('Bacino di carenaggio'),
       ('Falegnameria'),
       ('Officina'),
       ('Bar Aperto');

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

insert into addetto (persona, servizio, iniziocontratto, finecontratto)
values  ('GLLGNN81A54G224W', 'Lavanderia', '2022-05-24', null),
        ('RZZPLP63L70G224M', 'Bacino di carenaggio', '2019-05-04', null),
        ('MRTMRM92T65G224D', 'Officina', '2022-05-19', null),
        ('BRNNIO80S51G224L', 'Bar Aperto', '2022-05-01', '2024-05-25'),
        ('GLLSNA90A05G224V', 'Falegnameria', '2022-05-06', '2024-05-02'),
        ('VTLSSA77C53G224W', 'Gru sud', '2022-05-02', '2023-05-25'),
        ('GRCBRM70T30G224L', 'Gru nord', '2022-05-01', '2023-05-25'),
        ('CTTTMS64B16G224U', 'Gru nord', '2012-05-03', '2022-05-01');

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

insert into allacciamento (nome, prezzounitario, unitamisura)
values ('Acqua', 0.02, 'l'),
       ('AriaCompressa', 0.03, 'l'),
       ('Gas', 0.32, 'M/C'),
       ('Elettricità', 0.21, 'KW');

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

insert into imbarcazione (mmsi, id, cliente, bandiera, nomecapitano, npostiletto, nome, pescaggio, larghezza, loa)
values ('8815920  ', 11, 'GLLGNN81A54G224W', 'ita', 'Marco', 6, 'ZENIT', 6, 11, 36),
       ('8814093  ', 1, 'SPSLRA03M70G224G', 'ita', 'Mirko', 14, 'CELESTINA', 6, 8, 42),
       ('9017575  ', 2, 'BRNRNS61D64G224W', 'ita', 'Luca', 18, 'NAUTILUS', 7, 9, 47),
       ('5337771  ', 30, 'PRSFNZ86H17G224I', 'ger', 'Nunzio', 9, 'STADT KIEL', 5, 7, 28),
       ('9855288  ', 31, 'BRNRNS61D64G224W', 'spa', 'Mirko', 2, 'ECO TERRA', 6, 9, 28),
       ('9832236  ', 32, 'FRIFME76P50G224A', 'spa', 'Luca', 4, 'BENCHI EXPRESS', 5, 9, 26),
       ('9809631  ', 33, 'PRSFNZ86H17G224I', 'spa', 'Sara', 2, 'ESPALMADOR JET', 6, 9, 28),
       ('9264489  ', 34, 'FRIMRV60S67G224G', 'spa', 'Filippo', 5, 'AIGUES DE FORMENTERA', 5, 9, 27),
       ('9844239  ', 35, 'BTTDPE87L24G224C', 'spa', 'Nicola', 6, 'ECO LUX', 6, 9, 28),
       ('9866897  ', 37, 'BTTDPE87L24G224C', 'fra', 'Luca', 2, 'MERCATOR', 4, 8, 19),
       ('9099391  ', 38, 'RSSCTN98M28G224B', 'fra', 'Sara', 3, 'BROCELIANDE', 5, 8, 18),
       ('8229212  ', 39, 'MTATSE95R28G224U', 'fra', 'Filippo', 2, 'LE VICOMTE', 4, 7, 16),
       ('8215510  ', 44, 'RSSCTN98M28G224B', 'nor', 'Nicola', 2, 'NCTB 7', 5, 9, 14),
       ('9921207  ', 45, 'MTATSE95R28G224U', 'nor', 'Nunzio', 2, 'FOX INSPECTOR', 5, 8, 14),
       ('7945106  ', 6, 'SPSLRA03M70G224G', 'ita', 'Nunzio', 8, 'SEMPRE AVANTI T II', 5, 3.5, 10),
       ('5217555  ', 3, 'FRIFME76P50G224A', 'ita', 'Sara', 22, 'ALA', 8, 3, 10),
       ('8745917  ', 10, 'GLLGNN81A54G224W', 'ger', 'Luca', 8, 'HORIZONT', 1, 1.5, 5),
       ('7945144  ', 9, 'PRSFNZ86H17G224I', 'ita', 'Mirko', 7, 'ERIDANO', 2, 1.6, 5),
       ('9112026  ', 4, 'PRSFNZ86H17G224I', 'ita', 'Filippo', 14, 'EUROFAST', 2.4, 2, 8),
       ('8836340  ', 7, 'BRNRNS61D64G224W', 'ita', 'Gaetano', 9, 'GIORGIONE', 2, 1.7, 6),
       ('9212553  ', 8, 'FRIFME76P50G224A', 'ita', 'Marco', 10, 'MAZZORBO', 1.3, 1, 5),
       ('8877124  ', 5, 'GLLGNN81A54G224W', 'ita', 'Nicola', 9, 'AZZURRA SECONDA', 2.5, 2, 9),
       ('9180322  ', 43, 'BTTDPE87L24G224C', 'nor', 'Filippo', 4, 'BERGEN KREDS', 3.1, 3, 12),
       ('9831581  ', 40, 'MRTSVN62M13G224Z', 'fra', 'Nicola', 2, 'LA TRINITE', 2, 3, 13),
       ('8745890  ', 29, 'FRIFME76P50G224A', 'ger', 'Nicola', 8, 'DANA', 4, 1.3, 7),
       ('8745943  ', 28, 'BRNRNS61D64G224W', 'ger', 'Filippo', 6, 'NORDLICHT', 3.5, 3.5, 11),
       ('9850991  ', 36, 'FRIMRV60S67G224G', 'fra', 'Mirko', 4, 'TIGERS III', 4, 1.9, 7),
       ('9137765  ', 42, 'FRIMRV60S67G224G', 'nor', 'Sara', 2, 'VOLLEROSA', 2, 2.5, 12),
       ('8745929  ', 27, 'SPSLRA03M70G224G', 'ger', 'Sara', 7, 'INSEL RUEGEN', 3.5, 1.8, 6.5),
       ('9868041  ', 41, 'MRTSVN62M13G224Z', 'nor', 'Luca', 3, 'FROY STADT', 4, 4, 15.5),
       ('7564864  ', 13, 'GTTMNL80D23G224S', 'ita', 'Mario', 2, 'Maria', 2, 1.8, 6),
       ('1256789  ', 46, 'BLLMRK80D29G224M', 'ger', 'Alex', 2, 'Empire', 2, 3.8, 6),
       ('5432179  ', 47, 'BNCCRI03T58G224W', 'nor', 'Nicola', 1, 'Nicolina', 1, 2, 8),
       ('4866548  ', 65, 'FNTCGL78B08G224E', 'slo', 'Francesco', 2, 'Maria Vergine', 2, 2.5, 8),
       ('1351561  ', 48, 'MRTSRT91H55G224R', 'slo', 'Estebiu', 3, 'Branil', 1, 2.8, 6),
       ('1358946  ', 49, 'RZZPLP63L70G224M', 'slo', 'Marko', 4, 'Sinfonia', 3, 2.1, 7),
       ('4654894  ', 50, 'SNNMRV74S45G224C', 'slo', 'Nicolai', 2, 'Giuseppina', 2, 2, 5),
       ('4549847  ', 51, 'MRNVNN00C58G224F', 'slo', 'Vienna', 2, 'Annone', 2, 1, 6),
       ('4894896  ', 52, 'CTTTMS64B16G224U', 'slo', 'Tommaso', 3, 'Jotaro', 1, 1.5, 6),
       ('5646544  ', 53, 'CLMMNL00C10G224D', 'slo', 'Manuele', 5, 'Totano', 2, 1.7, 10),
       ('4564894  ', 54, 'LNELIA78E69G224J', 'cro', 'Perisic', 6, 'Tod', 3, 1.4, 12),
       ('4651156  ', 55, 'BNCRLA58A25G224U', 'cro', 'Raul', 5, 'Totoro', 2, 1.5, 13),
       ('1651891  ', 56, 'MRNMRP81S70G224W', 'cro', 'Mariapia', 2, 'Spidey', 1, 1.6, 12),
       ('1651894  ', 57, 'PLLGGR91P14G224J', 'cro', 'Gregorio', 3, 'Natalino', 2, 1.9, 10),
       ('1561894  ', 58, 'MRCLRZ70B47G224O', 'cro', 'Lucrezia', 4, 'Filippo Lippi', 2, 3, 9),
       ('3518194  ', 59, 'FRILTT02A44G224C', 'pan', 'Loretta', 6, 'Lumumba', 2.1, 3.2, 10),
       ('3518915  ', 60, 'MSSLRZ73M57G224S', 'pan', 'Lucrezia', 2, 'Samuela', 2, 4.2, 17),
       ('1151511  ', 61, 'GRCMRP69L58G224Q', 'pan', 'Mariapia', 1, 'Our pratical dreams', 3, 3.2, 21),
       ('5618181  ', 62, 'SLVRST98P02G224K', 'pan', 'Oreste', 3, 'Supreme', 4, 5, 28),
       ('5189111  ', 63, 'BNDRMO78P17G224H', 'cia', 'Romeo', 2, 'Salina', 5, 2, 7),
       ('1181855  ', 64, 'GRCLRS80T10G224B', 'cia', 'Loris', 4, 'Meloria', 2.3, 1.8, 8);

insert into fattura (id, cliente, scadenza, pagato)
values (11, 'SPSLRA03M70G224G', '2022-07-02', '2022-07-24 15:32:26.000000'),
       (1, 'RSSCTN98M28G224B', '2022-07-02', null),
       (2, 'PRSFNZ86H17G224I', '2022-05-25', null),
       (3, 'MTATSE95R28G224U', '2022-05-26', null),
       (4, 'MRTSVN62M13G224Z', '2022-05-25', null),
       (5, 'GLLGNN81A54G224W', '2022-07-02', null),
       (6, 'FRIMRV60S67G224G', '2022-05-26', null),
       (7, 'FRIFME76P50G224A', '2022-07-02', '2022-07-24 18:26:52.000000'),
       (8, 'BTTDPE87L24G224C', '2022-05-25', null),
       (9, 'BRNRNS61D64G224W', '2022-05-26', null);

insert into sosta (imbarcazione, molo, arrivo, id, partenza, fattura)
values  (1, 122, '2022-05-23 16:24:29.715000 +00:00', 4, 'infinity', 11),
        (27, 8, '2022-05-23 17:58:28.539000 +00:00', 20, 'infinity', 11),
        (38, 48, '2022-05-23 17:54:10.384000 +00:00', 18, 'infinity', 1),
        (44, 46, '2022-05-23 17:53:28.090000 +00:00', 16, 'infinity', 1),
        (4, 4, '2022-05-23 17:51:00.425000 +00:00', 10, 'infinity', 2),
        (30, 53, '2022-05-23 18:04:41.176000 +00:00', 33, 'infinity', 2),
        (9, 2, '2022-05-23 17:49:25.267000 +00:00', 8, 'infinity', 2),
        (33, 55, '2022-05-23 18:05:27.551000 +00:00', 35, 'infinity', 2),
        (39, 47, '2022-05-23 17:53:45.558000 +00:00', 17, 'infinity', 3),
        (41, 50, '2022-05-23 18:03:53.323000 +00:00', 28, 'infinity', 4),
        (11, 69, '2022-05-23 16:12:23.622000 +00:00', 3, 'infinity', 5),
        (5, 5, '2022-05-23 17:51:43.102000 +00:00', 11, 'infinity', 5),
        (10, 1, '2022-05-23 17:26:02.266000 +00:00', 7, 'infinity', 5),
        (42, 12, '2022-05-23 18:01:40.055000 +00:00', 24, 'infinity', 6),
        (36, 10, '2022-05-23 18:01:07.745000 +00:00', 22, 'infinity', 6),
        (8, 23, '2022-05-23 17:25:31.346000 +00:00', 6, 'infinity', 7),
        (3, 6, '2022-05-23 17:52:03.545000 +00:00', 12, '2022-05-24 17:20:37.084000 +00:00', 7),
        (32, 51, '2022-05-23 18:04:10.394000 +00:00', 29, 'infinity', 7),
        (29, 9, '2022-05-23 17:58:46.047000 +00:00', 21, 'infinity', 7),
        (35, 56, '2022-05-23 18:05:43.786000 +00:00', 36, 'infinity', 8),
        (37, 49, '2022-05-23 17:54:49.793000 +00:00', 19, 'infinity', 8),
        (43, 13, '2022-05-23 18:02:07.340000 +00:00', 25, 'infinity', 8),
        (28, 11, '2022-05-23 18:01:20.817000 +00:00', 23, 'infinity', 9),
        (31, 54, '2022-05-23 18:05:05.651000 +00:00', 34, 'infinity', 9),
        (7, 3, '2022-05-23 17:50:30.986000 +00:00', 9, 'infinity', 9),
        (2, 123, '2022-02-23 17:20:26.530000 +00:00', 5, '2022-03-23 17:20:37.084000 +00:00', 9),
        (6, 7, '2022-05-23 17:52:38.822000 +00:00', 13, '2022-05-25 10:42:59.648000 +00:00', 11),
        (40, 41, '2022-05-23 18:03:32.148000 +00:00', 27, '2022-05-25 10:42:59.648000 +00:00', 4),
        (45, 45, '2022-05-23 17:52:58.439000 +00:00', 15, '2022-05-25 10:42:59.648000 +00:00', 3),
        (34, 52, '2022-05-23 18:04:22.121000 +00:00', 30, '2022-05-25 10:42:59.648000 +00:00', 6),
        (3, 14, '2022-05-24 17:37:06.500000 +00:00', 37, '2022-05-28 17:38:06.500000 +00:00', 7);

insert into prenotazione (cliente, molo, prevarrivo, prevpartenza, sosta)
values (33, 14, '2022-05-24 17:37:06.500000 +00:00', '2022-05-27 17:38:06.500000 +00:00', 37),
       (33, 51, '2022-05-23 18:04:10.394000 +00:00', '2022-05-31 11:28:25.457000 +00:00', 29),
       (37, 13, '2022-05-23 13:02:07.340000 +00:00', 'infinity', 25),
       (32, 54, '2022-05-23 18:05:05.651000 +00:00', 'infinity', 34),
       (42, 15, '2022-09-02 12:45:13.039000 +00:00', 'infinity', null),
       (43, 16, '2022-09-02 08:45:23.903000 +00:00', 'infinity', null),
       (44, 17, '2022-09-01 15:45:38.254000 +00:00', 'infinity', null),
       (45, 18, '2022-09-02 15:45:51.804000 +00:00', 'infinity', null),
       (46, 19, '2022-09-02 12:46:05.893000 +00:00', 'infinity', null),
       (47, 20, '2022-09-04 12:46:22.524000 +00:00', 'infinity', null),
       (48, 21, '2022-09-06 12:46:34.560000 +00:00', 'infinity', null),
       (49, 22, '2022-09-04 16:46:43.095000 +00:00', 'infinity', null),
       (50, 64, '2022-09-05 12:46:55.943000 +00:00', 'infinity', null),
       (51, 68, '2022-09-05 07:47:04.684000 +00:00', 'infinity', null),
       (53, 78, '2022-09-03 15:47:15.146000 +00:00', 'infinity', null);

insert into fornitura (allacciamento, molo)
values ('Acqua', 48),
       ('Elettricità', 45);

--da cambiare
insert into aperturaservizio (servizio, periodoapertura)
values ('Bar Aperto', 4),
       ('Bar Aperto', 5),
       ('Bar Aperto', 6),
       ('Bar Aperto', 7),
       ('Bar Aperto', 8),
       ('Bar Aperto', 9),
       ('Bar Aperto', 10),
       ('Bar Aperto', 11),
       ('Officina', 7),
       ('Officina', 8),
       ('Officina', 9),
       ('Falegnameria', 5),
       ('Lavanderia', 6),
       ('Falegnameria', 8),
       ('Falegnameria', 10),
       ('Falegnameria', 6),
       ('Lavanderia', 1),
       ('Gru nord', 1),
       ('Gru sud', 7),
       ('Bacino di carenaggio', 2),
       ('Falegnameria', 1),
       ('Officina', 1),
       ('Bar Aperto', 1),
       ('Lavanderia', 2),
       ('Gru nord', 2),
       ('Gru sud', 8),
       ('Bacino di carenaggio', 4),
       ('Falegnameria', 2),
       ('Officina', 2),
       ('Bar Aperto', 2),
       ('Gru nord', 3),
       ('Gru sud', 9),
       ('Bacino di carenaggio', 6),
       ('Officina', 3),
       ('Bar Aperto', 3);

insert into consumo (cliente, allacciamento, inizio, fine, quantita, fattura)
values ('PRSFNZ86H17G224I', 'Acqua', '2022-05-23 16:12:23.622000', null, 55, null),
       ('FRIFME76P50G224A', 'Acqua', '2022-05-23 16:12:23.622000', null, 27, null),
       ('PRSFNZ86H17G224I', 'Elettricità', '2022-05-23 16:12:23.622000', null, 30, null),
       ('SPSLRA03M70G224G', 'Elettricità', '2022-05-23 16:12:23.622000', null, 65, null),
       ('BRNRNS61D64G224W', 'Elettricità', '2022-05-23 16:12:23.622000', null, 70, null),
       ('BRNRNS61D64G224W', 'Acqua', '2022-05-23 16:12:23.622000', null, 30, null),
       ('FRIFME76P50G224A', 'Elettricità', '2022-05-26 16:12:23.622000', null, 40, null),
       ('GLLGNN81A54G224W', 'Acqua', '2022-05-26 16:12:23.622000', null, 20, null),
       ('GLLGNN81A54G224W', 'Acqua', '2022-05-04 16:12:23.622000', null, 57, null),
       ('FRIFME76P50G224A', 'Elettricità', '2022-05-23 16:12:23.622000', null, 25, null),
       ('GLLGNN81A54G224W', 'Elettricità', '2022-05-23 16:12:23.622000', null, 50, null),
       ('BRNRNS61D64G224W', 'Elettricità', '2022-05-26 16:12:23.622000', null, 98, null),
       ('PRSFNZ86H17G224I', 'Acqua', '2022-05-30 16:12:23.622000', null, 30, null),
       ('SPSLRA03M70G224G', 'Acqua', '2022-05-25 16:12:23.622000', null, 75, null);

-- checkup finale delle sequenze
SELECT setval('cliente_id_seq', (select max(id) as max from cliente), true);

SELECT setval('fattura_id_seq', (select max(id) as max from fattura), true);

SELECT setval('imbarcazione_id_seq', (select max(id) as max from imbarcazione), true);

SELECT setval('molo_id_seq', (select max(id) as max from molo), true);

SELECT setval('periodoapertura_id_seq', (select max(id) as max from periodoapertura), true);

SELECT setval('sosta_id_seq', (select max(id) as max from sosta), true);


