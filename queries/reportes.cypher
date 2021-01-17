//////////////////////////////////
// Listado de capacidades

CALL apoc.export.csv.query("match (a1:Actor)<-[:DEPENDE]-(a2:Actor)<-[:DEPENDE]-(a3:Actor)
match (a4:Actor)<-[:DEPENDE]-(a5:Actor) where not ()<-[:DEPENDE]-(a4)

CALL {
 WITH a4
 match (a4)<-[:CAPACIDAD_DE]-(c:Capacidad)<-[:TIPO_DE]-(tc:TipoCapacidad)
 return a4.nombre as Actor1, null as Actor2, null as Actor3, tc.ambito as AmbitoCapacidad, tc.nombre as TipoCapacidad, c.desc as NombreCapacidad

 UNION
 
 WITH a4, a5
 match (a5)<-[:CAPACIDAD_DE]-(c:Capacidad)<-[:TIPO_DE]-(tc:TipoCapacidad)
 return a4.nombre as Actor1, a5.nombre as Actor2, null as Actor3, tc.ambito as AmbitoCapacidad, tc.nombre as TipoCapacidad, c.desc as NombreCapacidad

 UNION
  
 WITH a1, a2, a3
 match (a3)<-[:CAPACIDAD_DE]-(c:Capacidad)<-[:TIPO_DE]-(tc:TipoCapacidad)
 return a1.nombre as Actor1, a2.nombre as Actor2, a3.nombre as Actor3, tc.ambito as AmbitoCapacidad, tc.nombre as TipoCapacidad, c.desc as NombreCapacidad
}

return distinct Actor1, Actor2, Actor3, AmbitoCapacidad, TipoCapacidad, NombreCapacidad",
'reporte_capacidades.csv', {delim: ';'});

//////////////////////////////////
// Reporte de carga de capacidades

CALL apoc.export.csv.query("match (ac:Actor)<-[:CAPACIDAD_DE]-(c:Capacidad)<-[x:UTILIZA]-(t:Tactica)<-[:REALIZADA_CON]-(a:Accion)
match (c)<-[:TIPO_DE]-(tc:TipoCapacidad)
match (dr:Actor)<-[:CORRESPONDE_A]-(a)
match (um:Actor)<-[:REALIZADA_POR]-(a)

call {
 with ac, c, x, t, a, tc
 match (ac2:Actor)<-[:CAPACIDAD_DE]-(oct:Capacidad)<-[:TIPO_DE]-(tc2:TipoCapacidad)
 where c.id = 'multiple-todos-tacticos' and (tc2.id = 'tactica' or tc2.id = 'tactica-estrategica') and ac2.cai <> 'multiple' and not (oct)<-[:UTILIZA]-(t)<-[:REALIZADA_CON]-(a)
 return 'Todos tácticos' as Tipo_Seleccion, ac2.cai as CAI_Actor, ac2.nombre as Nombre_Actor, oct.desc as Capacidad, tc2.nombre as Tipo_Capacidad
 
 union
 
 with ac, c, x, t, a, tc
 match (ac2:Actor)<-[:CAPACIDAD_DE]-(oct:Capacidad)<-[:TIPO_DE]-(tc2:TipoCapacidad)
 where c.id = 'multiple-todos-estrategicos' and tc2.id = 'estrategica' and ac2.cai <> 'multiple' and not (oct)<-[:UTILIZA]-(t)<-[:REALIZADA_CON]-(a)
 return 'Todos estratégicos' as Tipo_Seleccion, ac2.cai as CAI_Actor, ac2.nombre as Nombre_Actor, oct.desc as Capacidad, tc2.nombre as Tipo_Capacidad
 
 union
 
 with ac, c, x, t, a, tc
 match (ac2:Actor)<-[:CAPACIDAD_DE]-(oct:Capacidad)<-[:TIPO_DE]-(tc2:TipoCapacidad)
 where c.id = 'multiple-todos-gestion-academica' and tc2.id = 'gestion' and ac2.cai <> 'multiple' and not (oct)<-[:UTILIZA]-(t)<-[:REALIZADA_CON]-(a)
 return 'Todos gestión académica' as Tipo_Seleccion, ac2.cai as CAI_Actor, ac2.nombre as Nombre_Actor, oct.desc as Capacidad, tc2.nombre as Tipo_Capacidad
 
 union

 with ac, c, x, t, a, tc
 match (ac)<-[:CAPACIDAD_DE]-(c)<-[x]-(t)<-[:REALIZADA_CON]-(a)
 match (c)<-[:TIPO_DE]-(tc)
 where ac.cai <> 'multiple'
 return 'Específico' as Tipo_Seleccion, ac.cai as CAI_Actor, ac.nombre as Nombre_Actor, c.desc as Capacidad, tc.nombre as Tipo_Capacidad
}

match (n1:ParamsJCE { id: 'cobertura' })
match (n2:ParamsJCE { id: 'rol' })
match (n3:ParamsJCE { id: 'tipo-capacidad' })
match (n4:ParamsJCE { id: 'participacion' })
match (n5:ParamsJCE { id: 'complejidad' })
match (n6:ParamsJCE { id: 'naturaleza' })

CALL { 
	with t 
	return 
		t.desc as Tactica, 
		t.tipo as Tipo_Tactica, 
		t.cobertura as Cobertura_Tactica,
		t.naturaleza as Naturaleza_Tactica,
		(case when t.complejidad is not null then t.complejidad else 'Normal' end) as Complejidad_Tactica
}
CALL { with x return x.rol as Rol_Capacidad, x.participacion as Participacion_Capacidad }
CALL {
	with 
		Cobertura_Tactica,
		Naturaleza_Tactica,
		Participacion_Capacidad, 
		Rol_Capacidad, 
		Tipo_Capacidad,
		n1, n2, n3, n4, n6
	return
		n1[Cobertura_Tactica] * n4[Participacion_Capacidad] as Meses,
		n2[Rol_Capacidad] as Sems,
		n3[Tipo_Capacidad] * (case when Tipo_Capacidad = 'Operativa' and (Rol_Capacidad = 'Responsable' or Rol_Capacidad = 'Soporte') then n6[Naturaleza_Tactica] else 1 end) as Hrs        
}

return 
	Tipo_Seleccion,
	dr.cai as Area_POA,
	um.cai as Unidad_Responsable,
	CAI_Actor,
	Nombre_Actor,
	Capacidad,
	a.tipo as Tipo_Accion,
	a.id as ID_Accion,
	a.titulo as Accion,
	a.objetivo as Objetivo_Accion,
	t.cod as Cod_Tactica,	
	Tactica, 
	Tipo_Tactica, 
	Cobertura_Tactica, 
	Complejidad_Tactica,	
	t.prioridad as Prioridad_Tactica,	
	case when Tipo_Capacidad <> 'Operativa' then '-' else Naturaleza_Tactica end as Naturaleza_Tactica,
	Rol_Capacidad, 
	Participacion_Capacidad, 
	Tipo_Capacidad,
	apoc.number.format(Meses, '0.##########') as Meses,
	apoc.number.format(Sems, '0.##########') as Sems,
	apoc.number.format(Hrs, '0.##########') as Hrs,
	apoc.number.format(Meses * Sems * Hrs * n5[Complejidad_Tactica], '0.##########') as Hrs_Anio,
	apoc.number.format((Meses * Sems * Hrs * n5[Complejidad_Tactica]) / 1716.0, '0.##########') as JCE",
'reporte_uso_capacidades.csv', {delim: ';'});

//////////////////////////////////
// Reporte IOs (funciones)

CALL apoc.export.csv.query("match (io:IO)<-[:MONITOREADA_CON]-(t:Tactica)<-[:REALIZADA_CON]-(a:Accion)
match (dr:Actor)<-[:CORRESPONDE_A]-(a)
match (um:Actor)<-[:REALIZADA_POR]-(a)
optional match (mdv:MdV)<-[:RESPALDADA_CON]-(t)
where t.tipo = 'Función'

unwind mdv.estandar as Estandares_MDV

return 
	dr.cai as Area_POA,
	um.cai as Unidad_Responsable,
	a.tipo as Tipo_Accion,
	a.id as ID_Accion,
	a.titulo as Accion,
	a.objetivo as Objetivo_Accion,
	t.cod as Cod_Tactica,	
	t.desc as Tactica,
	t.prioridad as Prioridad_Tactica,
	io.nombre as Nombre_IO,
	io.formula as Formula_IO,
	io.meta as Meta_IO,
	mdv.nombre as Nombre_MDV,
	Estandares_MDV",
'reporte_ios.csv', {delim: ';'});

//////////////////////////////////
// Reporte MdVs (hitos)

CALL apoc.export.csv.query("match (mdv:MdV)<-[:RESPALDADA_CON]-(t:Tactica)<-[:REALIZADA_CON]-(a:Accion)
match (dr:Actor)<-[:CORRESPONDE_A]-(a)
match (um:Actor)<-[:REALIZADA_POR]-(a)
where t.tipo = 'Hito'

unwind mdv.estandar as Estandares_MDV

return 
	dr.cai as Area_POA,
	um.cai as Unidad_Responsable,
	a.tipo as Tipo_Accion,
	a.id as ID_Accion,
	a.titulo as Accion,
	a.objetivo as Objetivo_Accion,
	t.cod as Cod_Tactica,	
	t.desc as Tactica,
	t.prioridad as Prioridad_Tactica,
	mdv.nombre as Nombre_MDV,
	mdv.plazo as Plazo_MDV,
	case mdv.plazo 
		when 'mar' then 1
		when 'abr' then 2
		when 'may' then 3
		when 'jun' then 4
		when 'jul' then 5
		when 'ago' then 6
		when 'sep' then 7
		when 'oct' then 8
		when 'nov' then 9
		when 'dic' then 10
		when 'ene' then 11
	end as Plazo_MDV_Num,
	Estandares_MDV",
'reporte_mdvs_hitos.csv', {delim: ';'});

//////////////////////////////////
// Reporte de combinatorias JCE

match (ct:ParamsJCE { id: 'cobertura' })
match (rc:ParamsJCE { id: 'rol' })
match (tc:ParamsJCE { id: 'tipo-capacidad' })
match (pc:ParamsJCE { id: 'participacion' })
match (ca:ParamsJCE { id: 'complejidad' })

unwind [x IN keys(ct) WHERE x <> 'id'] as kct
unwind [x IN keys(rc) WHERE x <> 'id'] as krc
unwind [x IN keys(tc) WHERE x <> 'id'] as ktc
unwind [x IN keys(pc) WHERE x <> 'id'] as kpc
unwind [x IN keys(ca) WHERE x <> 'id'] as kca

return
	kct as Cobertura_Tactica,
	krc as Rol_Capacidad,
  ktc as Tipo_Capacidad,
  kpc as Participacion_Capacidad,
  kca as Complejidad_Tactica,
  ((ct[kct] * pc[kpc] * rc[krc] * tc[ktc] * ca[kca]) / 1716.0) as JCE

//////////////////////////////////
// Indicadores estructura POA

CALL {
	match (ac:Actor)
	with ac, size((ac)-[:CORRESPONDE_A]-()) as relAccion
	where size((ac)-[:CORRESPONDE_A]-()) <> 0
	return avg(relAccion) AS Acciones_Por_Direccion
}

CALL {
	match (ac:Actor)
	with ac, size((ac)-[:REALIZADA_POR]-()) as relAccion
	where size((ac)-[:REALIZADA_POR]-()) <> 0
	return avg(relAccion) AS Acciones_Por_Unidad
}

CALL {
	match (a:Accion)
	with a, size((a)-[:REALIZADA_CON]-()) as relTactica
	return avg(relTactica) AS Tacticas_Por_Accion
}

CALL {
	match (t:Tactica)
	with t, size((t)-[:UTILIZA]-()) as relCapacidad
	return avg(relCapacidad) as Capacidades_Por_Tactica
}

return Acciones_Por_Direccion, Acciones_Por_Unidad, Tacticas_Por_Accion, Capacidades_Por_Tactica

//////////////////////////////////
// Tabla acciones / tácticas

match (a:Accion)-[:REALIZADA_CON]->(t:Tactica)
return a.id as Id_Accion, '-' as Cod_Tactica

union

match (a:Accion)-[:REALIZADA_CON]->(t:Tactica)
return a.id as Id_Accion, t.cod as Cod_Tactica