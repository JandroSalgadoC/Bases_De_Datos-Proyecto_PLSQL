--FUNCION que, dado un género y año, nos devuelve cuántas películas se alquilaron con esas características. 
--Devolverá -1 si hay algún error.

CREATE OR REPLACE FUNCTION f_alquileres_genero_anio(v_genero VARCHAR2 ,v_anio number)
    RETURN NUMBER IS
    v_cantidad NUMBER;--Variable numérica para almacenar el resultado
    e_aniomenor EXCEPTION;
    e_aniomayor EXCEPTION;    
    BEGIN   
         --Compruebo que el rango de año es válido:
        IF v_anio < 2015 THEN
            RAISE e_aniomenor;
        ELSIF v_anio > TO_CHAR(SYSDATE, 'YYYY') THEN
             RAISE e_aniomayor;        
        END IF;    
    SELECT COUNT(P.COD_COPIA) INTO v_cantidad --Cursor implícito para guardar el resultado de la consulta
        FROM prestamo P, PELICULA PE, copia_fisica C
        WHERE p.cod_copia=c.cod_copia
        AND c.cod_pel=pe.cod_pel
        AND UPPER(pe.genero)=UPPER(v_genero)
        AND TO_CHAR(p.fecha_inicio,'YYYY') = v_anio;        
    RETURN v_cantidad;--Devuelvo.
    
    EXCEPTION
        WHEN e_aniomenor THEN
            dbms_output.put_line('ERROR ORA-20004: Nuestro videoclub abrió en 2015, no puede consultar datos de años previos.');
            RETURN -1;
        WHEN e_aniomayor THEN    
            dbms_output.put_line('ERROR ORA-20005: No puede consultar datos de años posteriores al actual.');
            RETURN -1;
        WHEN VALUE_ERROR THEN
            dbms_output.put_line('ERROR VALOR');
            RETURN -1;
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('No se han encontrado datos en la base');
            RETURN -1;
        WHEN OTHERS THEN
            dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
            RETURN -1;
END;
/

--Prueba
DECLARE
BEGIN
DBMS_OUTPUT.PUT_LINE(f_alquileres_genero_anyo('comedia','pepe'));
END;
/
