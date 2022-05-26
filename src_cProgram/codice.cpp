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
#define QUERY_1 ""
#define QUERY_2 ""
#define QUERY_3 ""
#define QUERY_4 ""
#define QUERY_5 "with intestazione_fattura as(select fattura.*, p.nome, p.cognome from fattura join cliente c on c.persona = fattura.cliente join persona p on c.persona = p.cf where cliente = 'GLLGNN81A54G224W'), spese as( select sosta.fattura,i.cliente,'sosta' as tipo,ROUND((tstzrange_subdiff(sosta.partenza,sosta.arrivo)/86400.0 * m.prezzogiorno)::numeric,2)  as prezzo from sosta join imbarcazione i on i.id = sosta.imbarcazione join molo m on sosta.molo = m.id where partenza != 'infinity' union all select consumo.fattura,consumo.cliente,'consumo' as tipo, ROUND((consumo.quantita * a2.prezzounitario)::numeric,2) as prezzo from consumo join fornitura f on consumo.allacciamento = f.allacciamento join allacciamento a2 on consumo.allacciamento = a2.nome) select distinct id, scadenza, pagato, nome, cognome, intestazione_fattura.cliente, tipo, prezzo    from spese, intestazione_fattura where spese.fattura = intestazione_fattura.id;"

using std::cout;
using std::endl;
using std::string;
using std::cin;

PGconn* connect(const char* host, const char* user, const char* db, const char* pass, const char* port) {
    char conninfo[256];
    sprintf(conninfo, "user=%s password=%s dbname=\'%s\' hostaddr=%s port=%s",
            user, pass, db, host, port);

    PGconn* conn = PQconnectdb(conninfo);

    if (PQstatus(conn) != CONNECTION_OK) {
        std::cerr << "Errore di connessione" << endl << PQerrorMessage(conn);
        PQfinish(conn);
        exit(1);
    }

    return conn;
}
PGresult* execute(PGconn* conn, const char* query) {
    PGresult* res = PQexec(conn, query);
    if (PQresultStatus(res) != PGRES_TUPLES_OK) {
        cout << " Risultati inconsistenti!" << PQerrorMessage(conn) << endl;
        PQclear(res);
        exit(1);
    }

    return res;
}

void printLine(int campi, int* maxChar) {
    for (int j = 0; j < campi; ++j) {
        cout << '+';
        for (int k = 0; k < maxChar[j] + 2; ++k)
            cout << '-';
    }
    cout << "+\n";
}
void printQuery(PGresult* res) {
    // Preparazione dati
    const int tuple = PQntuples(res), campi = PQnfields(res);
    string v[tuple + 1][campi];

    for (int i = 0; i < campi; ++i) {
        string s = PQfname(res, i);
        v[0][i] = s;
    }
    for (int i = 0; i < tuple; ++i)
        for (int j = 0; j < campi; ++j) {
            if (string(PQgetvalue(res, i, j)) == "t" || string(PQgetvalue(res, i, j)) == "f")
                if (string(PQgetvalue(res, i, j)) == "t")
                    v[i + 1][j] = "si";
                else
                    v[i + 1][j] = "no";
            else
                v[i + 1][j] = PQgetvalue(res, i, j);
        }

    int maxChar[campi];
    for (int i = 0; i < campi; ++i)
        maxChar[i] = 0;

    for (int i = 0; i < campi; ++i) {
        for (int j = 0; j < tuple + 1; ++j) {
            int size = v[j][i].size();
            maxChar[i] = size > maxChar[i] ? size : maxChar[i];
        }
    }

    // Stampa effettiva delle tuple
    printLine(campi, maxChar);
    for (int j = 0; j < campi; ++j) {
        cout << "| ";
        cout << v[0][j];
        for (int k = 0; k < maxChar[j] - v[0][j].size() + 1; ++k)
            cout << ' ';
        if (j == campi - 1)
            cout << "|";
    }
    cout << endl;
    printLine(campi, maxChar);

    for (int i = 1; i < tuple + 1; ++i) {
        for (int j = 0; j < campi; ++j) {
            cout << "| ";
            cout << v[i][j];
            for (int k = 0; k < maxChar[j] - v[i][j].size() + 1; ++k)
                cout << ' ';
            if (j == campi - 1)
                cout << "|";
        }
        cout << endl;
    }
    printLine(campi, maxChar);
}

char* chooseParam(PGconn* conn, const char* query, const char* table) {
    PGresult* res = execute(conn, query);
    printQuery(res);

    const int tuple = PQntuples(res), campi = PQnfields(res);
    int val;
    cout << "Inserisci il numero del " << table << " scelto: ";
    cin >> val;
    while (val <= 0 || val > tuple) {
        cout << "Valore non valido\n";
        cout << "Inserisci il numero del " << table << " scelto: ";
        cin >> val;
    }
    return PQgetvalue(res, val - 1, 0);
}

int main(int argc, char** argv) {
    PGconn* conn = connect(PG_HOST, PG_USER, PG_DB, PG_PASS, PG_PORT);

    const char* query[6] = {QUERY_1,
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
            cout << "Le query vanno da 1 a 6...\n";
            cout << "Query da eseguire (0 per uscire): ";
            cin >> q;
        }
        if (q == 0) break;
        char queryTemp[5000];

        int i = 0;
        switch (q) {
            default:
                printQuery(execute(conn, query[q - 1]));
                break;
        }
        string a = "";
        cout << "Press any key and press enter..";
        cin >> a;
    }

    PQfinish(conn);
}
