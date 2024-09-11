-- DEFINE EXTENSIONS FOR ADDED DATABASE FUNCTIONALITY
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "cube";
CREATE EXTENSION IF NOT EXISTS "fuzzystrmatch";
CREATE EXTENSION IF NOT EXISTS "moddatetime";
CREATE EXTENSION IF NOT EXISTS "amcheck";
CREATE EXTENSION IF NOT EXISTS "autoinc";


-- DEFINE SCHEMA FOR APP FUNCTIONS
CREATE TABLE IF NOT EXISTS Tasks (
    taskid          UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    userid          TEXT NOT NULL,
    noradid         TEXT NOT NULL,
    priority        INTEGER NOT NULL
);


CREATE TABLE IF NOT EXISTS Stations (
    stnid           UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    stnname         TEXT NOT NULL,
    latitude        FLOAT NOT NULL,
    longitude       FLOAT NOT NULL,
    altitude        FLOAT NOT NULL,
    minhorizon      FLOAT NOT NULL
);


CREATE TABLE IF NOT EXISTS Satellites (
    satid           UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    noradid         TEXT UNIQUE NOT NULL,
    satname         TEXT UNIQUE NOT NULL,
    designator      TEXT NOT NULL,
    epoch           FLOAT NOT NULL,
    mm1td           FLOAT NOT NULL,
    mm2td           FLOAT NOT NULL,
    bstar           FLOAT NOT NULL,
    inclination     FLOAT NOT NULL,
    ascension       FLOAT NOT NULL,
    eccentricity    FLOAT NOT NULL,
    perigee         FLOAT NOT NULL,
    meananomaly     FLOAT NOT NULL,
    mm              FLOAT NOT NULL
);


CREATE TABLE IF NOT EXISTS Passes (
    stnid           TEXT NOT NULL,
    stnname         TEXT NOT NULL,
    noradid         TEXT NOT NULL,
    satname         TEXT NOT NULL,
    azimuth         FLOAT NOT NULL,
    elevation       FLOAT NOT NULL,
    aos             TIMESTAMPTZ NOT NULL,
    los             TIMESTAMPTZ NOT NULL,
    scheduled       BOOL NOT NULL
);
/*
    FOREIGN KEY(stnid) REFERENCES Stations(stnid),
    FOREIGN KEY(satid) REFERENCES Satellites(satid)
*/


CREATE TABLE IF NOT EXISTS Jobs (
    jobid           UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    stnid           TEXT NOT NULL, 
    stnname         TEXT NOT NULL,
    noradid         TEXT NOT NULL,
    satname         TEXT NOT NULL,
    aos             TIMESTAMPTZ NOT NULL,
    los             TIMESTAMPTZ NOT NULL,
    azimuth         FLOAT NOT NULL,
    elevation       FLOAT NOT NULL,
    scheduled       BOOL NOT NULL,
    completed       BOOL NOT NULL
);
/*
    FOREIGN KEY(stnid) REFERENCES Stations(stnid),
    FOREIGN KEY(satid) REFERENCES Satellites(satid)
*/


CREATE TABLE IF NOT EXISTS TLEs (
    noradid         TEXT NOT NULL PRIMARY KEY,
    satname         TEXT NOT NULL,
    line1           TEXT NOT NULL,
    line2           TEXT NOT NULL
);


CREATE TABLE IF NOT EXISTS Media (
    fname           TEXT NOT NULL,
    data            BYTEA NOT NULL
);


CREATE TABLE IF NOT EXISTS Notifications (
    service         TEXT NOT NULL
);


-- DEFINE INDEXES FOR IMPROVED SEARCH PERFORMANCE
CREATE UNIQUE INDEX tasks_userid_idx ON Tasks(userid);
CREATE UNIQUE INDEX stations_stnid_idx ON Stations(stnid);
CREATE UNIQUE INDEX satellites_satid_idx ON Satellites(satid);
CREATE UNIQUE INDEX passes_stnid_idx ON Passes(stnid, aos);
CREATE UNIQUE INDEX jobs_stnid_idx ON Jobs(stnid, aos);
CREATE UNIQUE INDEX tles_satid_idx ON TLEs(noradid);


-- DEFINE TRIGGER FUNCTIONS FOR LISTEN/NOTIFY SERVICES
CREATE OR REPLACE FUNCTION orbit_notification()
RETURNS TRIGGER LANGUAGE PLPGSQL AS 
$$
BEGIN
    INSERT INTO Notifications (service) VALUES ('orbit');
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION optimization_notification()
RETURNS TRIGGER LANGUAGE PLPGSQL AS 
$$
BEGIN
    PERFORM pg_notify('optimization_notification', '');
    RETURN NEW;
END;
$$;


-- DEFINE TRIGGERS FOR LISTEN/NOTIFY SERVICES
CREATE OR REPLACE TRIGGER tle_trigger AFTER INSERT OR UPDATE OR DELETE ON TLEs
FOR EACH STATEMENT EXECUTE PROCEDURE orbit_notification();


CREATE OR REPLACE TRIGGER pass_trigger AFTER INSERT OR UPDATE OR DELETE ON Passes
FOR EACH STATEMENT EXECUTE PROCEDURE optimization_notification();


CREATE OR REPLACE TRIGGER task_trigger AFTER INSERT OR UPDATE OR DELETE ON Tasks
FOR EACH STATEMENT EXECUTE PROCEDURE optimization_notification();
