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
CREATE TABLE IF NOT EXISTS Stations (
    stnid           UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    stnname         TEXT NOT NULL,
    latitude        FLOAT NOT NULL,
    longitude       FLOAT NOT NULL,
    altitude        FLOAT NOT NULL,
    minhorizon      FLOAT NOT NULL
);


CREATE TABLE IF NOT EXISTS Satellites (
    noradid         INTEGER UNIQUE PRIMARY KEY,
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


CREATE TABLE IF NOT EXISTS Tasks (
    taskid          UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    userid          UUID,
    stnid           UUID,
    noradid         INTEGER,
    duration        INTEGER,
    notbefore       TIMESTAMPTZ NOT NULL,
    deadline        TIMESTAMPTZ NOT NULL,
    priority        INTEGER NOT NULL,
    FOREIGN KEY(stnid) REFERENCES Stations(stnid),
    FOREIGN KEY(noradid) REFERENCES Satellites(noradid)
);


CREATE TABLE IF NOT EXISTS Passes (
    passid          UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    stnid           UUID NOT NULL,
    stnname         TEXT NOT NULL,
    noradid         INTEGER NOT NULL,
    satname         TEXT NOT NULL,
    azimuth         FLOAT NOT NULL,
    elevation       FLOAT NOT NULL,
    aos             TIMESTAMPTZ NOT NULL,
    los             TIMESTAMPTZ NOT NULL,
    FOREIGN KEY(stnid) REFERENCES Stations(stnid),
    FOREIGN KEY(noradid) REFERENCES Satellites(noradid)
);

CREATE TABLE IF NOT EXISTS Plans (
    taskid          UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    planid          UUID NOT NULL,
    stnid           UUID,
    noradid         INTEGER,
    notbefore       TIMESTAMPTZ NOT NULL,
    deadline        TIMESTAMPTZ NOT NULL,
    priority        INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS Jobs (
    jobid           UUID UNIQUE PRIMARY KEY DEFAULT uuid_generate_v4(),
    planid          UUID UNIQUE NOT NULL,
    stnid           UUID NOT NULL, 
    stnname         TEXT NOT NULL,
    noradid         INTEGER NOT NULL,
    satname         TEXT NOT NULL,
    azimuth         FLOAT NOT NULL,
    elevation       FLOAT NOT NULL,
    aos             TIMESTAMPTZ NOT NULL,
    los             TIMESTAMPTZ NOT NULL
);


CREATE TABLE IF NOT EXISTS TLEs (
    noradid         INTEGER NOT NULL PRIMARY KEY,
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
CREATE UNIQUE INDEX satellites_satid_idx ON Satellites(noradid);
CREATE UNIQUE INDEX tles_satid_idx ON TLEs(noradid);


-- DEFINE TRIGGER FUNCTIONS FOR LISTEN/NOTIFY SERVICES
CREATE OR REPLACE FUNCTION orbital_prediction()
RETURNS TRIGGER LANGUAGE PLPGSQL AS 
$$
BEGIN
    INSERT INTO Notifications (service) VALUES ('orbit');
    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION optimization()
RETURNS TRIGGER LANGUAGE PLPGSQL AS 
$$
BEGIN
    DELETE FROM Plans;
    DELETE FROM Jobs;
    INSERT INTO Notifications (service) VALUES ('optimization');
    PERFORM pg_notify('optimization', '');
    RETURN NEW;
END;
$$;


-- DEFINE TRIGGERS FOR LISTEN/NOTIFY SERVICES
CREATE OR REPLACE TRIGGER tle_trigger AFTER INSERT OR UPDATE OR DELETE ON TLEs
FOR EACH STATEMENT EXECUTE PROCEDURE orbital_prediction();


CREATE OR REPLACE TRIGGER pass_trigger AFTER INSERT OR UPDATE OR DELETE ON Passes
FOR EACH STATEMENT EXECUTE PROCEDURE optimization();


CREATE OR REPLACE TRIGGER task_trigger AFTER INSERT OR UPDATE OR DELETE ON Tasks
FOR EACH STATEMENT EXECUTE PROCEDURE optimization();
