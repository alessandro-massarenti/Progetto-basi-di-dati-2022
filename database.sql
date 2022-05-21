-- Tabelle inizializzate rispettando i riferimenti

-- Molo
-- Ha una chiave
CREATE TABLE Molo
(
    id               INT,
    occupato         BOOLEAN,
    profonditaMinima DOUBLE PRECISION,
    larghezza        DOUBLE PRECISION,
    lunghezza        DOUBLE PRECISION,
    prezzoGiorno     DECIMAL,
    PRIMARY KEY (id)
);

-- Servizio
-- Ha una chiave
CREATE TABLE Servizio
(
    nome VARCHAR,
    PRIMARY KEY (nome)
);

-- Persona
-- Ha una chiave
CREATE TABLE Persona
(
    CF          VARCHAR NOT NULL,
    dataNascita DATE    NOT NULL,
    nome        VARCHAR NOT NULL,
    cognome     VARCHAR NOT NULL,
    PRIMARY KEY (CF)
);

-- Addetto
-- Ha due chiavi
CREATE TABLE Addetto
(
    persona         VARCHAR NOT NULL references Persona (CF),
    servizio        VARCHAR NOT NULL,
    inizioContratto DATE    NOT NULL,
    fineContratto   DATE,

    PRIMARY KEY (persona),
    UNIQUE (servizio, inizioContratto)
);

-- Cliente
-- ha due chiavi
CREATE TABLE Cliente
(
    persona         VARCHAR NOT NULL references Persona (CF),
    id              INT,
    cittadinanza    VARCHAR NOT NULL,
    residenza       VARCHAR NOT NULL,
    quantitaSoste   INT,
    scontoPersonale DOUBLE PRECISION,
    PRIMARY KEY (persona),
    UNIQUE (id)
);

-- Allacciamento
-- ha una chiave
CREATE TABLE Allacciamento
(
    nome           VARCHAR(255),
    prezzoUnitario DOUBLE PRECISION,
    unitaMisura    VARCHAR(255),
    PRIMARY KEY (nome)
);

-- Fornitura
-- ha due chiavi
CREATE TABLE PeriodoApertura
(
    id       int     NOT NULL,
    giorno   VARCHAR NOT NULL,
    apertura TIME    NOT NULL,
    chiusura TIME    NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (giorno, apertura, chiusura)
);

-- Imbarcazione,
-- Ha due chiavi
CREATE TABLE Imbarcazione
(
    MMSI         VARCHAR(9)       NOT NULL,
    id           INT              NOT NULL,
    cliente      VARCHAR(255)     NOT NULL references Cliente (persona),
    bandiera     VARCHAR          NOT NULL,
    nomeCapitano VARCHAR,
    nPostiLetto  INT              NOT NULL,
    nome         VARCHAR,
    pescaggio    DOUBLE PRECISION NOT NULL,
    larghezza    DOUBLE PRECISION NOT NULL,
    LOA          DOUBLE PRECISION NOT NULL,
    PRIMARY KEY (MMSI),
    UNIQUE (id)
);

-- Sosta
-- Ha due chiavi
-- tabella sosta, non permette la sovrapposizione di soste in uguali orari
-- se la barca è già in un altra sosta oppure se il molo è già occupato
CREATE TABLE sosta
(
    imbarcazione int         NOT NULL references Imbarcazione (id),
    molo         int         NOT NULL references Molo (id),
    arrivo       TIMESTAMPTZ NOT NULL,
    id           INT         NOT NULL,
    partenza     TIMESTAMPTZ NOT NULL default 'infinity',
    fattura      INT
        constraint sosta_fattura__fk
            references Fattura (id),
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
CREATE TABLE Prenotazione
(
    cliente      INTEGER     NOT NULL references Cliente (id),
    molo         INTEGER     NOT NULL references Molo (id),
    prevArrivo   TIMESTAMPTZ NOT NULL,
    prevPartenza TIMESTAMPTZ NOT NULL default 'infinity',
    sosta        INT references sosta (id),
    CHECK ( prevArrivo < prevPartenza ),
    CONSTRAINT molo_gia_occupato EXCLUDE USING GIST (
        int8range(molo, molo, '[]') WITH =,
        box(
                point(extract(epoch FROM prevArrivo at time zone 'UTC'),
                      extract(epoch FROM prevArrivo at time zone 'UTC')),
                point(extract(epoch FROM prevPartenza at time zone 'UTC'),
                      extract(epoch FROM prevPartenza at time zone 'UTC'))
            ) WITH &&
        ),
    CONSTRAINT imbarcazione_gia_in_molo EXCLUDE USING GIST (
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
CREATE TABLE AperturaServizio
(
    servizio        VARCHAR NOT NULL references Molo (id),
    periodoApertura INT     NOT NULL references PeriodoApertura (id),
    PRIMARY KEY (servizio, periodoApertura)
);

-- Consumo
-- ha una chiave
CREATE TABLE Consumo
(
    cliente       varchar references Cliente (id),
    allacciamento varchar references Allacciamento (nome),
    inizio        timestamp,
    fine          int,
    quantita      decimal,
    fattura       int references Fattura (id),
    primary key (cliente, allacciamento, inizio)
);

-- Fattura
-- Ha due chiavi
CREATE TABLE Fattura
(
    id       serial    not null,
    cliente  varchar   not null references Cliente (id),
    scadenza date      not null,
    pagato   timestamp not null,
    primary key (id),
    unique (cliente, scadenza)
);
