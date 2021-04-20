/*
    Este procedimiento tiene como objetivos:
    a) Controlar los datos que recibe para comprobar la coherencia en la base de datos.
    b) Una vez hecho eso, generar automáticamente el código de copia, que es PK de la tabla.
    c) Insertar en la tabla COPIA_FISICA los datos correctamente
*/
SET SERVEROUT ON;
--Creo el procedimiento, que recibirá el codigo de la pelicula, el nif del distribuidor y el formato de la copia.
CREATE OR REPLACE PROCEDURE p_insertar_copia (v_cod_pel VARCHAR2, v_nif_dist VARCHAR2, v_formato VARCHAR2) 
    IS
        r_pelicula pelicula.nombre%TYPE;
        r_distribuidor distribuidor.nombre%TYPE;
        v_cont_copias NUMBER;     
        v_cod_copia VARCHAR2(11);
        v_redflag BOOLEAN:=FALSE; --Esta variable nos permitirá, al final del programa, controlar en que momento del código se han generado excepciones.
     
    BEGIN
        --Almaceno el nombre de la película y compruebo que la película existe la base de datos:
        SELECT p.nombre INTO r_pelicula
        FROM pelicula p
        WHERE p.cod_pel = v_cod_pel;        
        
        v_redflag:=TRUE; --Actualizo la variable de control de excepciones para contemplar la otra posibilidad de fallo.
        --Compruebo que existe el distribuidor:
        SELECT d.nombre INTO r_distribuidor
        FROM distribuidor d
        WHERE d.nif_dist = v_nif_dist;        
            
        --Compruebo que el formato se encuentra entre los aceptados:
        IF v_formato NOT IN ('VHS','DVD','BR') OR (v_formato IS NULL) THEN
             RAISE_APPLICATION_ERROR(-20003,'Formato incorrecto. Debe ser VHS, DVD o BR.');
        END IF;
        
        --Concateno el codigo de pelicula y el formato:
        v_cod_copia:=CONCAT(v_cod_pel,v_formato);        
        --Almaceno cuantas copias hay ya en la base de datos:    
        SELECT NVL(COUNT(cp.cod_copia),0) INTO v_cont_copias
            FROM copia_fisica cp
            WHERE cp.cod_copia LIKE v_cod_copia||'%';     
        --Actualizo el contador y concateno el resultado:        
        v_cont_copias:=v_cont_copias+1;            
        v_cod_copia:=CONCAT(v_cod_copia,v_cont_copias);        
        
        --Efectuo el Insert
        INSERT INTO copia_fisica VALUES(v_cod_copia,v_cod_pel,r_pelicula,v_nif_dist,v_formato,'N');
        
        --Gestión de excepciones:
        EXCEPTION
            WHEN no_data_found THEN --Las dos primeras gracias a la variable de control:
                IF (v_redflag = FALSE) THEN
                    RAISE_APPLICATION_ERROR(-20001,'Parámetro de entrada incorrecto. No existe en nuestra base de datos la película con código: '||v_cod_pel);
                ELSE
                    RAISE_APPLICATION_ERROR(-20002,'Parámetro de entrada incorrecto. No existe en nuestra base de datos el distribuidor con NIF: '||v_nif_dist);
                END IF;
            WHEN OTHERS THEN --Cualquier otra que no podamos preveer.   
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);    
END;--Fin del procedimiento
/

--Prueba:
--Con fallos:
EXEC p_insertar_copia_v2('JPI','PEPE','DVD');     
EXEC p_insertar_copia_v2('JP','D05095732','DVD'); 
EXEC p_insertar_copia_v2('JPI','D05095732','BETA'); 
--Correcto:
EXEC p_insertar_copia_v2('JPI','D05095732','DVD'); 
select * from copia_fisica;
rollback;      
SET SERVEROUTPUT ON;       

DROP PROCEDURE P_INSERTAR_COPIA_V2;
    
    