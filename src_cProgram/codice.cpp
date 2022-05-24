// g++ codice.cpp -L depencies\lib -lpq -o codice
#include <iostream>
#include "dependencies/include/libpq-fe.h"

//Parametri database
# define PG_HOST "localhost" // Indirizzo Host
# define PG_USER "amassare" // Nome utente
# define PG_DB "progetto_amassare_fzontaro" //Nome del database
# define PG_PASS "%zNqTm:0wF4x" //Password
# define PG_PORT 8080

//Query
#define QUERY_1 "SELECT Ev.Specialita, MAX(Os.Nome) AS Presentatore, MAX(Az.Nome) AS Sponsor, MAX(Pa.Nazionalita) AS Vincitori FROM Evento Ev JOIN Ospite Os ON Ev.Presentatore=Os.Codice JOIN Azienda Az ON Ev.Sponsor=Az.Codice JOIN Partecipante Pa ON Pa.CF=Ev.Vincitore GROUP BY Ev.Specialita"
#define QUERY_2 "SELECT Au.Casa, TRUNC(AVG(Pa.Eta)) AS EtaMedia FROM Partecipante Pa JOIN Automobile Au ON Pa.CF=Au.Proprietario GROUP BY Au.Casa ORDER BY AVG(Pa.Eta)"
#define QUERY_3 "SELECT Acquirente, SUM(Totale) AS TotaleAcquisti FROM Acquisto Ac, (SELECT Proprietario FROM Automobile Au JOIN Partecipazione Pa ON Au.Targa=Pa.Automobile GROUP BY Proprietario HAVING COUNT(Evento)>1) AS Partecipanti WHERE Ac.Acquirente=Partecipanti.Proprietario GROUP BY Acquirente"
#define QUERY_4 "DROP VIEW IF EXISTS Epoca; CREATE VIEW Epoca AS SELECT Targa, DATE_PART('year', AGE(CURRENT_DATE, Anno)) AS Eta, CASE WHEN DATE_PART('year', AGE(CURRENT_DATE, Anno))>=25 THEN 'Storica' WHEN DATE_PART('year', AGE(CURRENT_DATE, Anno))<25 THEN 'Attuale' END Epoca FROM Automobile; SELECT Nazionalita, COUNT(Epoca) FROM Partecipante Pa JOIN Automobile Au ON Pa.CF=Au.Proprietario JOIN Epoca E ON Au.Targa=E.Targa WHERE Epoca='Storica' GROUP BY Nazionalita ORDER BY COUNT(Epoca) DESC"
#define QUERY_5 "DROP VIEW IF EXISTS Vendite; CREATE VIEW Vendite AS SELECT Prod.Codice, Prod.Nome, Prod.Produttore, Prod.Prezzo, Cont.Quantita FROM Prodotto Prod JOIN Contenuto Cont ON Prod.Codice=Cont.Prodotto; SELECT St.Nome AS Stand, Pers.Nome AS Proprietario FROM (SELECT Pe.Codice, COALESCE(Nome, 'Membro Staff') Nome FROM Personale Pe LEFT JOIN (SELECT Codice, Nome FROM Azienda UNION SELECT Codice, Nome FROM Ospite) AS Speciali ON Pe.Codice=Speciali.Codice) AS Pers JOIN Stand St ON Pers.Codice=St.Proprietario JOIN (SELECT DISTINCT Va.Stand FROM Vendita Va WHERE NOT EXISTS (SELECT DISTINCT Codice FROM Vendite Ve WHERE Va.Prodotto=Ve.Codice)) AS NonVe ON NonVe.Stand=St.Codice"
#define QUERY_6 "SELECT Pa.Nome, COALESCE(Stand, 0) Stand, COALESCE(Eventi, 0) Eventi FROM Padiglione Pa LEFT JOIN (	SELECT Pa.Nome, COUNT(Ev.Padiglione) AS Eventi FROM Padiglione Pa JOIN Evento Ev ON Pa.Nome=Ev.Padiglione GROUP BY Pa.Nome) AS PaEv ON Pa.Nome=PaEv.Nome LEFT JOIN (	SELECT Pa.Nome,  COUNT(St.Padiglione) AS Stand FROM Padiglione Pa  JOIN Stand St ON Pa.Nome=St.Padiglione GROUP BY Pa.Nome ) AS PaSt ON Pa.Nome=PaSt.Nome ORDER BY Pa.Nome"

void do_exit(PGconn *conn)
{
    PQfinish(conn);
    exit(1);
}

class Dbable{
    public:
        void checkResults ( PGresult * res , const PGconn * conn );
        virtual ~Dbable(){};
};

class Imbarcazione: public Dbable{
public:
    Imbarcazione();
    void ormeggia(int molo);
    void disormeggia();
    int getLung() const;
    int getLargh() const;
    int getProf() const;
private:
    int lung,largh,prof;
};

class Marina:public Dbable{
public: 
    void printFreeDocks(PGconn* conn);
    int getFreeDock(PGconn* conn,const Imbarcazione& imb);
};


class Table{
    friend std::ostream& operator<<(std::ostream& os,const Table& table);
    public:
        Table(PGresult* res);
        int getRowsCount() const;
        int getColsCount() const;
        
    private:
        PGresult* res;
};

std::ostream& operator<< (std::ostream& os,const Table& table);

int main()
{

    char conninfo[250];
    sprintf(conninfo , "user=%s password=%s dbname=%s host=%s port=%d" , PG_USER , PG_PASS , PG_DB , PG_HOST , PG_PORT );



    PGconn *conn = PQconnectdb(conninfo); //Connessione al database
    if ( PQstatus ( conn ) != CONNECTION_OK ) {
        std::cout << " Errore di connessione " << PQerrorMessage(conn);
        PQfinish(conn) ;
        exit (1) ;
    }
    else {
        std::cout << " Connessione avvenuta correttamente \n"; 
    }


    std::cout<< "------------------------------\n";
    std::cout<< "Scegli un'opzione dal menù \n";
    std::cout<< "1. Ormeggia Imbarcazione\n";
    std::cout<< "2. Disormeggia Imbarcazione\n";
    std::cout<< "------------------------------\n";

    int i = 0;

    std::cin >> i;

    Marina marina;
    switch (i)
    {
    case(1):
        std::cout << "Dammi l'id della barca da ormeggiare";
        marina.getFreeDock(conn,Imbarcazione());
        //Fai cose relative all'inserimento barca
        break;
    case(2):
        std::cout << "Scegli la barca da disormeggiare\n";
        break;    
    default:
        //Di che c'è stato un errore e rimostra il menù
        break;
    }

    //Pulizia finale
    PQfinish(conn);
}

//Implementazioni ---------------------------------------------

void Marina::printFreeDocks(PGconn* conn){
    PGresult *res = PQexec(conn, "SELECT * FROM molo where occupato = false");
    checkResults(res,conn);

    Table t(res);
    std::cout << t;
}

void Dbable::checkResults (PGresult * res , const PGconn * conn ) {
    if ( PQresultStatus(res) != PGRES_TUPLES_OK) {
        std::cout << " Risultati inconsistenti ! " << PQerrorMessage(conn) << std::endl ;
            PQclear(res) ;
            exit (1) ;
        }
}

Table::Table(PGresult* re) : res(re){}


int Table::getRowsCount() const{return PQntuples(res);}
int Table::getColsCount() const{return PQnfields(res);}

std::ostream& operator<<(std::ostream& os,const Table& table){
    for(int i = 0; i < table.getColsCount(); ++i){
            os << PQfname(table.res,i) << "\t\t";
        }

        os << std::endl;

        for(int i = 0; i < table.getRowsCount(); ++i){
            for(int j = 0; j < table.getColsCount(); ++j){
                os << PQgetvalue(table.res,i,j) << "\t\t";
            }
            os << std::endl;
        }
    return os;
}

int Marina::getFreeDock(PGconn* conn,const Imbarcazione& imb){
    PGresult* ressss = PQprepare(conn,
                              "mario",
                              "SELECT id FROM molo"
                              "WHERE occupato = false"
                              "AND lunghezza > 1"
                              "AND larghezza > 1"
                              "AND profondita > $1::int"
                              "LIMIT 1",
                              3,
                              NULL);

    std::cout << ressss << "\n";
    std::string padiglione;
    std::cin>>padiglione;
    const char *parameter = padiglione.c_str();

    PGresult *res;
    res=PQexecPrepared(conn, "mario", 1, &parameter, NULL, 0, 0);
    checkResults(res,conn);


    Table t(res);
    std::cout << t;
    //std::cout<<PQgetvalue(res, 0, 0);

    return 0;
}


Imbarcazione::Imbarcazione() {}

void Imbarcazione::ormeggia(int molo) {}

void Imbarcazione::disormeggia() {}

int Imbarcazione::getLung() const {return lung;}

int Imbarcazione::getLargh() const {return largh;}

int Imbarcazione::getProf() const {return prof;}