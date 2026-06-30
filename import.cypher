

//prevent duplicates, uniqueness constraint for star_hip-star's unique id
CREATE CONSTRAINT star_hip IF NOT EXISTS
FOR (s:Star)
REQUIRE s.hip IS UNIQUE;

CREATE CONSTRAINT constellation_name IF NOT EXISTS
FOR (c:Constellation)
REQUIRE c.constellation IS UNIQUE;

//index on star name for faster lookup
CREATE INDEX star_name IF NOT EXISTS
FOR (s:Star)
ON (s.name);

//load csv, null cunversions
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/stars_enriched.csv' AS row
WITH row
//filter invalid rows w/ no hip
WHERE row.hip IS NOT NULL AND row.hip <> ""
//avoids duplicates, if star doesnt exist-create it, if yes-use it
MERGE (s:Star {hip: toInteger(row.hip)})

SET
    s.name = row.proper,
    s.bf = row.bf,
    s.ra = CASE WHEN row.ra <> "" THEN toFloat(row.ra) END, //if ""->null
    s.dec = CASE WHEN row.dec <> "" THEN toFloat(row.dec) END,
    s.mag = CASE WHEN row.mag <> "" THEN toFloat(row.mag) END,
    s.absmag = CASE WHEN row.absmag <> "" THEN toFloat(row.absmag) END,
    s.dist = CASE WHEN row.dist <> "" THEN toFloat(row.dist) END,
    s.rv = CASE WHEN row.rv <> "" THEN toFloat(row.rv) END,
    s.spect = row.spect,
    s.lum = CASE WHEN row.lum <> "" THEN toFloat(row.lum) END,
    s.ci = CASE WHEN row.ci <> "" THEN toFloat(row.ci) END,
    s.x = CASE WHEN row.x <> "" THEN toFloat(row.x) END,
    s.y = CASE WHEN row.y <> "" THEN toFloat(row.y) END,
    s.z = CASE WHEN row.z <> "" THEN toFloat(row.z) END,
    s.vx = CASE WHEN row.vx <> "" THEN toFloat(row.vx) END,
    s.vy = CASE WHEN row.vy <> "" THEN toFloat(row.vy) END,
    s.vz = CASE WHEN row.vz <> "" THEN toFloat(row.vz) END,
    s.bayer = row.bayer,
    s.flam = CASE WHEN row.flam <> "" THEN toInteger(row.flam) END,
    s.var = row.var,
    s.var_min = CASE WHEN row.var_min <> "" THEN toFloat(row.var_min) END,
    s.var_max = CASE WHEN row.var_max <> "" THEN toFloat(row.var_max) END

MERGE (c:Constellation {name: row.constellation})

MERGE (s)-[:IN_CONSTELLATION]->(c);



//meteors

CREATE CONSTRAINT meteorite_id_unique IF NOT EXISTS
FOR (m:Meteorite)
REQUIRE m.id IS UNIQUE;
//querying m's year later so faster lookup
CREATE INDEX meteorite_year IF NOT EXISTS
FOR (m:Meteorite)
ON (m.year);

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/Meteorite_Landings.csv' AS row
WITH row
WHERE row.id IS NOT NULL AND row.id <> ""

MERGE (m:Meteorite {id: toInteger(row.id)})
SET
m.name = row.name,
m.mass = toFloat(row.`mass (g)`),
m.year = toInteger(row.year),
m.reclat = toFloat(row.reclat),
m.reclong =toFloat(row.reclong),
m.geolocation = row.geolocation;
//point for map visualising
MATCH (m:Meteorite)
WHERE m.reclat IS NOT NULL
  AND m.reclong IS NOT NULL
  AND trim(toString(m.reclat)) <> ''
  AND trim(toString(m.reclong)) <> ''
SET m.location = point({
    latitude: toFloat(m.reclat),
    longitude: toFloat(m.reclong)
});

//exoplanet stars, from a new csv, avoid duplicating
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

//matching with several identifiers if a star already exists
OPTIONAL MATCH (s:Star)
WHERE
    (row.hip IS NOT NULL AND s.hip = row.hip)
    OR (row.hd IS NOT NULL AND s.hd = row.hd)
    OR (row.gl IS NOT NULL AND s.gl = row.gl)
    OR (row.hostname IS NOT NULL AND (
        s.star_name = row.hostname OR s.proper = row.hostname
    ))

WITH row, s
WHERE s IS NULL

CREATE (ns:Star {

    star_name: row.hostname,

    spect: row.st_spectype,

    teff: CASE WHEN row.st_teff IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.st_teff) END,
    stellarMass: CASE WHEN row.st_mass IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.st_mass) END,
    stellarRadius: CASE WHEN row.st_rad IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.st_rad) END,
    metallicity: CASE WHEN row.st_met IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.st_met) END,
    surfaceGravity: CASE WHEN row.st_logg IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.st_logg) END,

    dist: CASE WHEN row.sy_dist IN ["", " ", "NA", "null"] THEN null ELSE toFloat(row.sy_dist) END,

    systemPlanetCount: CASE WHEN row.sy_pnum IN ["", " "] THEN null ELSE toInteger(row.sy_pnum) END,
    systemStarCount: CASE WHEN row.sy_snum IN ["", " "] THEN null ELSE toInteger(row.sy_snum) END
});

//exoplanets
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MERGE (p:Planet {name: row.pl_name})

SET
    p.radiusEarth = CASE WHEN row.pl_rade IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_rade) END,
    p.radiusJupiter = CASE WHEN row.pl_radj IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_radj) END,
    p.massEarth = CASE WHEN row.pl_bmasse IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_bmasse) END,
    p.massJupiter = CASE WHEN row.pl_bmassj IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_bmassj) END,

    p.eccentricity = CASE WHEN row.pl_orbeccen IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_orbeccen) END,
    p.insolation = CASE WHEN row.pl_insol IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_insol) END,
    p.equilibriumTemp = CASE WHEN row.pl_eqt IN ["", " ", "NA"] THEN null ELSE toFloat(row.pl_eqt) END,

    p.controversial = toInteger(coalesce(row.pl_controv_flag, "0"));//if null, then 0

//indexes
CREATE INDEX star_hip IF NOT EXISTS FOR (s:Star) ON (s.hip);

CREATE INDEX planet_name IF NOT EXISTS FOR (p:Planet) ON (p.name);


//for different identifiers, instead of writing MATCH WHERE hip OR hd OR gl OR ... we create this lookup key,takes on the first non-null value
MATCH (s:Star)
SET s.lookup =
coalesce(s.hip, s.hd, s.gl, s.star_name, s.proper);

CREATE INDEX star_lookup IF NOT EXISTS FOR (s:Star) ON (s.lookup);

//orbits rel
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MATCH (p:Planet {name: row.pl_name})

WITH row, p, coalesce(row.hip, row.hostname) AS key

MATCH (s:Star {lookup: key})

MERGE (p)-[r:ORBITS]->(s)

//relationship orbits' properties
SET
    r.periodDays = CASE WHEN row.pl_orbper IN ["", " ", "null"] THEN null ELSE toFloat(row.pl_orbper) END,
    r.semiMajorAxisAU = CASE WHEN row.pl_orbsmax IN ["", " ", "null"] THEN null ELSE toFloat(row.pl_orbsmax) END,
    r.eccentricity = CASE WHEN row.pl_orbeccen IN ["", " ", "null"] THEN null ELSE toFloat(row.pl_orbeccen) END;

//discovery
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MERGE (m:DiscoveryMethod {name: row.discoverymethod});

//discovered by rel
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MATCH (p:Planet {name: row.pl_name})
MATCH (m:DiscoveryMethod {name: row.discoverymethod})

MERGE (p)-[r:DISCOVERED_BY]->(m)

SET r.year = CASE WHEN row.disc_year IN ["", " ", "null"] THEN null ELSE toInteger(row.disc_year) END;

//facilities
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MERGE (f:Facility {name: row.disc_facility});


//planet discovered at facility
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MATCH (p:Planet {name: row.pl_name})
MATCH (f:Facility {name: row.disc_facility})

MERGE (p)-[r:DISCOVERED_AT]->(f)

//relationship property year
SET r.year = CASE WHEN row.disc_year IN ["", " ", "null"] THEN null ELSE toInteger(row.disc_year) END;

//system
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

MERGE (sys:System {name: row.hostname})

SET
    sys.numStars = CASE WHEN row.sy_snum IN ["", "null"] THEN null ELSE toInteger(row.sy_snum) END,
    sys.numPlanets = CASE WHEN row.sy_pnum IN ["", "null"] THEN null ELSE toInteger(row.sy_pnum) END,
    sys.distance = CASE WHEN row.sy_dist IN ["", "null"] THEN null ELSE toFloat(row.sy_dist) END;
//idx
CREATE INDEX system_name IF NOT EXISTS FOR (sys:System) ON (sys.name);


//star->system
LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/mimir-cmyk/neo4j-astro-db/refs/heads/main/PS_2026.05.12_10.06.39.csv' AS row

WITH row, coalesce(row.hip, row.hostname) AS key

MATCH (s:Star {lookup: key})
MATCH (sys:System {name: row.hostname})
MERGE (s)-[:PART_OF]->(sys);