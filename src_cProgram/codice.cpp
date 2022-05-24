// g++ codice.cpp -L depencies\lib -lpq -o codice
#include <iostream>
#include "dependencies/include/libpq-fe.h"

//Parametri database
#define PG_HOST "localhost" // Indirizzo Host
#define PG_USER "amassare" // Nome utente
#define PG_DB "progetto_amassare_fzontaro" //Nome del database
#define PG_PASS "%zNqTm:0wF4x" //Password
#define PG_PORT 8080

//Query
#define QUERY_1 "SELECT Ev.Specialita, MAX(Os.Nome) AS Presentatore, MAX(Az.Nome) AS Sponsor, MAX(Pa.Nazionalita) AS Vincitori FROM Evento Ev JOIN Ospite Os ON Ev.Presentatore=Os.Codice JOIN Azienda Az ON Ev.Sponsor=Az.Codice JOIN Partecipante Pa ON Pa.CF=Ev.Vincitore GROUP BY Ev.Specialita"
#define QUERY_2 "SELECT Au.Casa, TRUNC(AVG(Pa.Eta)) AS EtaMedia FROM Partecipante Pa JOIN Automobile Au ON Pa.CF=Au.Proprietario GROUP BY Au.Casa ORDER BY AVG(Pa.Eta)"
#define QUERY_3 "SELECT Acquirente, SUM(Totale) AS TotaleAcquisti FROM Acquisto Ac, (SELECT Proprietario FROM Automobile Au JOIN Partecipazione Pa ON Au.Targa=Pa.Automobile GROUP BY Proprietario HAVING COUNT(Evento)>1) AS Partecipanti WHERE Ac.Acquirente=Partecipanti.Proprietario GROUP BY Acquirente"
#define QUERY_4 "DROP VIEW IF EXISTS Epoca; CREATE VIEW Epoca AS SELECT Targa, DATE_PART('year', AGE(CURRENT_DATE, Anno)) AS Eta, CASE WHEN DATE_PART('year', AGE(CURRENT_DATE, Anno))>=25 THEN 'Storica' WHEN DATE_PART('year', AGE(CURRENT_DATE, Anno))<25 THEN 'Attuale' END Epoca FROM Automobile; SELECT Nazionalita, COUNT(Epoca) FROM Partecipante Pa JOIN Automobile Au ON Pa.CF=Au.Proprietario JOIN Epoca E ON Au.Targa=E.Targa WHERE Epoca='Storica' GROUP BY Nazionalita ORDER BY COUNT(Epoca) DESC"
#define QUERY_5 "DROP VIEW IF EXISTS Vendite; CREATE VIEW Vendite AS SELECT Prod.Codice, Prod.Nome, Prod.Produttore, Prod.Prezzo, Cont.Quantita FROM Prodotto Prod JOIN Contenuto Cont ON Prod.Codice=Cont.Prodotto; SELECT St.Nome AS Stand, Pers.Nome AS Proprietario FROM (SELECT Pe.Codice, COALESCE(Nome, 'Membro Staff') Nome FROM Personale Pe LEFT JOIN (SELECT Codice, Nome FROM Azienda UNION SELECT Codice, Nome FROM Ospite) AS Speciali ON Pe.Codice=Speciali.Codice) AS Pers JOIN Stand St ON Pers.Codice=St.Proprietario JOIN (SELECT DISTINCT Va.Stand FROM Vendita Va WHERE NOT EXISTS (SELECT DISTINCT Codice FROM Vendite Ve WHERE Va.Prodotto=Ve.Codice)) AS NonVe ON NonVe.Stand=St.Codice"
#define QUERY_6 "SELECT Pa.Nome, COALESCE(Stand, 0) Stand, COALESCE(Eventi, 0) Eventi FROM Padiglione Pa LEFT JOIN (	SELECT Pa.Nome, COUNT(Ev.Padiglione) AS Eventi FROM Padiglione Pa JOIN Evento Ev ON Pa.Nome=Ev.Padiglione GROUP BY Pa.Nome) AS PaEv ON Pa.Nome=PaEv.Nome LEFT JOIN (	SELECT Pa.Nome,  COUNT(St.Padiglione) AS Stand FROM Padiglione Pa  JOIN Stand St ON Pa.Nome=St.Padiglione GROUP BY Pa.Nome ) AS PaSt ON Pa.Nome=PaSt.Nome ORDER BY Pa.Nome"

using namespace std;

void checkResults(PGresult* res, const PGconn* conn){
    if(PQresultStatus(res) != PGRES_TUPLES_OK){
        cout<<"Risultati inconsistenti!"<<PQerrorMessage(conn);
        PQclear(res);
        exit(1);
    }
}

void stampaResults(PGresult* res){

    int tuple = PQntuples(res);
    int campi = PQnfields(res);
    cout<<endl;

    for(int i=0; i<campi; ++i){
        cout << PQfname(res, i) << "\t\t";
    }
    cout << endl<<endl;

    for(int i=0; i<tuple; ++i){
        for(int j=0; j<campi; ++j){
            cout<<PQgetvalue(res, i, j)<<"\t\t";
        }
        cout<<endl;
    }

    PQclear(res);
}

void execQuery(PGconn* conn, const char* q){

    PGresult *res = PQexec(conn, q);

    checkResults(res, conn);
    stampaResults(res);

}

int main(int argc, char **argv){
    cout<<"Start"<<endl<<endl;

    char conninfo[250];
    sprintf(conninfo, "user=%s password=%s dbname=%s hostaddr=%s port=%d", PG_USER, PG_PASS, PG_DB, PG_HOST, PG_PORT);

    PGconn * conn = PQconnectdb (conninfo);

    if(PQstatus(conn) != CONNECTION_OK){
        cout<<"Errore di connessione "<<PQerrorMessage(conn)<<endl;
        PQfinish(conn);
        exit(1);
    }

    const char* query[]={QUERY_1, QUERY_2, QUERY_3, QUERY_4, QUERY_5, QUERY_6};

    for(int q=0; q<6; q++){
        cout<<"Query "<<q+1<<endl;
        execQuery(conn, query[q]);
        cout<<endl;
    }

    string parStand = "SELECT St.Nome, Pers.Nome, St.Funzione FROM Stand St JOIN (SELECT Pe.Codice, COALESCE(Nome, 'Membro Staff') Nome FROM Personale Pe LEFT JOIN (SELECT Codice, Nome FROM Azienda UNION SELECT Codice, Nome FROM Ospite) AS Speciali ON Pe.Codice=Speciali.Codice) AS Pers ON St.Proprietario=Pers.Codice WHERE Padiglione=$1::varchar";
    PGresult *stmtST = PQprepare(conn, "stand_parametro", parStand.c_str(), 1, NULL);
    string parEvento = "SELECT Orario, Specialita, Ev.Nome, (Pa.Nome, Pa.Cognome) AS Vincitore, Premio, Os.Nome AS Presentatore, Az.Nome AS Sponsor FROM Evento Ev JOIN Ospite Os ON Ev.Presentatore=Os.Codice JOIN Azienda Az ON Ev.Sponsor=Az.Codice JOIN Partecipante Pa ON Ev.Vincitore=Pa.CF WHERE Padiglione=$1::varchar";
    PGresult *stmtEV = PQprepare(conn, "eventi_parametro", parEvento.c_str(), 1, NULL);
    string padiglione;
    cout<<"Inserire Padiglione di cui cercare le informazioni"<<endl;
    cin>>padiglione;
    const char *parameter = padiglione.c_str();

    PGresult *res;
    res=PQexecPrepared(conn, "stand_parametro", 1, &parameter, NULL, 0, 0);
    checkResults(res, conn);
    cout<<"Stand"<<endl;
    stampaResults(res);
    res=PQexecPrepared(conn, "eventi_parametro", 1, &parameter, NULL, 0, 0);
    checkResults(res, conn);
    cout<<endl<<"Eventi"<<endl;
    stampaResults(res);


    cout<<endl<<"Finish"<<endl;
    return 0;
}