--1
select upper(e.edi_nombre_edificio) AS "NOMBRE EDIFICIO", count(d.nro_departamento) as "TOTAL DEPTOS",
sum(case when d.total_dormitorios=1 then 1 else 0 end) as "TOTAL DEPTOS 1 DORMITORIO",
sum(case when d.total_dormitorios=2 then 1 else 0 end) as "TOTAL DEPTOS 2 DORMITORIOS",
sum(case when d.total_dormitorios=3 then 1 else 0 end) as "TOTAL DEPTOS 3 DORMITORIOS",
sum(case when d.total_dormitorios=4 then 1 else 0 end) as "TOTAL DEPTOS 4 DORMITORIOS",
sum(case when d.total_dormitorios=5 then 1 else 0 end) as "TOTAL DEPTOS 5 DORMITORIOS"
from departamento d join edificio e on(d.id_edificio=e.id_edificio)
group by e.edi_nombre_edificio
order by e.edi_nombre_edificio;

--2
select upper(e.edi_nombre_edificio) as "NOMBRE EDIFICIO", c.nombre_comuna as comuna, 
to_char(a.adm_numrun, '99G999G999')||'-'||a.adm_dvrun as "RUN ADMINISTRADOR", 
initcap(a.adm_pnombre||' '||a.adm_snombre||' '||a.adm_apellido_paterno||' '||a.adm_apellido_materno) as "NOMBRE ADMINISTRADOR", 
count(distinct d.nro_departamento) as "TOTAL DEPARTAMENTOS",
count(distinct d.nro_departamento)-count(distinct p.nro_departamento) as "TOTAL DEPTOS NO CANCELAN CG"
from edificio e join comuna c on(e.id_comuna = c.id_comuna)
    join administrador a on(e.adm_numrun = a.adm_numrun)
    join departamento d on(e.id_edificio=d.id_edificio)
    join pago_gasto_comun p on(e.id_edificio=p.id_edificio)
having p.pco_periodo = to_char(sysdate, 'YYYYMM')-1
group by e.edi_nombre_edificio, c.nombre_comuna, a.adm_numrun, a.adm_dvrun, 
    a.adm_pnombre, a.adm_snombre, a.adm_apellido_paterno, a.adm_apellido_materno, p.pco_periodo
order by c.nombre_comuna;

--3
select upper(e.edi_nombre_edificio) as edificio, g.nro_departamento as departamento, 
substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4) as "PERIODO COBRO", 
g.gas_fecha_pago as "FECHA DE PAGO", p.pgc_fecha_cancelacion as "FECHA CANCELACIÓN", 
to_char(p.pgc_monto_cancelado, '$999G999') as "TOTAL GASTO COMÚN",
p.pgc_fecha_cancelacion-g.gas_fecha_pago as "DIAS MORA",
case 
    when (p.pgc_fecha_cancelacion-g.gas_fecha_pago) 
        between 1 and 9 then 'Se le cobrará como multa del periodo'||' '||
            to_char(add_months(to_date((substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4)),'mm/yyyy'),1), 'mm/yyyy')||' '||
            to_char(round(0.02*p.pgc_monto_cancelado), '$999G999')
    when (p.pgc_fecha_cancelacion-g.gas_fecha_pago) 
        between 10 and 15 then 'Se le cobrará como multa del periodo'||' '||
            to_char(add_months(to_date((substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4)),'mm/yyyy'),1), 'mm/yyyy')||' '||
            to_char(round(0.04*p.pgc_monto_cancelado), '$999G999')
    when (p.pgc_fecha_cancelacion-g.gas_fecha_pago) 
        between 16 and 20 then 'Se le cobrará como multa del periodo'||' '||
            to_char(add_months(to_date((substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4)),'mm/yyyy'),1), 'mm/yyyy')||' '||
            to_char(round(0.06*p.pgc_monto_cancelado), '$999G999')
    when (p.pgc_fecha_cancelacion-g.gas_fecha_pago) 
        between 21 and 25 then 'Se le cobrará como multa del periodo'||' '||
            to_char(add_months(to_date((substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4)),'mm/yyyy'),1), 'mm/yyyy')||' '||
            to_char(round(0.08*p.pgc_monto_cancelado), '$999G999') 
    else 'Se le cobrará como multa del periodo'||' '||
            to_char(add_months(to_date((substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4)),'mm/yyyy'),1), 'mm/yyyy')||' '||
            to_char(round(0.1*p.pgc_monto_cancelado), '$999G999')
    end as "OBSERVACIÓN COBRO MULTAS"
from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
    join pago_gasto_comun p on(g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento and g.id_edificio=p.id_edificio)
where g.pco_periodo = to_char(sysdate, 'YYYYMM')-1 and p.pgc_fecha_cancelacion-g.gas_fecha_pago>0
order by p.pgc_fecha_cancelacion-g.gas_fecha_pago desc;

--4
select upper(e.edi_nombre_edificio) as edificio, g.nro_departamento as departamento,
to_char(g.gas_gasto_total, '$999G999') as "TOTAL GASTO COMUN", 
to_char(r.rpgc_numrun,'09G999G999')||'-'||r.rpgc_dvrun as "RUN RESPONSABLE", 
initcap(r.rpgc_pnombre||' '||r.rpgc_snombre||' '||r.rpgc_apellido_paterno||' '||r.rpgc_apellido_materno) as "NOMBRE RESPONSABLE", 
t.tp_descripcion as "DUEÑO/ARRIENDA/REPRESENTANTE"
from edificio e
    join gasto_comun g on(e.id_edificio = g.id_edificio)
    join responsable_pago_gasto_comun r on(g.rpgc_numrun = r.rpgc_numrun)
    join tipo_persona t on(r.id_tipo_persona = t.id_tipo_persona)
where g.pco_periodo = to_char(sysdate, 'YYYYMM')-1
order by e.edi_nombre_edificio, g.nro_departamento;

--5
select upper(e.edi_nombre_edificio) as edificio, g.nro_departamento as departamento, 
substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4) as "PERIODO COBRO", 
to_char(g.gas_gasto_total, '$999G999') as "TOTAL GASTO COMUN", to_char(nvl(p.pgc_monto_cancelado, 0), '$999G999') as "MONTO CANCELADO", 
to_char(g.gas_gasto_total-nvl(p.pgc_monto_cancelado, 0), '$999G999') as "DEUDA"
from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
    full join pago_gasto_comun p on(e.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento)
where g.pco_periodo <= to_char(sysdate, 'YYYYMM')-1 and g.gas_gasto_total-nvl(p.pgc_monto_cancelado, 0)>0
order by substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4), e.edi_nombre_edificio, g.gas_gasto_total-nvl(p.pgc_monto_cancelado, 0) desc;

--6
select upper(e.edi_nombre_edificio) as edificio, g.nro_departamento as departamento, 
substr(g.pco_periodo, 5)||'/'||substr(g.pco_periodo, 0, 4) as "PERIODO COBRO", g.gas_fecha_pago as "FECHA DE PAGO", 
p.pgc_fecha_cancelacion as "FECHA EN QUE SE CANCELÓ", g.gas_gasto_total as "TORAL GASTO COMUN", 
p.pgc_monto_cancelado as "MONTO CANCELADO", f.fpa_descripcion as "FORMA DE PAGO"
from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
    join pago_gasto_comun p on(e.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento)
    join forma_pago f on(p.id_forma_pago=f.id_forma_pago)
where g.pco_periodo = to_char(sysdate, 'YYYYMM')-1
order by e.edi_nombre_edificio, g.nro_departamento;

--7
select g.pco_periodo, e.edi_nombre_edificio, g.nro_departamento
from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
    full join pago_gasto_comun p on(e.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento)
where nvl(p.pgc_monto_cancelado, 0)=0 and g.pco_periodo = to_char(sysdate, 'YYYYMM')-1
order by e.edi_nombre_edificio, g.nro_departamento;


--8
select upper(e.edi_nombre_edificio) as "NOMBRE EDIFICIO", c.nombre_comuna as "COMUNA", 
g.gas_fecha_desde||'-'||g.gas_fecha_hasta as "PERIODO COBRO", 
count(g.nro_departamento) as "TOTAL DEPARTAMENTOS", to_char(sum(nvl(g.gas_fondo_reserva, 0)), '$9G999G999') as "FONDO RESERVA", 
to_char(sum(nvl(g.gas_agua_individual, 0)), '$9G999G999') as "AGUA INDIVIDUAL", 
to_char(sum(nvl(g.gas_combustible_individual, 0)), '$9G999G999') as "COMBUSTIBLE INDIVIDUAL",
to_char(sum(nvl(g.gas_lavanderia, 0)), '$9G999G999') as "LAVANDERIA", 
to_char(sum(nvl(g.gas_eventos, 0)), '$9G999G999') as "EVENTOS", 
to_char(sum(nvl(g.gas_gastos_atrasados, 0)), '$9G999G999') as "GASTOS ATRASADOS", 
to_char(sum(nvl(g.gas_multas, 0)), '$9G999G999') as "MULTAS", 
to_char(sum(nvl(g.gas_gasto_total, 0)), '$99G999G999') as "TOTAL GASTOS COMUNES"
from edificio e join comuna c on(e.id_comuna=c.id_comuna)
    join gasto_comun g on(e.id_edificio=g.id_edificio)
where substr(g.pco_periodo, 0, 4)=extract(year from sysdate)-1
group by e.edi_nombre_edificio, c.nombre_comuna, g.gas_fecha_desde, g.gas_fecha_hasta
order by g.gas_fecha_desde, e.edi_nombre_edificio;

--9
select e.edi_nombre_edificio as edificio, g.nro_departamento as departamento, 
to_char(sum(g.gas_gasto_total-nvl(pgc_monto_cancelado, 0)),'$999G999') as "DEUDA ACUMULADA"
from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
    full join pago_gasto_comun p on(e.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento)
where g.pco_periodo <= to_char(sysdate, 'YYYYMM')-2 and nvl(pgc_monto_cancelado, 0)>=0
having sum(g.gas_gasto_total-nvl(pgc_monto_cancelado, 0))>(select avg(sum(g.gas_gasto_total-nvl(pgc_monto_cancelado, 0)))
                    from edificio e join gasto_comun g on(e.id_edificio=g.id_edificio)
                        full join pago_gasto_comun p on(e.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo and g.nro_departamento=p.nro_departamento)
                    where g.pco_periodo <= to_char(sysdate, 'YYYYMM')-2 and nvl(pgc_monto_cancelado, 0)>=0
                    group by g.nro_departamento)
group by e.edi_nombre_edificio, g.nro_departamento
order by e.edi_nombre_edificio, g.nro_departamento;

--10
--(SE DEBEN EJECUTAR AMBOS SCRIPTS DE FORMA SIMULTÁNEA)
update gasto_comun_pruebaestpago g
set id_estado_pago = (select 
                        case 
                            when g.gas_gasto_total=p.pgc_monto_cancelado then 1
                            when g.gas_gasto_total>p.pgc_monto_cancelado then 2
                            else 3
                        end
                        from pago_gasto_comun_pruebaestpago p
                        where g.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo 
                            and g.nro_departamento=p.nro_departamento);
                        
update gasto_comun_pruebaestpago g
set id_estado_pago = (select 1
                        from pago_gasto_comun_pruebaestpago p 
                        where g.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo 
                        and g.nro_departamento=p.nro_departamento and g.gas_gasto_total=p.pgc_monto_cancelado)
                    ||(select 2
                        from pago_gasto_comun_pruebaestpago p 
                        where g.id_edificio=p.id_edificio and g.pco_periodo=p.pco_periodo 
                        and g.nro_departamento=p.nro_departamento and g.gas_gasto_total>p.pgc_monto_cancelado)
                    ||(select 3 
                        from gasto_comun_pruebaestpago g2
                        where g.id_edificio=g2.id_edificio and g.pco_periodo=g2.pco_periodo 
                        and g.nro_departamento=g2.nro_departamento and g.id_estado_pago is null);

--11
--11.1
--(SE MUESTRA EL LISTADO TODOS LOS REGISTROS GRABADOS (EN AMBAS TABLAS))
select pco_periodo, id_edificio, nro_departamento, pgc_monto_cancelado, id_forma_pago
from pago_gasto_comun_mensual
where pco_periodo = 201909
union
select pco_periodo, id_edificio, nro_departamento, pgc_monto_cancelado, id_forma_pago
from pago_gasto_comun
where pco_periodo = 201909;

--11.2
--(SOLO LOS GRABADOS EN LA TABLA PAGO_GASTO_COMUN_MENSUAL)
select pco_periodo, id_edificio, nro_departamento, pgc_monto_cancelado, id_forma_pago
from pago_gasto_comun_mensual
where pco_periodo = 201909
minus
select pco_periodo, id_edificio, nro_departamento, pgc_monto_cancelado, id_forma_pago
from pago_gasto_comun
where pco_periodo = 201909;

--11.3
--(PRIMERO SE ELIMINAN LOS REGISTROS CON FECHA CANCELACION EQUIVOCADA)
delete from pago_gasto_comun p
where p.pgc_fecha_cancelacion <> (select pm.pgc_fecha_cancelacion from pago_gasto_comun_mensual pm
                        where pm.pco_periodo=p.pco_periodo and pm.id_edificio=p.id_edificio 
                        and pm.nro_departamento=p.nro_departamento and pm.pgc_monto_cancelado=p.pgc_monto_cancelado
                        and pm.id_forma_pago=p.id_forma_pago);
                        
--(SE INSERTAN TODAS LAS FILAS QUE FALTAN (INCLUYENDO CON FECHA CANCELACION EQUIVOCADA))
insert into pago_gasto_comun
(select *
from pago_gasto_comun_mensual
where pco_periodo = 201909
minus
select *
from pago_gasto_comun
where pco_periodo = 201909);
