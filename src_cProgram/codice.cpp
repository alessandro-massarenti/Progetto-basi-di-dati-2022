#include <iostream>
#include "dependencies/include/libpq-fe.h"

# define PG_HOST "localhost" // oppure " localhost " o " postgresql "
# define PG_USER "amassare" // il vostro nome utente
# define PG_DB "progetto_amassare_fzontaro" // il nome del database
# define PG_PASS "%zNqTm:0wF4x" // la vostra password
# define PG_PORT 8080

void do_exit(PGconn *conn)
{
    PQfinish(conn);
    exit(1);
}

void checkResults ( PGresult * res , const PGconn * conn ) {
    if ( PQresultStatus(res) != PGRES_TUPLES_OK) {
        std::cout << " Risultati inconsistenti ! " << PQerrorMessage(conn) << std::endl ;
            PQclear(res) ;
            exit (1) ;
        }
}

int main()
{

    char conninfo [250];
    sprintf ( conninfo , "user=%s password=%s dbname=%s host=%s port=%d" , PG_USER , PG_PASS , PG_DB , PG_HOST , PG_PORT ) ;


    PGconn *conn = PQconnectdb(conninfo); //Connessione al database
    if ( PQstatus ( conn ) != CONNECTION_OK ) {
        std::cout << " Errore di connessione " << PQerrorMessage(conn);
        PQfinish(conn) ;
        exit (1) ;
    }
    else {
        std::cout << " Connessione avvenuta correttamente " ;

        PGresult *res;
        res = PQexec(conn, "SELECT * FROM imbarcazione");

        checkResults(res,conn);

        int tuple = PQntuples(res);
        int campi = PQnfields(res);
        
        for(int i = 0; i < campi; ++i){
            std::cout << PQfname(res,i) << "\t\t";
        }

        std::cout << std::endl;

        for(int i = 0; i < tuple; ++i){
            for(int j = 0; j < campi; ++j){
                std::cout << PQgetvalue(res,i,j) << "\t\t";
            }
            std::cout << std::endl;
        }

        PQclear(res);
        PQfinish(conn) ;
    }
}