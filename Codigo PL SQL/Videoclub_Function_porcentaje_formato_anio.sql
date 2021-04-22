--Función para devolver el porcentaje de alquileres de un formato dado respecto al total del año solicitado:

CREATE OR REPLACE FUNCTION f_porcentaje_formato (v_formato VARCHAR2 ,v_anio number)
    RETURN NUMBER IS 
    TYPE re_contadoralqui IS RECORD
        (
        num_total NUMBER, 
        num_genero NUMBER
        );
        r_alquileres re_contadoralqui;
    BEGIN    
        SELECT COUNT(p.cod_copia), a.gen INTO r_alquileres
            FROM PRESTAMO P, (SELECT COUNT(P1.COD_COPIA)AS GEN
                                    FROM PRESTAMO P1 
                                    WHERE UPPER(p1.cod_copia) LIKE UPPER('%'||v_formato||'%') 
                                    AND TO_CHAR(p1.fecha_inicio,'YYYY')=v_anio) A
            WHERE TO_CHAR(p.fecha_inicio,'YYYY')=v_anio
            GROUP BY a.gen;       
        
    RETURN ROUND(((r_alquileres.num_genero*100)/r_alquileres.num_total),2);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('No se han encontrado datos en la base');
        RETURN -1;
        WHEN OTHERS THEN
        dbms_output.put_line('ERROR OTRO');
        RETURN -1;
END;
/

DECLARE
BEGIN
DBMS_OUTPUT.PUT_LINE(f_porcentaje_formato ('br',2015));
END;
/
        