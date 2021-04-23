/*
##########################################################################
SCRIPT DE GESTI�N DE PRUEBAS DE LA BASE DE DATOS RELACIONAL VIDEOCLUB
DE ALEJANDRO SALGADO CERDEIRA PARA DAW2 - CURSO 20/21
##########################################################################

Para ir probando de manera controlada, se ha creado una variable num�rica 
llamada v_opc que debe cambiar a mano antes de ejecutar el bloque an�nimo. 

Dependiendo de lo que elija seg�n el siguiente men�, se ejecutar� un caso de 
prueba:
    0.- Termina el procedimiento de manera controlada, �sela en caso de estar
        probando las opciones 6 o 7.
    1.- Funci�n que dado un formato de cinta y un a�o, devuelve el porcentaje
        de alquileres que corresponden a ese a�o para ese formato. Se incluye
        muestra de las excepciones posibles.
    2.- Funci�n que, dado un g�nero y a�o, nos devuelve cu�ntas pel�culas se 
        alquilaron con esas caracter�sticas.Se incluye muestra de las excepciones 
        posibles.
    3.- Actualizaci�n de un campo de la tabla cliente sin problemas, sirve para 
        contrastar con el fallo del siguiente punto.
    4.- Disparador de sentencia. Bloquea la modificaci�n del campo 'N�mero de socio'
        en la tabla cliente y lanza una excepci�n que impide que el proceso finalice
        correctamente.
    5.- Disparadores de fila: Se han a�adido disparadores para registrar todas las 
        modificaciones de nuestra base de datos. Se hace la prueba solo con la tabla
        pel�cula, pero se puede comprobar en la carpeta de disparadores la existencia
        de los dem�s.
    6.- Procedimiento para insertar en la tabla COPIA_FISICA generando autom�ticamente
        su primary key y los datos por defecto. Como no se puede incluir un procedimiento
        dentro de otro, lo encontrar� debajo del t�rmino de este, comentado, para s�lo
        tener que descomentarlo y probarlo.
    7.- Procedimiento para generar un listado de balance anual. Al igual que el procedimiento
        anterior est� comentado. Debido a la longitud del mismo, se recomienda mirar la 
        documentacion adjunta para analizar mejor su contenido.
*/
SET SERVEROUTPUT ON;
DECLARE
    v_opc NUMBER;
    r_aux audit_pelicula%ROWTYPE;    
    BEGIN
    v_opc:=0;--ESTA ES LA VARIABLE PARA SELECCIONAR.    
    CASE        
        WHEN v_opc = 0 THEN
            DBMS_OUTPUT.PUT_LINE('');        
        WHEN v_opc = 1 THEN 
            --Caso con �xito:
            DBMS_OUTPUT.PUT_LINE('-- Caso correcto --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('br',2015));
            --Fallo de a�o fuera de rango:
            DBMS_OUTPUT.PUT_LINE('-- Errores de a�o fuera de rango --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('br',2014));
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('br',2030));
            --Fallo de formato err�neo:
            DBMS_OUTPUT.PUT_LINE('-- Error de formato err�neo --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('beta',2015));
            --Fallo de no_data_found:
            DBMS_OUTPUT.PUT_LINE('-- Error de data not found --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('br',2019));
            --Fallo de error de tipo de datos, lo recoge el propio bloque anonimo:
            DBMS_OUTPUT.PUT_LINE('-- Error de tipo de datos incorrecto --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_porcentaje_formato ('br','pepe'));
        WHEN v_opc = 2 THEN 
            --Caso con �xito:
            DBMS_OUTPUT.PUT_LINE('-- Caso correcto --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_alquileres_genero_anio ('ciencia ficci�n',2015));
            --Fallo de a�o fuera de rango:
            DBMS_OUTPUT.PUT_LINE('-- Errores de a�o fuera de rango --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_alquileres_genero_anio ('ciencia ficci�n',2014));
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_alquileres_genero_anio ('ciencia ficci�n',2030));
            --Fallo de no_data_found:
            DBMS_OUTPUT.PUT_LINE('-- Error de data not found --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_alquileres_genero_anio ('pepe',2019));
            --Fallo de error de tipo de datos, lo recoge el propio bloque anonimo:
            DBMS_OUTPUT.PUT_LINE('-- Error de tipo de datos incorrecto --');
            DBMS_OUTPUT.PUT_LINE('La funci�n devuelve: '||f_alquileres_genero_anio ('ciencia ficci�n','pepe'));
        WHEN v_opc = 3 THEN
            --A�adimos sin problemas un email al cliente con numero de socio 2:            
            UPDATE CLIENTE SET email = 'mailtest@test.com' WHERE NUM_SOCIO=2;            
            ROLLBACK;--No quiero mantener los datos.             
        WHEN v_opc = 4 THEN
            --Intentamos modificar el n�mero de socio y se interrumpe el programa.
            UPDATE CLIENTE SET NUM_SOCIO = 1 WHERE NUM_SOCIO=2;
        WHEN v_opc = 5 THEN
            INSERT INTO PELICULA VALUES ('SOLRYA','Salvar al soldado Ryan','Steven Spielberg','Tom Hanks','Matt Damon','Dreamworks Pictures','1998','B�lica');
            SELECT usuario, fecha_hora, opcion, old_reg, new_reg INTO r_aux FROM AUDIT_PELICULA WHERE NEW_REG LIKE '%SOLRYA%';
            DBMS_OUTPUT.PUT_LINE('---REGISTRO DEL INSERT---');
            DBMS_OUTPUT.PUT_LINE(r_aux.usuario||' '||r_aux.fecha_hora||' '||r_aux.opcion||' '||r_aux.old_reg||' '||r_aux.new_reg);
            UPDATE PELICULA SET COD_PEL = 'SALSOL' WHERE COD_PEL='SOLRYA';
            SELECT usuario, fecha_hora, opcion, old_reg, new_reg INTO r_aux FROM AUDIT_PELICULA WHERE NEW_REG LIKE '%SALSOL%' AND OPCION=2;
            DBMS_OUTPUT.PUT_LINE('---REGISTRO DEL UPDATE---');
            DBMS_OUTPUT.PUT_LINE(r_aux.usuario||' '||r_aux.fecha_hora||' '||r_aux.opcion||' '||r_aux.old_reg||' '||r_aux.new_reg);
            DELETE FROM PELICULA WHERE COD_PEL='SALSOL';
            SELECT usuario, fecha_hora, opcion, old_reg, new_reg INTO r_aux FROM AUDIT_PELICULA WHERE OLD_REG LIKE '%SALSOL%' AND OPCION=3;
            DBMS_OUTPUT.PUT_LINE('---REGISTRO DEL DELETE---');
            DBMS_OUTPUT.PUT_LINE(r_aux.usuario||' '||r_aux.fecha_hora||' '||r_aux.opcion||' '||r_aux.old_reg||' '||r_aux.new_reg);
            ROLLBACK;
        ELSE
            DBMS_OUTPUT.PUT_LINE('No ha seleccionado una opci�n v�lida. Elija entre 0 y 5 por favor.');
    END CASE;
    --Control de excepciones.
    EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE(sqlerrm);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(sqlerrm);
END;
/
    
/*
--6.- PRUEBAS DEL PROCEDIMIENTO PARA INSERTAR COPIAS F�SICAS DE LAS PEL�CULAS:
--Con fallos:
EXEC p_insertar_copia('JPI','PEPE','DVD');    
EXEC p_insertar_copia('JP','D05095732','DVD'); 
EXEC p_insertar_copia('JPI','D05095732','BETA');
--Correcto:
EXEC p_insertar_copia('JPI','D05095732','DVD');
select * from copia_fisica WHERE cod_copia LIKE '%JPIDVD%';
SELECT usuario,fecha_hora,opcion,new_reg FROM audit_copia_fisica WHERE new_reg LIKE '%JPIDVD%';
ROLLBACK; 
*/

/*
--7.- LISTADO COMPLETO DE BALANCE ANUAL:
--Con fallos de rango de a�o:
EXEC p_listado_balance_anual ('2014');
EXEC p_listado_balance_anual ('2030');
--Con fallo de par�metro incorrecto:
EXEC p_listado_balance_anual ('pepe');
--Correcto:
EXEC p_listado_balance_anual ('2015');
*/

    