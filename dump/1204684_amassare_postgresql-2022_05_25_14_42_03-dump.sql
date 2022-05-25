--
-- PostgreSQL database dump
--

-- Dumped from database version 12.11 (Ubuntu 12.11-0ubuntu0.20.04.1)
-- Dumped by pg_dump version 14.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addetto; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.addetto (
    persona character(16) NOT NULL,
    servizio character varying NOT NULL,
    iniziocontratto date NOT NULL,
    finecontratto date
);


ALTER TABLE public.addetto OWNER TO amassare;

--
-- Name: allacciamento; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.allacciamento (
    nome character varying(255) NOT NULL,
    prezzounitario double precision NOT NULL,
    unitamisura character varying(255) NOT NULL
);


ALTER TABLE public.allacciamento OWNER TO amassare;

--
-- Name: aperturaservizio; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.aperturaservizio (
    servizio character varying NOT NULL,
    periodoapertura integer NOT NULL
);


ALTER TABLE public.aperturaservizio OWNER TO amassare;

--
-- Name: cliente; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.cliente (
    persona character(16) NOT NULL,
    id integer NOT NULL,
    cittadinanza character varying NOT NULL,
    residenza character varying NOT NULL,
    quantitasoste integer,
    scontopersonale double precision
);


ALTER TABLE public.cliente OWNER TO amassare;

--
-- Name: cliente_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.cliente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cliente_id_seq OWNER TO amassare;

--
-- Name: cliente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.cliente_id_seq OWNED BY public.cliente.id;


--
-- Name: consumo; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.consumo (
    cliente character(16) NOT NULL,
    allacciamento character varying NOT NULL,
    inizio timestamp without time zone NOT NULL,
    fine timestamp without time zone,
    quantita numeric NOT NULL,
    fattura integer,
    CONSTRAINT consumo_check CHECK ((inizio < fine))
);


ALTER TABLE public.consumo OWNER TO amassare;

--
-- Name: fattura; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.fattura (
    id integer NOT NULL,
    cliente character(16) NOT NULL,
    scadenza date NOT NULL,
    pagato timestamp without time zone,
    CONSTRAINT fattura_check CHECK ((pagato > scadenza))
);


ALTER TABLE public.fattura OWNER TO amassare;

--
-- Name: fattura_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.fattura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fattura_id_seq OWNER TO amassare;

--
-- Name: fattura_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.fattura_id_seq OWNED BY public.fattura.id;


--
-- Name: fornitura; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.fornitura (
    allacciamento character varying NOT NULL,
    molo integer NOT NULL
);


ALTER TABLE public.fornitura OWNER TO amassare;

--
-- Name: imbarcazione; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.imbarcazione (
    mmsi character(9) NOT NULL,
    id integer NOT NULL,
    cliente character(16),
    bandiera character varying NOT NULL,
    nomecapitano character varying NOT NULL,
    npostiletto integer NOT NULL,
    nome character varying,
    pescaggio double precision NOT NULL,
    larghezza double precision NOT NULL,
    loa double precision NOT NULL
);


ALTER TABLE public.imbarcazione OWNER TO amassare;

--
-- Name: imbarcazione_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.imbarcazione_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.imbarcazione_id_seq OWNER TO amassare;

--
-- Name: imbarcazione_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.imbarcazione_id_seq OWNED BY public.imbarcazione.id;


--
-- Name: sosta; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.sosta (
    imbarcazione integer NOT NULL,
    molo integer NOT NULL,
    arrivo timestamp with time zone NOT NULL,
    id integer NOT NULL,
    partenza timestamp with time zone DEFAULT 'infinity'::timestamp with time zone NOT NULL,
    fattura integer,
    CONSTRAINT sosta_check CHECK ((arrivo < partenza))
);


ALTER TABLE public.sosta OWNER TO amassare;

--
-- Name: molo_occupato; Type: VIEW; Schema: public; Owner: amassare
--

CREATE VIEW public.molo_occupato AS
 SELECT sosta.molo,
    sosta.arrivo,
    sosta.partenza
   FROM public.sosta
  WHERE ((sosta.partenza > timezone('Europe/Rome'::text, now())) AND (sosta.arrivo < timezone('Europe/Rome'::text, now())));


ALTER TABLE public.molo_occupato OWNER TO amassare;

--
-- Name: molo_libero_da; Type: VIEW; Schema: public; Owner: amassare
--

CREATE VIEW public.molo_libero_da AS
 SELECT sosta.molo,
    sosta.arrivo AS libero_da
   FROM public.sosta
  WHERE ((NOT (sosta.molo IN ( SELECT molo_occupato.molo
           FROM public.molo_occupato))) AND (sosta.partenza < timezone('Europe/Rome'::text, now())));


ALTER TABLE public.molo_libero_da OWNER TO amassare;

--
-- Name: molo_libero_fino_a; Type: VIEW; Schema: public; Owner: amassare
--

CREATE VIEW public.molo_libero_fino_a AS
 SELECT sosta.molo,
    sosta.arrivo AS libero_fino_a
   FROM public.sosta
  WHERE ((NOT (sosta.molo IN ( SELECT molo_occupato.molo
           FROM public.molo_occupato))) AND (sosta.arrivo > timezone('Europe/Rome'::text, now())));


ALTER TABLE public.molo_libero_fino_a OWNER TO amassare;

--
-- Name: libero_adesso; Type: VIEW; Schema: public; Owner: amassare
--

CREATE VIEW public.libero_adesso AS
 SELECT COALESCE(molo_libero_da.molo, mlfa.molo) AS molo,
    max(molo_libero_da.libero_da) AS libero_da,
    min(mlfa.libero_fino_a) AS libero_fino_a
   FROM (public.molo_libero_da
     FULL JOIN public.molo_libero_fino_a mlfa ON ((molo_libero_da.molo = mlfa.molo)))
  GROUP BY molo_libero_da.molo, mlfa.molo;


ALTER TABLE public.libero_adesso OWNER TO amassare;

--
-- Name: molo; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.molo (
    id integer NOT NULL,
    occupato boolean NOT NULL,
    profonditaminima double precision NOT NULL,
    larghezza double precision NOT NULL,
    lunghezza double precision NOT NULL,
    prezzogiorno numeric NOT NULL
);


ALTER TABLE public.molo OWNER TO amassare;

--
-- Name: molo_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.molo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.molo_id_seq OWNER TO amassare;

--
-- Name: molo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.molo_id_seq OWNED BY public.molo.id;


--
-- Name: periodoapertura; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.periodoapertura (
    id integer NOT NULL,
    giorno character varying NOT NULL,
    apertura time without time zone NOT NULL,
    chiusura time without time zone NOT NULL
);


ALTER TABLE public.periodoapertura OWNER TO amassare;

--
-- Name: periodoapertura_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.periodoapertura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.periodoapertura_id_seq OWNER TO amassare;

--
-- Name: periodoapertura_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.periodoapertura_id_seq OWNED BY public.periodoapertura.id;


--
-- Name: persona; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.persona (
    cf character(16) NOT NULL,
    datanascita date NOT NULL,
    nome character varying NOT NULL,
    cognome character varying NOT NULL
);


ALTER TABLE public.persona OWNER TO amassare;

--
-- Name: prenotazione; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.prenotazione (
    cliente integer NOT NULL,
    molo integer NOT NULL,
    prevarrivo timestamp with time zone NOT NULL,
    prevpartenza timestamp with time zone DEFAULT 'infinity'::timestamp with time zone NOT NULL,
    sosta integer,
    CONSTRAINT prenotazione_check CHECK ((prevarrivo < prevpartenza))
);


ALTER TABLE public.prenotazione OWNER TO amassare;

--
-- Name: servizio; Type: TABLE; Schema: public; Owner: amassare
--

CREATE TABLE public.servizio (
    nome character varying NOT NULL
);


ALTER TABLE public.servizio OWNER TO amassare;

--
-- Name: sosta_id_seq; Type: SEQUENCE; Schema: public; Owner: amassare
--

CREATE SEQUENCE public.sosta_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sosta_id_seq OWNER TO amassare;

--
-- Name: sosta_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: amassare
--

ALTER SEQUENCE public.sosta_id_seq OWNED BY public.sosta.id;


--
-- Name: cliente id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id SET DEFAULT nextval('public.cliente_id_seq'::regclass);


--
-- Name: fattura id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fattura ALTER COLUMN id SET DEFAULT nextval('public.fattura_id_seq'::regclass);


--
-- Name: imbarcazione id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.imbarcazione ALTER COLUMN id SET DEFAULT nextval('public.imbarcazione_id_seq'::regclass);


--
-- Name: molo id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.molo ALTER COLUMN id SET DEFAULT nextval('public.molo_id_seq'::regclass);


--
-- Name: periodoapertura id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.periodoapertura ALTER COLUMN id SET DEFAULT nextval('public.periodoapertura_id_seq'::regclass);


--
-- Name: sosta id; Type: DEFAULT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta ALTER COLUMN id SET DEFAULT nextval('public.sosta_id_seq'::regclass);


--
-- Data for Name: addetto; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.addetto (persona, servizio, iniziocontratto, finecontratto) FROM stdin;
GLLGNN81A54G224W	Lavanderia	2022-05-24	\N
RZZPLP63L70G224M	Bacino di carenaggio	2019-05-04	\N
MRTMRM92T65G224D	Officina	2022-05-19	\N
BRNNIO80S51G224L	Bar Aperto	2022-05-01	2024-05-25
GLLSNA90A05G224V	Falegnameria	2022-05-06	2024-05-02
VTLSSA77C53G224W	Gru sud	2022-05-02	2023-05-25
GRCBRM70T30G224L	Gru nord	2022-05-01	2023-05-25
CTTTMS64B16G224U	Gru nord	2012-05-03	2022-05-01
\.


--
-- Data for Name: allacciamento; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.allacciamento (nome, prezzounitario, unitamisura) FROM stdin;
Acqua	0.02	l
AriaCompressa	0.03	l
Gas	0.32	M/C
Elettricità	0.21	KW
\.


--
-- Data for Name: aperturaservizio; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.aperturaservizio (servizio, periodoapertura) FROM stdin;
Bar Aperto	4
Bar Aperto	5
Bar Aperto	6
Bar Aperto	7
Bar Aperto	8
Bar Aperto	9
Bar Aperto	10
Bar Aperto	11
Officina	7
Officina	8
Officina	9
Falegnameria	5
Lavanderia	6
Falegnameria	8
Falegnameria	10
Falegnameria	6
Lavanderia	1
Gru nord	1
Gru sud	7
Bacino di carenaggio	2
Falegnameria	1
Officina	1
Bar Aperto	1
Lavanderia	2
Gru nord	2
Gru sud	8
Bacino di carenaggio	4
Falegnameria	2
Officina	2
Bar Aperto	2
Gru nord	3
Gru sud	9
Bacino di carenaggio	6
Officina	3
Bar Aperto	3
\.


--
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.cliente (persona, id, cittadinanza, residenza, quantitasoste, scontopersonale) FROM stdin;
GLLGNN81A54G224W	2	ita	Napoli	\N	\N
SPSLRA03M70G224G	31	ita	Napoli	\N	\N
BRNRNS61D64G224W	32	ita	Padova	\N	\N
FRIFME76P50G224A	33	ita	Padova	\N	\N
PRSFNZ86H17G224I	34	ita	Venezia	\N	\N
GTTMNL80D23G224S	35	ita	Padova	\N	\N
FRIMRV60S67G224G	36	ita	Venezia	\N	\N
BTTDPE87L24G224C	37	ita	Venezia	\N	\N
RSSCTN98M28G224B	38	ita	Padova	\N	\N
MTATSE95R28G224U	39	ita	Napoli	\N	\N
MRTSVN62M13G224Z	40	ita	Padova	\N	\N
FNTCGL78B08G224E	41	ita	Roma	\N	\N
MRTSRT91H55G224R	42	ita	Roma	\N	\N
RZZPLP63L70G224M	43	ita	Padova	\N	\N
SNNMRV74S45G224C	44	ita	Venezia	\N	\N
MRNVNN00C58G224F	45	ita	Padova	\N	\N
CTTTMS64B16G224U	46	ita	Padova	\N	\N
CLMMNL00C10G224D	47	ita	Padova	\N	\N
LNELIA78E69G224J	48	ita	Padova	\N	\N
BNCRLA58A25G224U	49	ita	Venezia	\N	\N
MRNMRP81S70G224W	50	ita	Napoli	\N	\N
PLLGGR91P14G224J	51	ita	Roma	\N	\N
BLLMRK80D29G224M	52	ita	Napoli	\N	\N
MRCLRZ70B47G224O	53	ita	Venezia	\N	\N
FRILTT02A44G224C	54	ita	Roma	\N	\N
BNCCRI03T58G224W	55	ita	Venezia	\N	\N
MSSLRZ73M57G224S	56	ita	Venezia	\N	\N
GRCMRP69L58G224Q	57	ita	Roma	\N	\N
SLVRST98P02G224K	58	ita	Roma	\N	\N
BNDRMO78P17G224H	59	ita	Roma	\N	\N
GRCLRS80T10G224B	60	ita	Roma	\N	\N
\.


--
-- Data for Name: consumo; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.consumo (cliente, allacciamento, inizio, fine, quantita, fattura) FROM stdin;
PRSFNZ86H17G224I	Acqua	2022-05-23 16:12:23.622	\N	55	\N
FRIFME76P50G224A	Acqua	2022-05-23 16:12:23.622	\N	27	\N
PRSFNZ86H17G224I	Elettricità	2022-05-23 16:12:23.622	\N	30	\N
SPSLRA03M70G224G	Elettricità	2022-05-23 16:12:23.622	\N	65	\N
BRNRNS61D64G224W	Elettricità	2022-05-23 16:12:23.622	\N	70	\N
BRNRNS61D64G224W	Acqua	2022-05-23 16:12:23.622	\N	30	\N
FRIFME76P50G224A	Elettricità	2022-05-26 16:12:23.622	\N	40	\N
GLLGNN81A54G224W	Acqua	2022-05-26 16:12:23.622	\N	20	\N
GLLGNN81A54G224W	Acqua	2022-05-04 16:12:23.622	\N	57	\N
FRIFME76P50G224A	Elettricità	2022-05-23 16:12:23.622	\N	25	\N
GLLGNN81A54G224W	Elettricità	2022-05-23 16:12:23.622	\N	50	\N
BRNRNS61D64G224W	Elettricità	2022-05-26 16:12:23.622	\N	98	\N
PRSFNZ86H17G224I	Acqua	2022-05-30 16:12:23.622	\N	30	\N
SPSLRA03M70G224G	Acqua	2022-05-25 16:12:23.622	\N	75	\N
\.


--
-- Data for Name: fattura; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.fattura (id, cliente, scadenza, pagato) FROM stdin;
11	SPSLRA03M70G224G	2022-07-02	2022-07-24 15:32:26
1	RSSCTN98M28G224B	2022-07-02	\N
2	PRSFNZ86H17G224I	2022-05-25	\N
3	MTATSE95R28G224U	2022-05-26	\N
4	MRTSVN62M13G224Z	2022-05-25	\N
5	GLLGNN81A54G224W	2022-07-02	\N
6	FRIMRV60S67G224G	2022-05-26	\N
7	FRIFME76P50G224A	2022-07-02	2022-07-24 18:26:52
8	BTTDPE87L24G224C	2022-05-25	\N
9	BRNRNS61D64G224W	2022-05-26	\N
\.


--
-- Data for Name: fornitura; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.fornitura (allacciamento, molo) FROM stdin;
Acqua	48
Elettricità	45
\.


--
-- Data for Name: imbarcazione; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.imbarcazione (mmsi, id, cliente, bandiera, nomecapitano, npostiletto, nome, pescaggio, larghezza, loa) FROM stdin;
8815920  	11	GLLGNN81A54G224W	ita	Marco	6	ZENIT	6	11	36
8814093  	1	SPSLRA03M70G224G	ita	Mirko	14	CELESTINA	6	8	42
9017575  	2	BRNRNS61D64G224W	ita	Luca	18	NAUTILUS	7	9	47
5337771  	30	PRSFNZ86H17G224I	ger	Nunzio	9	STADT KIEL	5	7	28
9855288  	31	BRNRNS61D64G224W	spa	Mirko	2	ECO TERRA	6	9	28
9832236  	32	FRIFME76P50G224A	spa	Luca	4	BENCHI EXPRESS	5	9	26
9809631  	33	PRSFNZ86H17G224I	spa	Sara	2	ESPALMADOR JET	6	9	28
9264489  	34	FRIMRV60S67G224G	spa	Filippo	5	AIGUES DE FORMENTERA	5	9	27
9844239  	35	BTTDPE87L24G224C	spa	Nicola	6	ECO LUX	6	9	28
9866897  	37	BTTDPE87L24G224C	fra	Luca	2	MERCATOR	4	8	19
9099391  	38	RSSCTN98M28G224B	fra	Sara	3	BROCELIANDE	5	8	18
8229212  	39	MTATSE95R28G224U	fra	Filippo	2	LE VICOMTE	4	7	16
8215510  	44	RSSCTN98M28G224B	nor	Nicola	2	NCTB 7	5	9	14
9921207  	45	MTATSE95R28G224U	nor	Nunzio	2	FOX INSPECTOR	5	8	14
7945106  	6	SPSLRA03M70G224G	ita	Nunzio	8	SEMPRE AVANTI T II	5	3.5	10
5217555  	3	FRIFME76P50G224A	ita	Sara	22	ALA	8	3	10
8745917  	10	GLLGNN81A54G224W	ger	Luca	8	HORIZONT	1	1.5	5
7945144  	9	PRSFNZ86H17G224I	ita	Mirko	7	ERIDANO	2	1.6	5
9112026  	4	PRSFNZ86H17G224I	ita	Filippo	14	EUROFAST	2.4	2	8
8836340  	7	BRNRNS61D64G224W	ita	Gaetano	9	GIORGIONE	2	1.7	6
9212553  	8	FRIFME76P50G224A	ita	Marco	10	MAZZORBO	1.3	1	5
8877124  	5	GLLGNN81A54G224W	ita	Nicola	9	AZZURRA SECONDA	2.5	2	9
9180322  	43	BTTDPE87L24G224C	nor	Filippo	4	BERGEN KREDS	3.1	3	12
9831581  	40	MRTSVN62M13G224Z	fra	Nicola	2	LA TRINITE	2	3	13
8745890  	29	FRIFME76P50G224A	ger	Nicola	8	DANA	4	1.3	7
8745943  	28	BRNRNS61D64G224W	ger	Filippo	6	NORDLICHT	3.5	3.5	11
9850991  	36	FRIMRV60S67G224G	fra	Mirko	4	TIGERS III	4	1.9	7
9137765  	42	FRIMRV60S67G224G	nor	Sara	2	VOLLEROSA	2	2.5	12
8745929  	27	SPSLRA03M70G224G	ger	Sara	7	INSEL RUEGEN	3.5	1.8	6.5
9868041  	41	MRTSVN62M13G224Z	nor	Luca	3	FROY STADT	4	4	15.5
7564864  	13	GTTMNL80D23G224S	ita	Mario	2	Maria	2	1.8	6
1256789  	46	BLLMRK80D29G224M	ger	Alex	2	Empire	2	3.8	6
5432179  	47	BNCCRI03T58G224W	nor	Nicola	1	Nicolina	1	2	8
4866548  	65	FNTCGL78B08G224E	slo	Francesco	2	Maria Vergine	2	2.5	8
1351561  	48	MRTSRT91H55G224R	slo	Estebiu	3	Branil	1	2.8	6
1358946  	49	RZZPLP63L70G224M	slo	Marko	4	Sinfonia	3	2.1	7
4654894  	50	SNNMRV74S45G224C	slo	Nicolai	2	Giuseppina	2	2	5
4549847  	51	MRNVNN00C58G224F	slo	Vienna	2	Annone	2	1	6
4894896  	52	CTTTMS64B16G224U	slo	Tommaso	3	Jotaro	1	1.5	6
5646544  	53	CLMMNL00C10G224D	slo	Manuele	5	Totano	2	1.7	10
4564894  	54	LNELIA78E69G224J	cro	Perisic	6	Tod	3	1.4	12
4651156  	55	BNCRLA58A25G224U	cro	Raul	5	Totoro	2	1.5	13
1651891  	56	MRNMRP81S70G224W	cro	Mariapia	2	Spidey	1	1.6	12
1651894  	57	PLLGGR91P14G224J	cro	Gregorio	3	Natalino	2	1.9	10
1561894  	58	MRCLRZ70B47G224O	cro	Lucrezia	4	Filippo Lippi	2	3	9
3518194  	59	FRILTT02A44G224C	pan	Loretta	6	Lumumba	2.1	3.2	10
3518915  	60	MSSLRZ73M57G224S	pan	Lucrezia	2	Samuela	2	4.2	17
1151511  	61	GRCMRP69L58G224Q	pan	Mariapia	1	Our pratical dreams	3	3.2	21
5618181  	62	SLVRST98P02G224K	pan	Oreste	3	Supreme	4	5	28
5189111  	63	BNDRMO78P17G224H	cia	Romeo	2	Salina	5	2	7
1181855  	64	GRCLRS80T10G224B	cia	Loris	4	Meloria	2.3	1.8	8
\.


--
-- Data for Name: molo; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.molo (id, occupato, profonditaminima, larghezza, lunghezza, prezzogiorno) FROM stdin;
6	f	10	6	14	30
45	t	10	14	30	40
52	t	10	14	30	40
7	t	10	6	14	30
41	t	10	6	14	30
15	f	10	6	14	30
16	f	10	6	14	30
17	f	10	6	14	30
18	f	10	6	14	30
19	f	10	6	14	30
20	f	10	6	14	30
21	f	10	6	14	30
22	f	10	6	14	30
24	f	10	6	14	30
25	f	10	6	14	30
26	f	10	6	14	30
27	f	10	6	14	30
28	f	10	6	14	30
29	f	10	6	14	30
30	f	10	6	14	30
31	f	10	6	14	30
32	f	10	6	14	30
33	f	10	6	14	30
34	f	10	6	14	30
35	f	10	6	14	30
36	f	10	6	14	30
37	f	10	6	14	30
38	f	10	6	14	30
39	f	10	6	14	30
40	f	10	6	14	30
42	f	10	6	14	30
43	f	10	6	14	30
44	f	10	6	14	30
57	f	10	14	30	40
58	f	10	14	30	40
59	f	10	14	30	40
60	f	10	14	30	40
61	f	10	14	30	40
62	f	10	14	30	40
63	f	10	14	30	40
64	f	10	14	30	40
65	f	10	14	30	40
66	f	10	14	30	40
67	f	10	14	30	40
68	f	10	14	30	40
70	f	15	20	40	100
71	f	15	20	40	100
72	f	15	20	40	100
73	f	15	20	40	100
74	f	15	20	40	100
75	f	15	20	40	100
76	f	15	20	40	100
77	f	15	20	40	100
78	f	15	20	40	100
79	f	15	20	40	100
80	f	15	20	40	100
81	f	15	20	40	100
82	f	15	20	40	100
83	f	15	20	40	100
84	f	15	20	40	100
85	f	15	20	40	100
86	f	15	20	40	100
87	f	15	20	40	100
88	f	15	20	40	100
89	f	15	20	40	100
90	f	15	20	40	100
91	f	15	20	40	100
92	f	15	20	40	100
93	f	15	20	40	100
94	f	15	20	40	100
95	f	15	20	40	100
96	f	15	20	40	100
97	f	15	20	40	100
98	f	15	20	40	100
99	f	15	20	40	100
100	f	15	20	40	100
101	f	15	20	40	100
102	f	15	20	40	100
103	f	15	20	40	100
104	f	15	20	40	100
105	f	15	20	40	100
106	f	15	20	40	100
107	f	15	20	40	100
108	f	15	20	40	100
109	f	15	20	40	100
110	f	15	20	40	100
111	f	15	20	40	100
112	f	15	20	40	100
113	f	15	20	40	100
114	f	15	20	40	100
115	f	15	20	40	100
116	f	15	20	40	100
117	f	15	20	40	100
118	f	15	20	40	100
119	f	15	20	40	100
120	f	15	20	40	100
121	f	15	20	40	100
124	f	20	40	100	2340
125	f	20	40	100	2340
123	f	20	40	100	2340
8	t	10	6	14	30
9	t	10	6	14	30
51	t	10	14	30	40
54	t	10	14	30	40
53	t	10	14	30	40
48	t	10	14	30	40
47	t	10	14	30	40
13	t	10	6	14	30
49	t	10	14	30	40
10	t	10	6	14	30
46	t	10	14	30	40
4	t	10	6	14	30
3	t	10	6	14	30
55	t	10	14	30	40
56	t	10	14	30	40
11	t	10	6	14	30
12	t	10	6	14	30
5	t	10	6	14	30
50	t	10	14	30	40
23	t	10	6	14	30
69	t	15	20	40	100
14	t	10	6	14	30
1	t	10	6	14	30
2	t	10	6	14	30
122	t	20	40	100	2340
\.


--
-- Data for Name: periodoapertura; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.periodoapertura (id, giorno, apertura, chiusura) FROM stdin;
1	Lun	08:00:00	12:00:00
2	Mar	08:00:00	12:00:00
3	Mer	08:00:00	12:00:00
4	Gio	08:00:00	12:00:00
5	Ven	08:00:00	12:00:00
6	Sab	08:00:00	12:00:00
7	Lun	13:00:00	18:00:00
8	Mar	13:00:00	18:00:00
9	Mer	13:00:00	18:00:00
10	Gio	13:00:00	18:00:00
11	Ven	13:00:00	18:00:00
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.persona (cf, datanascita, nome, cognome) FROM stdin;
GLLGNN81A54G224W	1981-01-14	Giovanna	Galli
BRNRNS61D64G224W	1961-04-24	Ortensia	Bernardi
FRIFME76P50G224A	1976-09-10	Eufemia	Fiore
PRSFNZ86H17G224I	1986-06-17	Fiorenzo	Parisi
GTTMNL80D23G224S	1980-04-23	Emanuel	Gatti
FRIMRV60S67G224G	1960-11-27	Marieva	Fiore
BTTDPE87L24G224C	1987-07-24	Edipo	Battaglia
RSSCTN98M28G224B	1998-08-28	Costanzo	Russo
MTATSE95R28G224U	1995-10-28	Teseo	Amato
MRTSVN62M13G224Z	1962-08-13	Silvano	Moretti
FNTCGL78B08G224E	1978-02-08	Caligola	Fontana
MRTSRT91H55G224R	1991-06-15	Sarita	Martinelli
RZZPLP63L70G224M	1963-07-30	Penelope	Rizzo
SNNMRV74S45G224C	1974-11-05	Marieva	Sanna
MRNVNN00C58G224F	2000-03-18	Vienna	Marini
CTTTMS64B16G224U	1964-02-16	Tommaso	Cattaneo
CLMMNL00C10G224D	2000-03-10	Manuele	Colombo
LNELIA78E69G224J	1978-05-29	Lia	Leone
BNCRLA58A25G224U	1958-01-25	Raoul	Bianco
MRNMRP81S70G224W	1981-11-30	Mariapia	Marino
PLLGGR91P14G224J	1991-09-14	Gregorio	Pellegrini
BLLMRK80D29G224M	1980-04-29	Mirko	Bellini
MRCLRZ70B47G224O	1970-02-07	Lucrezia	Marchetti
FRILTT02A44G224C	2002-01-04	Loretta	Fiore
BNCCRI03T58G224W	2003-12-18	Cira	Bianchi
MSSLRZ73M57G224S	1973-08-17	Lucrezia	Messina
GLLSNA90A05G224V	1990-01-05	Ausonio	Gallo
BNDRMO78P17G224H	1978-09-17	Romeo	Benedetti
GRCMRP69L58G224Q	1969-07-18	Mariapia	Greco
BRNNIO80S51G224L	1980-11-11	Ione	Barone
VTLSSA77C53G224W	1977-03-13	Assia	Vitali
GRCBRM70T30G224L	1970-12-30	Abramo	Greco
RSSCRS82B05G224S	1982-02-05	Cleros	Rossetti
BLLLZR70E10G224M	1970-05-10	Lazzaro	Bellini
RZZMDE93B09G224Q	1993-02-09	Emidio	Rizzo
MRCLRD67S19G224K	1967-11-19	Leonardo	Marchetti
RGGLSI91D52G224R	1991-04-12	Lisa	Ruggiero
SNNBBN90R60G224N	1990-10-20	Bibiana	Sanna
MRNRMN65T28G224Y	1965-12-28	Erminio	Marini
PGNNRE69C59G224B	1969-03-19	Neri	Pagano
RVIMNL64L17G224Y	1964-07-17	Emanuel	Riva
PLMCSP65T61G224T	1965-12-21	Cassiopea	Palmieri
BNDFTN91A57G224P	1991-01-17	Fortunata	Benedetti
TSTMRA66L51G224O	1966-07-11	Maria	Testa
FRRSOE71T24G224G	1971-12-24	Osea	Ferrari
MRNWTR02E27G224F	2002-05-27	Walter	Marino
RCCMNT86T55G224P	1986-12-15	Marianita	Ricci
CRSGSM80R65G224C	1980-10-25	Gelsomina	Caruso
VTLNIO93T50G224P	1993-12-10	Ione	Vitali
RMNRSL64B50G224X	1964-02-10	Ursula	Romano
MZZMLE63T61G224Q	1963-12-21	Emilia	Mazza
CTTCDV88B42G224W	1988-02-02	Clodovea	Cattaneo
RSSCLE71T48G224V	1971-12-08	Clea	Rossetti
RGGDRH69S53G224N	1969-11-13	Deborah	Ruggiero
RNLCST86R49G224I	1986-10-09	Cristyn	Rinaldi
CSTRNR76T01G224U	1976-12-01	Raniero	Costantini
TSTLRS88E08G224E	1988-05-08	Loris	Testa
FRRFBN60A08G224J	1960-01-08	Fabiano	Ferrari
BTTCCT91C61G224K	1991-03-21	Concetta	Battaglia
GRCLRS80T10G224B	1980-12-10	Loris	Greco
SLAPBL72M16G224V	1972-08-16	Pablo	Sala
SLALSI78P55G224T	1978-09-15	Lisa	Sala
CSTQMD68H18G224A	1968-06-18	Quasimodo	Costantini
SPSLRA03M70G224G	2003-08-30	Laura	Esposito
CLMSBL90S63G224B	1990-11-23	Isabel	Colombo
RVIQMD76P27G224W	1976-09-27	Quasimodo	Riva
SRTLDN77L45G224L	1977-07-05	Loredana	Sartori
SLVRST98P02G224K	1998-09-02	Oreste	Silvestri
VTLMFR77R14G224J	1977-10-14	Manfredi	Vitali
DMCMHL84H59G224W	1984-06-19	Michele	Damico
MRNLRT73D29G224J	1973-04-29	Alberto	Mariani
NREFLC82P55G224R	1982-09-15	Felicia	Neri
CSTLIA92B43G224T	1992-02-03	Lia	Costa
FRRSSA82M64G224O	1982-08-24	Assia	Ferrara
NGRKST92P54G224H	1992-09-14	Kristel	Negri
FRRDMS98C30G224H	1998-03-30	Demis	Ferrara
MRTRMO92P30G224U	1992-09-30	Romeo	Martini
MZZMRN88T01G224G	1988-12-01	Mariano	Mazza
LMBMRM81H43G224O	1981-06-03	Miriam	Lombardo
NGRJRA92M16G224A	1992-08-16	Jari	Negri
CTTGNT80M17G224E	1980-08-17	Giacinto	Cattaneo
RSSMLE95S60G224V	1995-11-20	Emilia	Rossi
MRNFLC70P28G224Z	1970-09-28	Folco	Marini
BRNSRN65M66G224B	1965-08-26	Soriana	Bernardi
MZZNIO74A46G224T	1974-01-06	Ione	Mazza
VTLPCR58L61G224T	1958-07-21	Piccarda	Vitale
FRRZLD79H51G224K	1979-06-11	Zelida	Ferraro
RNLGLN97R10G224E	1997-10-10	Giuliano	Rinaldi
GRCGLN70S08G224A	1970-11-08	Giuliano	Greco
BLLPRM92A25G224H	1992-01-25	Priamo	Bellini
SRRMKA79P69G224Z	1979-09-29	Maika	Sorrentino
PLMNHO67T14G224O	1967-12-14	Noah	Palumbo
PRSKRA02T08G224E	2002-12-08	Akira	Piras
VTLGMN02L23G224E	2002-07-23	Germano	Vitale
LNGVLD69D14G224T	1969-04-14	Valdo	Longo
FRNMRV86M71G224H	1986-08-31	Marieva	Farina
NREMRN91R23G224K	1991-10-23	Marino	Neri
MZZMDA61M03G224S	1961-08-03	Amedeo	Mazza
MRTMRM92T65G224D	1992-12-25	Miriam	Martinelli
BRNLGU61S23G224M	1961-11-23	Luigi	Bruno
\.


--
-- Data for Name: prenotazione; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.prenotazione (cliente, molo, prevarrivo, prevpartenza, sosta) FROM stdin;
33	14	2022-05-24 17:37:06.5+00	2022-05-27 17:38:06.5+00	37
33	51	2022-05-23 18:04:10.394+00	2022-05-31 11:28:25.457+00	29
37	13	2022-05-23 13:02:07.34+00	infinity	25
32	54	2022-05-23 18:05:05.651+00	infinity	34
42	15	2022-09-02 12:45:13.039+00	infinity	\N
43	16	2022-09-02 08:45:23.903+00	infinity	\N
44	17	2022-09-01 15:45:38.254+00	infinity	\N
45	18	2022-09-02 15:45:51.804+00	infinity	\N
46	19	2022-09-02 12:46:05.893+00	infinity	\N
47	20	2022-09-04 12:46:22.524+00	infinity	\N
48	21	2022-09-06 12:46:34.56+00	infinity	\N
49	22	2022-09-04 16:46:43.095+00	infinity	\N
50	64	2022-09-05 12:46:55.943+00	infinity	\N
51	68	2022-09-05 07:47:04.684+00	infinity	\N
53	78	2022-09-03 15:47:15.146+00	infinity	\N
\.


--
-- Data for Name: servizio; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.servizio (nome) FROM stdin;
Lavanderia
Gru nord
Gru sud
Bacino di carenaggio
Falegnameria
Officina
Bar Aperto
\.


--
-- Data for Name: sosta; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.sosta (imbarcazione, molo, arrivo, id, partenza, fattura) FROM stdin;
1	122	2022-05-23 16:24:29.715+00	4	infinity	11
27	8	2022-05-23 17:58:28.539+00	20	infinity	11
38	48	2022-05-23 17:54:10.384+00	18	infinity	1
44	46	2022-05-23 17:53:28.09+00	16	infinity	1
4	4	2022-05-23 17:51:00.425+00	10	infinity	2
30	53	2022-05-23 18:04:41.176+00	33	infinity	2
9	2	2022-05-23 17:49:25.267+00	8	infinity	2
33	55	2022-05-23 18:05:27.551+00	35	infinity	2
39	47	2022-05-23 17:53:45.558+00	17	infinity	3
41	50	2022-05-23 18:03:53.323+00	28	infinity	4
11	69	2022-05-23 16:12:23.622+00	3	infinity	5
5	5	2022-05-23 17:51:43.102+00	11	infinity	5
10	1	2022-05-23 17:26:02.266+00	7	infinity	5
42	12	2022-05-23 18:01:40.055+00	24	infinity	6
36	10	2022-05-23 18:01:07.745+00	22	infinity	6
8	23	2022-05-23 17:25:31.346+00	6	infinity	7
3	6	2022-05-23 17:52:03.545+00	12	2022-05-24 17:20:37.084+00	7
32	51	2022-05-23 18:04:10.394+00	29	infinity	7
29	9	2022-05-23 17:58:46.047+00	21	infinity	7
35	56	2022-05-23 18:05:43.786+00	36	infinity	8
37	49	2022-05-23 17:54:49.793+00	19	infinity	8
43	13	2022-05-23 18:02:07.34+00	25	infinity	8
28	11	2022-05-23 18:01:20.817+00	23	infinity	9
31	54	2022-05-23 18:05:05.651+00	34	infinity	9
7	3	2022-05-23 17:50:30.986+00	9	infinity	9
2	123	2022-02-23 17:20:26.53+00	5	2022-03-23 17:20:37.084+00	9
6	7	2022-05-23 17:52:38.822+00	13	2022-05-25 10:42:59.648+00	11
40	41	2022-05-23 18:03:32.148+00	27	2022-05-25 10:42:59.648+00	4
45	45	2022-05-23 17:52:58.439+00	15	2022-05-25 10:42:59.648+00	3
34	52	2022-05-23 18:04:22.121+00	30	2022-05-25 10:42:59.648+00	6
3	14	2022-05-24 17:37:06.5+00	37	2022-05-28 17:38:06.5+00	7
\.


--
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.cliente_id_seq', 60, true);


--
-- Name: fattura_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.fattura_id_seq', 11, true);


--
-- Name: imbarcazione_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.imbarcazione_id_seq', 65, true);


--
-- Name: molo_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.molo_id_seq', 125, true);


--
-- Name: periodoapertura_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.periodoapertura_id_seq', 11, true);


--
-- Name: sosta_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.sosta_id_seq', 37, true);


--
-- Name: addetto addetto_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.addetto
    ADD CONSTRAINT addetto_pkey PRIMARY KEY (persona);


--
-- Name: addetto addetto_servizio_iniziocontratto_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.addetto
    ADD CONSTRAINT addetto_servizio_iniziocontratto_key UNIQUE (servizio, iniziocontratto);


--
-- Name: allacciamento allacciamento_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.allacciamento
    ADD CONSTRAINT allacciamento_pkey PRIMARY KEY (nome);


--
-- Name: aperturaservizio aperturaservizio_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.aperturaservizio
    ADD CONSTRAINT aperturaservizio_pkey PRIMARY KEY (servizio, periodoapertura);


--
-- Name: cliente cliente_id_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_id_key UNIQUE (id);


--
-- Name: cliente cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_pkey PRIMARY KEY (persona);


--
-- Name: consumo consumo_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_pkey PRIMARY KEY (cliente, allacciamento, inizio);


--
-- Name: fattura fattura_cliente_scadenza_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_cliente_scadenza_key UNIQUE (cliente, scadenza);


--
-- Name: fattura fattura_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_pkey PRIMARY KEY (id);


--
-- Name: fornitura fornitura_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fornitura
    ADD CONSTRAINT fornitura_pkey PRIMARY KEY (allacciamento, molo);


--
-- Name: sosta imbarcazione_gia_in_molo; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT imbarcazione_gia_in_molo EXCLUDE USING gist (int8range((imbarcazione)::bigint, (imbarcazione)::bigint, '[]'::text) WITH =, box(point(date_part('epoch'::text, timezone('UTC'::text, arrivo)), date_part('epoch'::text, timezone('UTC'::text, arrivo))), point(date_part('epoch'::text, timezone('UTC'::text, partenza)), date_part('epoch'::text, timezone('UTC'::text, partenza)))) WITH &&);


--
-- Name: imbarcazione imbarcazione_id_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.imbarcazione
    ADD CONSTRAINT imbarcazione_id_key UNIQUE (id);


--
-- Name: imbarcazione imbarcazione_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.imbarcazione
    ADD CONSTRAINT imbarcazione_pkey PRIMARY KEY (mmsi);


--
-- Name: sosta molo_gia_occupato; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT molo_gia_occupato EXCLUDE USING gist (int8range((molo)::bigint, (molo)::bigint, '[]'::text) WITH =, box(point(date_part('epoch'::text, timezone('UTC'::text, arrivo)), date_part('epoch'::text, timezone('UTC'::text, arrivo))), point(date_part('epoch'::text, timezone('UTC'::text, partenza)), date_part('epoch'::text, timezone('UTC'::text, partenza)))) WITH &&);


--
-- Name: prenotazione molo_gia_prenotato; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT molo_gia_prenotato EXCLUDE USING gist (int8range((molo)::bigint, (molo)::bigint, '[]'::text) WITH =, box(point(date_part('epoch'::text, timezone('UTC'::text, prevarrivo)), date_part('epoch'::text, timezone('UTC'::text, prevarrivo))), point(date_part('epoch'::text, timezone('UTC'::text, prevpartenza)), date_part('epoch'::text, timezone('UTC'::text, prevpartenza)))) WITH &&);


--
-- Name: molo molo_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.molo
    ADD CONSTRAINT molo_pkey PRIMARY KEY (id);


--
-- Name: periodoapertura periodoapertura_giorno_apertura_chiusura_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.periodoapertura
    ADD CONSTRAINT periodoapertura_giorno_apertura_chiusura_key UNIQUE (giorno, apertura, chiusura);


--
-- Name: periodoapertura periodoapertura_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.periodoapertura
    ADD CONSTRAINT periodoapertura_pkey PRIMARY KEY (id);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (cf);


--
-- Name: prenotazione prenotazione_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_pkey PRIMARY KEY (molo, cliente, prevarrivo);


--
-- Name: servizio servizio_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.servizio
    ADD CONSTRAINT servizio_pkey PRIMARY KEY (nome);


--
-- Name: sosta sosta_id_key; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT sosta_id_key UNIQUE (id);


--
-- Name: sosta sosta_pkey; Type: CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT sosta_pkey PRIMARY KEY (molo, imbarcazione, arrivo);


--
-- Name: idx_molo; Type: INDEX; Schema: public; Owner: amassare
--

CREATE INDEX idx_molo ON public.molo USING btree (id);


--
-- Name: addetto addetto_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.addetto
    ADD CONSTRAINT addetto_persona_fkey FOREIGN KEY (persona) REFERENCES public.persona(cf);


--
-- Name: aperturaservizio aperturaservizio_periodoapertura_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.aperturaservizio
    ADD CONSTRAINT aperturaservizio_periodoapertura_fkey FOREIGN KEY (periodoapertura) REFERENCES public.periodoapertura(id);


--
-- Name: aperturaservizio aperturaservizio_servizio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.aperturaservizio
    ADD CONSTRAINT aperturaservizio_servizio_fkey FOREIGN KEY (servizio) REFERENCES public.servizio(nome);


--
-- Name: cliente cliente_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT cliente_persona_fkey FOREIGN KEY (persona) REFERENCES public.persona(cf);


--
-- Name: consumo consumo_allacciamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_allacciamento_fkey FOREIGN KEY (allacciamento) REFERENCES public.allacciamento(nome);


--
-- Name: consumo consumo_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_cliente_fkey FOREIGN KEY (cliente) REFERENCES public.cliente(persona);


--
-- Name: consumo consumo_fattura_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.consumo
    ADD CONSTRAINT consumo_fattura_fkey FOREIGN KEY (fattura) REFERENCES public.fattura(id);


--
-- Name: fattura fattura_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fattura
    ADD CONSTRAINT fattura_cliente_fkey FOREIGN KEY (cliente) REFERENCES public.cliente(persona);


--
-- Name: fornitura fornitura_allacciamento_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fornitura
    ADD CONSTRAINT fornitura_allacciamento_fkey FOREIGN KEY (allacciamento) REFERENCES public.allacciamento(nome);


--
-- Name: fornitura fornitura_molo__fk; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.fornitura
    ADD CONSTRAINT fornitura_molo__fk FOREIGN KEY (molo) REFERENCES public.molo(id);


--
-- Name: imbarcazione imbarcazione_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.imbarcazione
    ADD CONSTRAINT imbarcazione_cliente_fkey FOREIGN KEY (cliente) REFERENCES public.cliente(persona);


--
-- Name: prenotazione prenotazione_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_cliente_fkey FOREIGN KEY (cliente) REFERENCES public.cliente(id);


--
-- Name: prenotazione prenotazione_molo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_molo_fkey FOREIGN KEY (molo) REFERENCES public.molo(id);


--
-- Name: prenotazione prenotazione_sosta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.prenotazione
    ADD CONSTRAINT prenotazione_sosta_fkey FOREIGN KEY (sosta) REFERENCES public.sosta(id);


--
-- Name: sosta sosta_fattura_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT sosta_fattura_fkey FOREIGN KEY (fattura) REFERENCES public.fattura(id);


--
-- Name: sosta sosta_imbarcazione_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT sosta_imbarcazione_fkey FOREIGN KEY (imbarcazione) REFERENCES public.imbarcazione(id);


--
-- Name: sosta sosta_molo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: amassare
--

ALTER TABLE ONLY public.sosta
    ADD CONSTRAINT sosta_molo_fkey FOREIGN KEY (molo) REFERENCES public.molo(id);


--
-- PostgreSQL database dump complete
--

