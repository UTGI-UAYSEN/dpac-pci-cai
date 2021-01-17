//////////////////////////////////
// Parámetros generales

match (p:ParamsJCE) detach delete p;

MERGE (n1:ParamsJCE { id: "cobertura",
	`Amplia`: 11, `Mediana`: 6, `Acotada`: 3, `Mínima`: 1
})

MERGE (n2:ParamsJCE { id: "rol",
	`Responsable`: 4, `Aprobador`: 1, `Soporte`: 2, `Consultado`: 1, `Informado`: 0.5
})

MERGE (n3:ParamsJCE { id: "tipo-capacidad",
	`Estratégica`: 1, `Táctica Estratégica`: 2, `Táctica`: 3, `Operativa`: 10, `Gestión Académica`: 6
})

MERGE (n4:ParamsJCE { id: "participacion",
	`Normal`: 1, `Esporádica`: 0.5, `Puntual`: 0.2
})

MERGE (n5:ParamsJCE { id: "complejidad",
	`Alta`: 2, `Normal`: 1, `Baja`: 0.5
})

MERGE (n6:ParamsJCE { id: "naturaleza",
	`Analítica`: 1, `Técnica`: 2, `Administrativa`: 3
})

return n1, n2, n3, n4, n5, n6

//////////////////////////////////
// Crea capacidades

CALL apoc.load.json("file:///datos/capacidades.json") YIELD value
merge (c:TipoCapacidad { id: value.id })
set c.nombre = value.nombre, c.ambito = value.ambito
return c

//////////////////////////////////
// Crea actores

CALL apoc.load.json("file:///datos/actor.json") YIELD value
merge (a:Actor { cai: value.cai })
set a.nombre = value.nombre

with a, value
UNWIND value.capacidades as cap
match (tc:TipoCapacidad { id: cap.tipo })
merge (a)<-[:CAPACIDAD_DE]-(c:Capacidad { id: value.cai + '-' + cap.id })<-[:TIPO_DE]-(tc)
set c.desc = cap.desc

with a, value where value.depende is not null
match (t:Actor { cai: value.depende })
merge (a)-[:DEPENDE]->(t)

with value
match (a:Actor)
optional match (a)<-[:CAPACIDAD_DE]-(c:Capacidad)
return a, c

//////////////////////////////////
// Crea acciones

WITH [ 'DAC', 'DPAC', 'DAF', 'DI', 'DVcM', 'Rectoria', 'CI' ] as files
UNWIND files as file
CALL apoc.load.json('file:///datos/acciones_' + file + '.json') YIELD value

match (c1:Actor { cai: value.area })
match (c2:Actor { cai: value.responsable })

merge (a:Accion { id: value.area + '-' + value.id })
set a.titulo = value.titulo, a.objetivo = value.objetivo, a.tipo = value.tipo
merge (a)-[x:CORRESPONDE_A]->(c1)
merge (a)-[y:REALIZADA_POR]->(c2)

with a, value, c1, c2

unwind value.tacticas as i
merge (a)-[:REALIZADA_CON]->(nt:Tactica {id: value.area + '-' + value.id + '-' + i.id})
set	nt.cod = i.id,
		nt.tipo = i.tipo,
		nt.desc = i.desc,
		nt.cobertura = (case when i.cobertura is not null then i.cobertura else "Amplia" end),
		nt.naturaleza = (case when i.naturaleza is not null then i.naturaleza else "Analítica" end),
		nt.prioridad = (case when i.prioridad is not null then i.prioridad else "Normal" end)

with a, value, c1, c2, nt, i
unwind i.actores as j
unwind j.capacidades as k 
match (c:Capacidad {id: j.cai + '-' + k })
merge (nt)-[:UTILIZA { rol: j.rol, participacion: (case when j.participacion is not null then j.participacion else "Normal" end) }]->(c)

with a, value, c1, c2
optional match (a)-[:REALIZADA_CON]->(t:Tactica)

return a, t, c1, c2

//////////////////////////////////
// Crea IOs y MDVs

//WITH [ 'DAC', 'DPAC', 'DAF', 'DI', 'DVcM', 'Rectoria', 'CI' ] as files
WITH [ 'CI' ] as files
UNWIND files as file
CALL apoc.load.json('file:///datos/acciones_' + file + '.json') YIELD value

unwind value.tacticas as tactica
match (t:Tactica {id: value.area + '-' + value.id + '-' + tactica.id})

foreach(mdv in tactica.verificadores |
	merge (t)-[:RESPALDADA_CON]->(n1:MdV { 
		nombre: mdv.nombre, 
		//estandar: reduce(text = '', e IN mdv.estandar | text + e + '\n')
		estandar: mdv.estandar
	})

	set n1.plazo = (CASE WHEN mdv.plazo is not null then mdv.plazo else null end)
)

foreach(io in tactica.ios |
	merge (t)-[:MONITOREADA_CON]->(n2:IO { nombre: io.nombre, formula: io.formula, meta: io.meta })
)

with t
match (a:Accion)-[:REALIZADA_CON]->(t)
optional match (t)-[:RESPALDADA_CON]->(mdv:MdV)
optional match (t)-[:MONITOREADA_CON]->(io:IO)
return a, t, mdv, io

//////////////////////////////////
// Crea directrices

CALL apoc.load.json("file:///datos/directriz.json") YIELD value

UNWIND value.instrumentos AS i
merge (in:Instrumento {id: i.id, nombre: i.nombre})

with value
UNWIND value.directrices AS d
match (in:Instrumento {id: d.parteDe})
merge (dn:Directriz {id: d.id, desc: d.desc})-[:PARTE_DE]->(in)

with value, in
UNWIND value.indicadores AS i
match (dn:Directriz {id: i.tributaA})
merge (id:Indicador {id: i.id, nombre: i.nombre})-[:TRIBUTA_A]->(dn)

with in, dn, id
return in, dn




