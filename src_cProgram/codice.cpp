#include <iostream>
#include "dependencies/include/libpq-fe.h"

# define PG_HOST "localhost" // oppure "localhost" o "postgresql"
# define PG_USER "amassare" // il vostro nome utente
# define PG_DB "progetto_amassare_fzontaro" // il nome del database
# define PG_PASS "%zNqTm:0wF4x" // la vostra password
# define PG_PORT 8080

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

class Marina:public Dbable{
public: 
    void printFreeDocks(PGconn* conn);
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


    std::cout<< "------------------------------";
    std::cout<< "Scegli un'opzione dal menù \n";
    std::cout<< "1. Ormeggia Imbarcazione\n";
    std::cout<< "2. Disormeggia Imbarcazione\n";
    std::cout<< "------------------------------";

    int i = 0;

    std::cin >> i;

    switch (i)
    {
    case(1):
        //Fai cose relative all'inserimento barca
        break;
    case(2):
        //Fai cose relative al Disormeggio della barca
        break;    
    default:
        //Di che c'è stato un errore e rimostra il menù
        break;
    }

    Marina marina;
    marina.printFreeDocks(conn);


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