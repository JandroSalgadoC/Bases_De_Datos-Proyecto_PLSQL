/*
    Este procedimiento tiene como objetivos:
    a) Controlar los datos que recibe para comprobar la coherencia en la base de datos.
    b) Una vez hecho eso, generar automáticamente el código de copia, que es PK de la tabla.
    c) Insertar en la tabla COPIA_FISICA los datos correctamente
*/
SET SERVEROUT ON;
-- Primero creo el procedimiento, que recibirá el codigo de la pelicula, el nif del distribuidor y el formato de la copia.
CREATE OR REPLACE PROCEDURE p_insertar_copia (v_cod_pel VARCHAR2, v_nif_dist VARCHAR2, v_formato VARCHAR2) IS

     r_pelicula pelicula.nombre%TYPE;
     r_distribuidor distribuidor.nombre%TYPE;
     v_cont_copias NUMBER;
     
     v_cod_copia VARCHAR2(11);
     
     BEGIN
     --Primero vamos a comprobar que la película existe en nuestra base de datos:
        SELECT p.nombre INTO r_pelicula
        FROM pelicula p
        WHERE p.cod_pel = v_cod_pel;
        
        IF (r_pelicula IS NULL) THEN
            RAISE_APPLICATION_ERROR(-20001,'La película no se encuentra en la base de datos.');
        END IF;
    
    --Después comprobamos que existe el distribuidor:
        SELECT d.nombre INTO r_distribuidor
        FROM distribuidor d
        WHERE d.nif_dist = v_nif_dist;
        
        IF (r_distribuidor IS NULL) THEN
            RAISE_APPLICATION_ERROR(-20002,'El distribuidor no se encuentra en la base de datos.');
        END IF;
        
    --Comprobamos que el formato se encuentra entre los aceptados:
        IF v_formato NOT IN ('VHS','DVD','BR') OR (v_formato IS NULL) THEN
             RAISE_APPLICATION_ERROR(-20003,'Formato incorrecto. Debe ser VHS, DVD o BR.');
        END IF;
        
    --Con las comprobaciones hechas, pasamos a generar el Codigo de Copia:
    --Lo primero en usar la función CONCAT para concatenar el codigo de pelicula y el formato:
        v_cod_copia:=CONCAT(v_cod_pel,v_formato);
        
    --Después contamos cuantas copias hay ya en la base de datos y la almacenamos, asegurándonos de no quedarnos con NULL si es la primera:    
        SELECT NVL(COUNT(cp.cod_copia),0) INTO v_cont_copias
            FROM copia_fisica cp
            WHERE cp.cod_copia LIKE v_cod_copia||'%'; 
    
    --Para terminar, aumentamos en uno la cantidad y concatenamos de nuevo al código de copia:        
        v_cont_copias:=v_cont_copias+1;
            
        v_cod_copia:=CONCAT(v_cod_copia,v_cont_copias);
        
        
        --FINALMENTE HACEMOS EL INSERT:
        INSERT INTO copia_fisica VALUES(v_cod_copia,v_cod_pel,r_pelicula,v_nif_dist,v_formato,'N');
        
        
END;--Fin del procedimiento
/

--Prueba:
EXEC p_insertar_copia('JPII','D05095732','DVD');        
rollback;      
        
    
    