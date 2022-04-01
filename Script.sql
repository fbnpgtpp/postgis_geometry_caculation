--ST_SetSRID(geometry geom, integer srid)
--ST_Transform(geometry g1, integer srid);
--ST_MakePolygon(geometry linestring)
--ST_LineMerge(geometry amultilinestring)
--ST_Area(geometry g1)
--ST_Length(geometry a_2dlinestring)
--ST_IsClosed(geometry g)
--ST_AddPoint(geometry linestring, geometry point)
--ST_StartPoint(geometry geomA)

with cte1 as (
select g.id, g.geom, u.srid, p2.modelname, u2.unit area_unit, u2.factor_m2 
from gps g 
join parcelwaves p ON g.parcelwaveid = p.id
join plantationmodels p2 on p.plantationmodelid = p2.id
join parcels p3 on p.parcelid = p3.id
join farmers f on p3.farmerid = f.id
join units u2 on f.areaunitid  = u2.id
join utm_zone u 
on ST_Contains(u.geom, st_setsrid(g.geom,4326)) --Spatial join
)

select id, modelname, area_unit,--st_setsrid(geom,4326) as geom
case 
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and ST_IsClosed((st_linemerge(geom))) -- planting model polygon fermé
		then ST_area(st_makepolygon(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))) * factor_m2 
	when modelname ilike '%m1%' -- planting model ligne
		then st_area(st_buffer(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),2.5, 'endcap=flat join=mitre')) * factor_m2
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and not ST_IsClosed((st_linemerge(geom))) -- planting model polygon non fermé
		then ST_area(st_makepolygon(st_addpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),st_startpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))))) * factor_m2 
end area_localunit,
case 
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and ST_IsClosed((st_linemerge(geom))) -- planting model polygon fermé
		then ST_area(st_makepolygon(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))) 
	when modelname ilike '%m1%' -- planting model ligne
		then st_area(st_buffer(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),2.5))
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and not ST_IsClosed((st_linemerge(geom))) -- planting model polygon non fermé
		then ST_area(st_makepolygon(st_addpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),st_startpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid))))))
end area_m2,
case 
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and ST_IsClosed((st_linemerge(geom))) -- planting model polygon fermé
		then ST_length(ST_ExteriorRing(st_makepolygon(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))))
	when modelname ilike '%m1%' -- planting model ligne
		then st_length(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))
	when (modelname ilike '%m2%' 
		or modelname ilike '%m3%' 
		or modelname ilike '%m4%') and not ST_IsClosed((st_linemerge(geom))) -- planting model polygon non fermé
		then ST_length(st_makepolygon(st_addpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),st_startpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid))))))
end length_m
from cte1
