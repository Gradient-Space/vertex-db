FROM postgres:17.0-alpine
#ADD config/pg_hba.conf /var/lib/postgresql/data/
#ADD config/pg_ident.conf /var/lib/postgresql/data/
#ADD config/postgresql.conf /var/lib/postgresql/data/
COPY ./migrations/init.sql /docker-entrypoint-initdb.d/
