--Esta función recibe un formato y un año y devuelve el porcentaje de alquileres de ese año que corresponden a ese formato.

CREATE OR REPLACE FUNCTION f_porcentaje_formato (v_formato VARCHAR2 ,v_anio number)
    RETURN NUMBER IS 
    TYPE re_contadoralqui IS RECORD--Creo un tipo registro con los campos que me interesan.
        (
        num_total NUMBER, 
        num_genero NUMBER
        );
        r_alquileres re_contadoralqui;--Y se asigno una variable registro.
        --Declaro excepciones:
        e_aniomenor EXCEPTION;
        e_aniomayor EXCEPTION;
        e_formato EXCEPTION;
    BEGIN   
         --Compruebo que el rango de año es válido:
        IF v_anio < 2015 THEN
            RAISE e_aniomenor;
        ELSIF v_anio > TO_CHAR(SYSDATE, 'YYYY') THEN
             RAISE e_aniomayor;        
        END IF; 
         --Compruebo que el formato se encuentra entre los aceptados y lanzo excepción:
        IF UPPER(v_formato) NOT IN ('VHS','DVD','BR') OR (v_formato IS NULL) THEN
             RAISE e_formato;
        END IF;
        SELECT COUNT(p.cod_copia), a.gen INTO r_alquileres --Almaceno los datos de la consulta en el registro
            FROM PRESTAMO P, (SELECT COUNT(P1.COD_COPIA)AS GEN
                                    FROM PRESTAMO P1 
                                    WHERE UPPER(p1.cod_copia) LIKE UPPER('%'||v_formato||'%') 
                                    AND TO_CHAR(p1.fecha_inicio,'YYYY')=v_anio) A
            WHERE TO_CHAR(p.fecha_inicio,'YYYY')=v_anio
            GROUP BY a.gen;       
        
    RETURN ROUND(((r_alquileres.num_genero*100)/r_alquileres.num_total),2);--Y devuelvo el cálculo.
    EXCEPTION--Gestiono excepciones:
        WHEN e_aniomenor THEN
            dbms_output.put_line('ERROR ORA-20004: Nuestro videoclub abrió en 2015, no puede consultar datos de años previos.');
            RETURN -1;
        WHEN e_aniomayor THEN    
            dbms_output.put_line('ERROR ORA-20005: No puede consultar datos de años posteriores al actual.');
            RETURN -1;
        WHEN e_formato THEN
            dbms_output.put_line('ERROR ORA--20003: Formato incorrecto. Ha introducido '||v_formato||'. Debe ser VHS, DVD o BR.');
            RETURN -1;
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('No se han encontrado datos en la base');
        RETURN -1;
        WHEN OTHERS THEN
            dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
        RETURN -1;
END;
/
SET SERVEROUTPUT ON;
DECLARE
BEGIN
DBMS_OUTPUT.PUT_LINE(f_porcentaje_formato ('br',2014));
END;
/
        