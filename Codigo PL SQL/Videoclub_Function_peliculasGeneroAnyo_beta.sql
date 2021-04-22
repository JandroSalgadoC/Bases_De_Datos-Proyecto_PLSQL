--FUNCION que, dado un g�nero y a�o, nos devuelve cu�ntas pel�culas se alquilaron con esas caracter�sticas. 
--Devolver� -1 si hay alg�n error.

CREATE OR REPLACE FUNCTION f_alquileres_genero_anyo(v_genero VARCHAR2 ,v_anio number)
    RETURN NUMBER IS
    v_cantidad NUMBER;
    BEGIN   
    --Compruebo que el rango de a�o es v�lido:
/*    IF v_anio < 2015 THEN
        RAISE_APPLICATION_ERROR(-20004,'Nuestro vidoclub abri� en 2015, no puede consultar datos de a�os previos.');
        RETURN -1;
    ELSIF v_anio > TO_CHAR(SYSDATE, 'YYYY') THEN
        RAISE_APPLICATION_ERROR(-20005,'No puede consultar datos de a�os que a�n no han ocurrido.'); 
        RETURN -1;
    END IF;*/
    
    SELECT COUNT(P.COD_COPIA) INTO v_cantidad
        FROM prestamo P, PELICULA PE, copia_fisica C
        WHERE p.cod_copia=c.cod_copia
        AND c.cod_pel=pe.cod_pel
        AND UPPER(pe.genero)=UPPER(v_genero)
        AND TO_CHAR(p.fecha_inicio,'YYYY') = v_anio;        
    RETURN v_cantidad;
    EXCEPTION     
        
        WHEN OTHERS THEN--Cualquier otra excepci�n que no podamos preveer.   
            dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
            RETURN -1;
END;
/



DECLARE
BEGIN
DBMS_OUTPUT.PUT_LINE(f_alquileres_genero_anyo('pepe','pepe'));
END;
/
