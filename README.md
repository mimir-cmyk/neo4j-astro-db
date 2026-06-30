This project is an interactive astronomy dashboard developed with Neo4j and NeoDash.
The dataset is based on the HYG Star Database, NASA exoplanet archive and Kaggle and was enriched with constellation names from Stellarium application. 
Nodes: Star , Constellation , Meteorite ,Planet , DiscoveryMethod , Facility, System .
Relationships: ORBITS links planets to their host stars . IN_CONSTELLATION connects stars to constellations. PART_OF links stars to systems. DISCOVERED_BY connects planets to discovery methods. DISCOVERED_AT links planets to facilities and also shows the year of discovery.
