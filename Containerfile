FROM postgres:16.4-alpine
#ADD config/pg_hba.conf /var/lib/postgresql/data/
#ADD config/pg_ident.conf /var/lib/postgresql/data/
#ADD config/postgresql.conf /var/lib/postgresql/data/
COPY ./migrations/init.sql /docker-entrypoint-initdb.d/
