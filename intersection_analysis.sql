-- Creat temp table
create temporary table tmp_test as
	(with cte1 as (
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
	
	select id, modelname, srid, area_unit, --st_setsrid(geom,4326) as geom
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
			then st_makepolygon(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))
		when modelname ilike '%m1%' -- planting model ligne
			then st_buffer(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),2.5, 'endcap=flat join=mitre')
		when (modelname ilike '%m2%' 
			or modelname ilike '%m3%' 
			or modelname ilike '%m4%') and not ST_IsClosed((st_linemerge(geom))) -- planting model polygon non fermé
			then st_makepolygon(st_addpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)),st_startpoint(st_linemerge(ST_TRANSFORM(st_setsrid(geom,4326), srid)))))
	end geom
	from cte1);

-- Create spatial index 
CREATE INDEX tmp_test_idx
    ON tmp_test
    USING GIST (geom);

-- Query to get area intersected
SELECT a.id, 
	b.id, 
	a.area_m2,
	ST_AREA(ST_TRANSFORM(ST_INTERSECTION(ST_TRANSFORM(ST_MAKEVALID(a.geom),4326), ST_TRANSFORM(ST_MAKEVALID(b.geom),4326)),a.srid)) intersected_area_m2,
	ST_INTERSECTION(ST_TRANSFORM(ST_MAKEVALID(a.geom),4326), ST_TRANSFORM(ST_MAKEVALID(b.geom),4326)) intersected_geom,
	ST_TRANSFORM(ST_MAKEVALID(a.geom),4326) geom
FROM tmp_test a, tmp_test b 
WHERE ST_INTERSECTS(ST_TRANSFORM(ST_MAKEVALID(a.geom),4326), ST_TRANSFORM(ST_MAKEVALID(b.geom),4326)) and a.id != b.id;

-- Drop temp table
--DROP table tmp_test;