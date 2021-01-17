//////////////////////////////////
// Limpia tipos de capacidades y relacionados

match (tc:TipoCapacidad) detach delete tc

//////////////////////////////////
// Limpia actor y todos sus relacionados

match (a:Actor)
optional match (a)<-[:CAPACIDAD_DE]-(c:Capacidad)

detach delete a, c

//////////////////////////////////
// Limpia acciones y relacionados

match (ac:Actor)<-[:CORRESPONDE_A]-(a:Accion)-[:REALIZADA_CON]->(t:Tactica)
detach delete a, t

//////////////////////////////////
// Limpia IOs y MDVs

match (io:IO)
match (mdv:MdV)

detach delete io, mdv
