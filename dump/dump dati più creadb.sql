--
-- PostgreSQL database dump
--

-- Dumped from database version 12.10 (Ubuntu 12.10-0ubuntu0.20.04.1)
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

--
-- Name: progetto_amassare_fzontaro; Type: DATABASE; Schema: -; Owner: amassare
--

CREATE DATABASE progetto_amassare_fzontaro WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.UTF-8';


ALTER DATABASE progetto_amassare_fzontaro OWNER TO amassare;

\connect progetto_amassare_fzontaro

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
-- Data for Name: addetto; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.addetto (persona, servizio, iniziocontratto, finecontratto) FROM stdin;
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
-- Data for Name: aperturaservizio; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.aperturaservizio (servizio, periodoapertura) FROM stdin;
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
Lavanderia	3
Gru nord	3
Gru sud	9
Bacino di carenaggio	6
Falegnameria	3
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
-- Data for Name: fattura; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.fattura (id, cliente, scadenza, pagato) FROM stdin;
1	BRNRNS61D64G224W	2022-06-02	2022-06-23 01:11:00
\.


--
-- Data for Name: consumo; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.consumo (cliente, allacciamento, inizio, fine, quantita, fattura) FROM stdin;
BRNRNS61D64G224W	Acqua	2022-05-27 08:12:57	\N	30	1
\.


--
-- Data for Name: molo; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.molo (id, occupato, profonditaminima, larghezza, lunghezza, prezzogiorno) FROM stdin;
8	t	10	6	14	30
9	t	10	6	14	30
45	t	10	14	30	40
52	t	10	14	30	40
51	t	10	14	30	40
54	t	10	14	30	40
53	t	10	14	30	40
48	t	10	14	30	40
47	t	10	14	30	40
13	t	10	6	14	30
49	t	10	14	30	40
7	t	10	6	14	30
10	t	10	6	14	30
46	t	10	14	30	40
4	t	10	6	14	30
3	t	10	6	14	30
6	t	10	6	14	30
55	t	10	14	30	40
41	t	10	6	14	30
56	t	10	14	30	40
11	t	10	6	14	30
12	t	10	6	14	30
14	f	10	6	14	30
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
5	t	10	6	14	30
42	f	10	6	14	30
43	f	10	6	14	30
44	f	10	6	14	30
50	t	10	14	30	40
23	t	10	6	14	30
69	t	15	20	40	100
1	t	10	6	14	30
2	t	10	6	14	30
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
122	t	20	40	100	2340
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
8815920	11	GLLGNN81A54G224W	ita	Marco	6	ZENIT	6	11	36
8814093	1	SPSLRA03M70G224G	ita	Mirko	14	CELESTINA	6	8	42
9017575	2	BRNRNS61D64G224W	ita	Luca	18	NAUTILUS	7	9	47
5337771	30	PRSFNZ86H17G224I	ger	Nunzio	9	STADT KIEL	5	7	28
9855288	31	BRNRNS61D64G224W	spa	Mirko	2	ECO TERRA	6	9	28
9832236	32	FRIFME76P50G224A	spa	Luca	4	BENCHI EXPRESS	5	9	26
9809631	33	PRSFNZ86H17G224I	spa	Sara	2	ESPALMADOR JET	6	9	28
9264489	34	FRIMRV60S67G224G	spa	Filippo	5	AIGUES DE FORMENTERA	5	9	27
9844239	35	BTTDPE87L24G224C	spa	Nicola	6	ECO LUX	6	9	28
9866897	37	BTTDPE87L24G224C	fra	Luca	2	MERCATOR	4	8	19
9099391	38	RSSCTN98M28G224B	fra	Sara	3	BROCELIANDE	5	8	18
8229212	39	MTATSE95R28G224U	fra	Filippo	2	LE VICOMTE	4	7	16
8215510	44	RSSCTN98M28G224B	nor	Nicola	2	NCTB 7	5	9	14
9921207	45	MTATSE95R28G224U	nor	Nunzio	2	FOX INSPECTOR	5	8	14
7945106	6	SPSLRA03M70G224G	ita	Nunzio	8	SEMPRE AVANTI T II	5	3.5	10
5217555	3	FRIFME76P50G224A	ita	Sara	22	ALA	8	3	10
8745917	10	GLLGNN81A54G224W	ger	Luca	8	HORIZONT	1	1.5	5
7945144	9	PRSFNZ86H17G224I	ita	Mirko	7	ERIDANO	2	1.6	5
9112026	4	PRSFNZ86H17G224I	ita	Filippo	14	EUROFAST	2.4	2	8
8836340	7	BRNRNS61D64G224W	ita	Gaetano	9	GIORGIONE	2	1.7	6
9212553	8	FRIFME76P50G224A	ita	Marco	10	MAZZORBO	1.3	1	5
8877124	5	GLLGNN81A54G224W	ita	Nicola	9	AZZURRA SECONDA	2.5	2	9
9180322	43	BTTDPE87L24G224C	nor	Filippo	4	BERGEN KREDS	3.1	3	12
9831581	40	MRTSVN62M13G224Z	fra	Nicola	2	LA TRINITE	2	3	13
8745890	29	FRIFME76P50G224A	ger	Nicola	8	DANA	4	1.3	7
8745943	28	BRNRNS61D64G224W	ger	Filippo	6	NORDLICHT	3.5	3.5	11
9850991	36	FRIMRV60S67G224G	fra	Mirko	4	TIGERS III	4	1.9	7
9137765	42	FRIMRV60S67G224G	nor	Sara	2	VOLLEROSA	2	2.5	12
8745929	27	SPSLRA03M70G224G	ger	Sara	7	INSEL RUEGEN	3.5	1.8	6.5
9868041	41	MRTSVN62M13G224Z	nor	Luca	3	FROY STADT	4	4	15.5
\.


--
-- Data for Name: sosta; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.sosta (imbarcazione, molo, arrivo, id, partenza, fattura) FROM stdin;
11	69	2022-05-23 16:12:23.622+00	3	infinity	\N
1	122	2022-05-23 16:24:29.715+00	4	infinity	\N
2	123	2022-02-23 17:20:26.53+00	5	2022-03-23 17:20:37.084+00	\N
8	23	2022-05-23 17:25:31.346+00	6	infinity	\N
10	1	2022-05-23 17:26:02.266+00	7	infinity	\N
9	2	2022-05-23 17:49:25.267+00	8	infinity	\N
7	3	2022-05-23 17:50:30.986+00	9	infinity	\N
4	4	2022-05-23 17:51:00.425+00	10	infinity	\N
5	5	2022-05-23 17:51:43.102+00	11	infinity	\N
3	6	2022-05-23 17:52:03.545+00	12	infinity	\N
6	7	2022-05-23 17:52:38.822+00	13	infinity	\N
45	45	2022-05-23 17:52:58.439+00	15	infinity	\N
44	46	2022-05-23 17:53:28.09+00	16	infinity	\N
39	47	2022-05-23 17:53:45.558+00	17	infinity	\N
38	48	2022-05-23 17:54:10.384+00	18	infinity	\N
37	49	2022-05-23 17:54:49.793+00	19	infinity	\N
27	8	2022-05-23 17:58:28.539+00	20	infinity	\N
29	9	2022-05-23 17:58:46.047+00	21	infinity	\N
36	10	2022-05-23 18:01:07.745+00	22	infinity	\N
28	11	2022-05-23 18:01:20.817+00	23	infinity	\N
42	12	2022-05-23 18:01:40.055+00	24	infinity	\N
43	13	2022-05-23 18:02:07.34+00	25	infinity	\N
40	41	2022-05-23 18:03:32.148+00	27	infinity	\N
41	50	2022-05-23 18:03:53.323+00	28	infinity	\N
32	51	2022-05-23 18:04:10.394+00	29	infinity	\N
34	52	2022-05-23 18:04:22.121+00	30	infinity	\N
30	53	2022-05-23 18:04:41.176+00	33	infinity	\N
31	54	2022-05-23 18:05:05.651+00	34	infinity	\N
33	55	2022-05-23 18:05:27.551+00	35	infinity	\N
35	56	2022-05-23 18:05:43.786+00	36	infinity	\N
\.


--
-- Data for Name: prenotazione; Type: TABLE DATA; Schema: public; Owner: amassare
--

COPY public.prenotazione (cliente, molo, prevarrivo, prevpartenza, sosta) FROM stdin;
32	45	2022-05-21 09:00:00.903+00	2022-05-25 12:01:00.161+00	\N
37	48	2022-05-22 17:42:41.2+00	2022-05-24 17:38:01.978+00	\N
\.


--
-- Name: cliente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.cliente_id_seq', 60, true);


--
-- Name: fattura_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.fattura_id_seq', 1, false);


--
-- Name: imbarcazione_id_seq; Type: SEQUENCE SET; Schema: public; Owner: amassare
--

SELECT pg_catalog.setval('public.imbarcazione_id_seq', 45, true);


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

SELECT pg_catalog.setval('public.sosta_id_seq', 36, true);


--
-- PostgreSQL database dump complete
--

