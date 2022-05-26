// g++ codice.cpp -L depencies\lib -lpq -o codice
#include <iostream>
#include <string>
#include <cstdio>
#include "dependencies/include/libpq-fe.h"

//Parametri database
#define PG_HOST "127.0.0.1" // Indirizzo Host
#define PG_USER "amassare" // Nome utente
#define PG_DB "progetto_amassare_fzontaro" //Nome del database
#define PG_PASS "%zNqTm:0wF4x" //Password
#define PG_PORT "8080"

//Query
#define QUERY_1 "select allacciamento,sum(quantita) as quantita_consumata,a.unitamisura, a.prezzounitario,sum(quantita) * a.prezzounitario as totale_bollette from consumo join allacciamento a on consumo.allacciamento = a.nome where inizio between '05-01-2020' and '05-31-2025' group by allacciamento, unitamisura, prezzounitario;"
#define QUERY_2 "select count(cliente) as conteggio, p.nome, p.cognome, c.persona from prenotazione join cliente c on prenotazione.cliente = c.id join persona p on c.persona = p.cf where prevarrivo between '01-01-2020' and '12-31-2025' group by c.persona,p.nome, p.cognome having count(cliente) >= 2 order by conteggio desc;"
#define QUERY_3 "select count(imbarcazione) as qt_soste, imbarcazione.nome, mmsi,p.nome as nome_proprietario,p.cognome as cognome_proprietario from sosta join imbarcazione on sosta.imbarcazione = imbarcazione.id join cliente c on imbarcazione.cliente = c.persona join persona p on c.persona = p.cf group by sosta.imbarcazione, imbarcazione.nome, mmsi,p.nome,p.cognome order by qt_soste desc;"
#define QUERY_4 "select distinct molo.id as id_molo,molo.prezzogiorno,molo.profonditaminima,molo.larghezza,molo.lunghezza, molo.occupato from molo,imbarcazione where occupato=false and molo.larghezza > imbarcazione.larghezza and molo.profonditaminima > imbarcazione.pescaggio and molo.lunghezza > imbarcazione.loa and imbarcazione.mmsi = '8836340' order by prezzogiorno limit 5;"
#define QUERY_5 "with intestazione_fattura as(select fattura.*, p.nome, p.cognome from fattura join cliente c on c.persona = fattura.cliente join persona p on c.persona = p.cf where cliente = 'GLLGNN81A54G224W'), spese as( select sosta.fattura,i.cliente,'sosta' as tipo,ROUND((tstzrange_subdiff(sosta.partenza,sosta.arrivo)/86400.0 * m.prezzogiorno)::numeric,2)  as prezzo from sosta join imbarcazione i on i.id = sosta.imbarcazione join molo m on sosta.molo = m.id where partenza != 'infinity' union all select consumo.fattura,consumo.cliente,'consumo' as tipo, ROUND((consumo.quantita * a2.prezzounitario)::numeric,2) as prezzo from consumo join fornitura f on consumo.allacciamento = f.allacciamento join allacciamento a2 on consumo.allacciamento = a2.nome) select distinct id, scadenza, pagato, nome, cognome, intestazione_fattura.cliente, tipo, prezzo    from spese, intestazione_fattura where spese.fattura = intestazione_fattura.id;"

using std::cout;
using std::endl;
using std::string;
using std::cin;


class ResultTable {
private:
    PGresult *res;
    int righe,colonne;
public:
    explicit ResultTable(PGresult *r) : res(r),righe(PQntuples(res)), colonne(PQnfields(res)) {}
    friend std::ostream &operator<<(std::ostream &os, const ResultTable &t);
    int getRighe() const{return righe;}
    int getColonne() const{return colonne;}
private:
    static void printLine(int campi, const size_t *maxChar) {
        for (int j = 0; j < campi; ++j) {
            cout << '+';
            for (int k = 0; k < maxChar[j] + 2; ++k)
                cout << '-';
        }
        cout << "+\n";
    }
    static void traduciBool(string & val) {
        if (val == "t") {
            val = "si";
            return;
        }
        if (val == "f") {
            val = "no";
            return;
        }
    }
};

std::ostream &operator<<(std::ostream &os, const ResultTable &t) {
    // Preparazione dati

    string v[t.getRighe() + 1][t.getColonne()];

    for (int i = 0; i < t.getColonne(); ++i) {
        string s = PQfname(t.res, i);
        v[0][i] = s;
    }
    //Vengono tradotti i bool
    for (int i = 0; i < t.getRighe(); ++i)
        for (int j = 0; j < t.getColonne(); ++j) {
            v[i+1][j] = PQgetvalue(t.res, i, j);
            ResultTable::traduciBool(v[i+1][j]);
        }

    size_t maxChar[t.getColonne()];
    for (int i = 0; i < t.getColonne(); ++i) {
        maxChar[i] = 0;
        for (int j = 0; j < t.getRighe() + 1; ++j) {
            maxChar[i] = v[j][i].size() > maxChar[i] ? v[j][i].size() : maxChar[i];
        }
        cout << maxChar[i] << endl;
    }

    // Stampa effettiva delle tuple
    ResultTable::printLine(t.getColonne(), maxChar);

    //Stampa intestazione
    for (int j = 0; j < t.getColonne(); ++j) {
        cout << "| ";
        cout << v[0][j];
        for (int k = 0; k < maxChar[j] - v[0][j].size() + 1; ++k)
            cout << ' ';
        if (j == t.getColonne() - 1)
            cout << "|";
    }
    cout << endl;


    ResultTable::printLine(t.getColonne(), maxChar);

    for (int i = 1; i < t.getRighe() + 1; ++i) {
        for (int j = 0; j < t.getColonne(); ++j) {
            cout << "| ";

            cout << v[i][j];

            for (int k = 0; k < (maxChar[j] - v[i][j].size()) + 1; ++k)
                cout << ' ';
        }
        cout << "|";
        cout << endl;
    }

    ResultTable::printLine(t.getColonne(), maxChar);
    return os;
}


PGconn *connect(const char *host, const char *user, const char *db, const char *pass, const char *port) {
    char conninfo[256];
    sprintf(conninfo, "user=%s password=%s dbname=\'%s\' hostaddr=%s port=%s",
            user, pass, db, host, port);

    PGconn *conn = PQconnectdb(conninfo);

    if (PQstatus(conn) != CONNECTION_OK) {
        std::cerr << "Errore di connessione" << endl << PQerrorMessage(conn);
        PQfinish(conn);
        exit(1);
    }

    return conn;
}

PGresult *execute(PGconn *conn, const char *query) {
    PGresult *res = PQexec(conn, query);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        cout << " Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
        PQclear(res);
        exit(1);
    }
    return res;
}

int main(int argc, char **argv) {
    PGconn *conn = connect(PG_HOST, PG_USER, PG_DB, PG_PASS, PG_PORT);

    const char *query[6] = {QUERY_1,
                            QUERY_2,
                            QUERY_3,
                            QUERY_4,
                            QUERY_5
    };

    while (true) {
        cout << endl;

        cout << "1. Consumi del marina nel mese indicato\n";
        cout << "2. Clienti con più di 2 di prenotazioni che iniziano nel quinquiennio 2020->2025\n";
        cout << "3. Conteggio soste di ogni imbarcazione\n";
        cout << "4. Controllo dei posti disponibili per una certa imbarcazione\n";
        cout << "5. Mostra la fattura di un cliente\n";


        cout << "Query da eseguire (0 per uscire): ";
        int q = 0;
        cin >> q;
        while (q < 0 || q > 6) {
            cout << "Le query vanno da 1 a 5...\n";
            cout << "Query da eseguire (0 per uscire): ";
            cin >> q;
        }
        if (q == 0) break;
        char queryTemp[5000];

        int i = 0;
        switch (q) {
            default:{
                ResultTable rt(execute(conn, query[q - 1]));
                cout << rt;
                break;
            }
        }
        string a = "";
        cout << "Press any key and press enter..";
        cin >> a;
    }

    PQfinish(conn);
}
