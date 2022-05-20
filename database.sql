-- tabella sosta, non permette la sovrapposizione di soste in uguali orari
-- se la barca è già in un altra sosta oppure se il molo è già occupato

CREATE TABLE sosta
(
    imbarcazione int         not null,
    molo         int         not null,
    arrivo       TIMESTAMPTZ not null,
    partenza     TIMESTAMPTZ not null default 'infinity',
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
    PRIMARY KEY (molo, imbarcazione, arrivo)
);

CREATE TABLE prenotazione
(
    imbarcazione INTEGER     not null,
    molo         INTEGER     not null,
    arrivo       TIMESTAMPTZ not null,
    partenza     TIMESTAMPTZ not null default 'infinity',
    CHECK ( arrivo < partenza ),
    CONSTRAINT molo_gia_occupato EXCLUDE USING GIST (
        int8range(molo, molo, '[]') WITH =,
        box(
                point(extract(epoch FROM arrivo at time zone 'UTC'), extract(epoch FROM arrivo at time zone 'UTC')),
                point(extract(epoch FROM partenza at time zone 'UTC'), extract(epoch FROM partenza at time zone 'UTC'))
            ) WITH &&
        ),
    CONSTRAINT imbarcazione_gia_in_molo EXCLUDE USING GIST (
        int8range(imbarcazione, imbarcazione, '[]') WITH =,
        box(
                point(extract(epoch FROM arrivo at time zone 'UTC'), extract(epoch FROM arrivo at time zone 'UTC')),
                point(extract(epoch FROM partenza at time zone 'UTC'), extract(epoch FROM partenza at time zone 'UTC'))
            ) WITH &&
        ),
    PRIMARY KEY (molo, imbarcazione, arrivo)
);

create table "Consumo"
(
    cliente       varchar,
    allacciamento varchar,
    inizio        timestamp,
    fine          int,
    quantita      decimal,
    fattura       int,
    primary key (cliente,allacciamento,inizio)
);

create table "Fattura"
(
    id       serial not null ,
    cliente  varchar not null ,
    scadenza date not null ,
    pagato   timestamp not null,
    primary key (id),
    unique (cliente,scadenza)
);

