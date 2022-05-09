from importlib import import_module
import psycopg2 as psql


print("library imported")

try :
    conn = psql.connect(host="db01.postgres.database.azure.com", dbname="fielddata", user="pp_fabien", password="9N9GNK78TyXQtls6")
    conn.set_client_encoding('utf-8')

    #Partie 1 : Track intersection avec une autre track d'une même vague
    cur_get_gps_id = conn.cursor()
    cur_check_table_error = conn.cursor()
    cur_insert_error = conn.cursor()
    cur_insert_error_details = conn.cursor()

    q_get_gps_id = "with cte as (select a.id, e.id waveid, d.id projectwaveid, a.geom \
                                from gps a\
                                join parcelwaves b on a.parcelwaveid = b.id\
                                join farmerwaves c on b.farmerwaveid = c.id\
                                join projectwaves d on c.projectwaveid = d.id\
                                join waves e on d.waveid = e.id)\
                    \
                    SELECT a.id, a.projectwaveid\
                    FROM cte a, cte b \
                    WHERE ST_INTERSECTS(ST_SETSRID(ST_MAKEVALID(a.geom),4326), ST_SETSRID(ST_MAKEVALID(b.geom),4326)) and \
                        a.id != b.id and a.waveid = b.waveid\
                    group by a.id, a.projectwaveid ;"

    q_check_table_error = "SELECT a.errorrow \
                            FROM checkerrordetails a\
                            JOIN checkerror b on a.checkerrorid = b.id\
                            WHERE b.errortypeid = 6;"

    q_insert_error = "INSERT INTO checkerror(errortypeid,projectwaveid) \
                        VALUES (6,%s) \
                        returning id;"

    q_insert_error_details = "INSERT INTO checkerrordetails(checkerrorid,errortable,errorrow,errorstatus)\
                                VALUES (%s,'gps',%s,'error')"

    cur_get_gps_id.execute(q_get_gps_id)
    r1 = cur_get_gps_id.fetchall()

    cur_check_table_error.execute(q_check_table_error)
    r2 = cur_check_table_error.fetchall()

    i = 0
    for a in r1 :
        bool = False
        gpsid = a[0]
        projectwaveid = a[1]
        for b in r2 :
            if a[0] == b[0] :
                bool = True
                break
        if bool == False :
            cur_insert_error.execute(q_insert_error,[projectwaveid])
            id_error = cur_insert_error.fetchone()[0]
            cur_insert_error_details.execute(q_insert_error_details,(id_error,gpsid))
            i += 1
        else :
            pass
        
    print(i, ' #6 error(s) added')
        
    conn.commit()


    #Partie 2 : Track intersection avec une track d'une autre vague
    cur_get_gps_id = conn.cursor()
    cur_check_table_error = conn.cursor()
    cur_insert_error = conn.cursor()
    cur_insert_error_details = conn.cursor()

    q_get_gps_id = "with cte as (select a.id, e.id waveid, d.id projectwaveid, a.geom \
                                from gps a\
                                join parcelwaves b on a.parcelwaveid = b.id\
                                join farmerwaves c on b.farmerwaveid = c.id\
                                join projectwaves d on c.projectwaveid = d.id\
                                join waves e on d.waveid = e.id)\
                    \
                    SELECT a.id, a.projectwaveid\
                    FROM cte a, cte b \
                    WHERE ST_INTERSECTS(ST_SETSRID(ST_MAKEVALID(a.geom),4326), ST_SETSRID(ST_MAKEVALID(b.geom),4326)) and \
                        a.id != b.id and a.waveid != b.waveid\
                    group by a.id, a.projectwaveid ;"

    q_check_table_error = "SELECT a.errorrow \
                            FROM checkerrordetails a\
                            JOIN checkerror b on a.checkerrorid = b.id\
                            WHERE b.errortypeid = 7;"

    q_insert_error = "INSERT INTO checkerror(errortypeid,projectwaveid) \
                        VALUES (7,%s) \
                        returning id;"

    q_insert_error_details = "INSERT INTO checkerrordetails(checkerrorid,errortable,errorrow,errorstatus)\
                                VALUES (%s,'gps',%s,'error')"

    cur_get_gps_id.execute(q_get_gps_id)
    r1 = cur_get_gps_id.fetchall()

    cur_check_table_error.execute(q_check_table_error)
    r2 = cur_check_table_error.fetchall()
    i = 0
    for a in r1 :
        bool = False
        gpsid = a[0]
        projectwaveid = a[1]
        for b in r2 :
            if a[0] == b[0] :
                bool = True
                break
        if bool == False :
            cur_insert_error.execute(q_insert_error,[projectwaveid])
            id_error = cur_insert_error.fetchone()[0]
            cur_insert_error_details.execute(q_insert_error_details,(id_error,gpsid))
            i += 1
        else :
            pass

    print(i, ' #7 error(s) added')
    
    conn.commit()

    #Partie 3 : Track self intersection
    cur_get_gps_id = conn.cursor()
    cur_check_table_error = conn.cursor()
    cur_insert_error = conn.cursor()
    cur_insert_error_details = conn.cursor()

    q_get_gps_id = "WITH noded AS (\
                    SELECT id, COUNT(id)\
                    FROM (\
                        SELECT DISTINCT (ST_DumpPoints(ST_Node(geom))).geom, id\
                        FROM gps\
                    ) tmp  group by id\
                    ),\
                    test AS (\
                        SELECT id, COUNT(id)\
                            FROM (\
                                SELECT DISTINCT (ST_DumpPoints(geom)).geom, id\
                                FROM gps\
                            ) tmp  group by id\
                    )\
                    \
                    select tmp2.id, projectwaveid\
                    from (\
                        SELECT noded.id, noded.count - test.count cnt \
                        FROM noded\
                        JOIN test USING (id) where (noded.count - test.count) > 0) tmp2\
                    join gps on tmp2.id = gps.id\
                    join parcelwaves b on gps.parcelwaveid = b.id\
                    join farmerwaves c on b.farmerwaveid = c.id\
                    join projectwaves d on c.projectwaveid = d.id\
                    join waves e on d.waveid = e.id;"

    q_check_table_error = "SELECT a.errorrow \
                            FROM checkerrordetails a\
                            JOIN checkerror b on a.checkerrorid = b.id\
                            WHERE b.errortypeid = 8;"

    q_insert_error = "INSERT INTO checkerror(errortypeid,projectwaveid) \
                        VALUES (8,%s) \
                        returning id;"

    q_insert_error_details = "INSERT INTO checkerrordetails(checkerrorid,errortable,errorrow,errorstatus)\
                                VALUES (%s,'gps',%s,'error')" #Check if "error" or smtg else

    cur_get_gps_id.execute(q_get_gps_id)
    r1 = cur_get_gps_id.fetchall()

    cur_check_table_error.execute(q_check_table_error)
    r2 = cur_check_table_error.fetchall()
    i= 0
    for a in r1 :
        bool = False
        gpsid = a[0]
        projectwaveid = a[1]
        for b in r2 :
            if a[0] == b[0] :
                bool = True
                break
        if bool == False :
            cur_insert_error.execute(q_insert_error,[projectwaveid])
            id_error = cur_insert_error.fetchone()[0]
            cur_insert_error_details.execute(q_insert_error_details,(id_error,gpsid))
            i += 1
        else :
            pass
    
    print(i, ' #8 error(s) added')
    
    conn.commit()
