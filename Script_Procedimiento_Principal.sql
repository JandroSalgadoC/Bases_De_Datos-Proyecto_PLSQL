/*
##########################################################################
SCRIPT DE GESTIÓN DE PRUEBAS DE LA BASE DE DATOS RELACIONAL VIDEOCLUB
DE ALEJANDRO SALGADO CERDEIRA PARA DAW2 - CURSO 20/21
##########################################################################

Para ir probando de manera controlada, se ha creado una variable numérica 
llamada v_opc que debe cambiar a mano antes de ejecutar el bloque anónimo. 

Dependiendo de lo que elija según el siguiente menú, se ejecutará un caso de 
prueba:
    0.- Termina el procedimiento de manera controlada, úsela en caso de estar
        probando las opciones 6 o 7.
    1.- Función que dado un formato de cinta y un año, devuelve el porcentaje
        de alquileres que corresponden a ese año para ese formato. Se incluye
        muestra de las excepciones posibles.
    2.- Función que, dado un género y año, nos devuelve cuántas películas se 
        alquilaron con esas características.Se incluye muestra de las excepciones 
        posibles.
    3.- Actualización de un campo de la tabla cliente sin problemas, sirve para 
        contrastar con el fallo del siguiente punto.
    4.- Disparador de sentencia. Bloquea la modificación del campo 'Número de socio'
        en la tabla cliente y lanza una excepción que impide que el proceso finalice
        correctamente.
    5.- Disparadores de fila: Se han añadido disparadores para registrar todas las 
        modificaciones de nuestra base de datos. Se hace la prueba solo con la tabla
        película, pero se puede comprobar en la carpeta de disparadores la existencia
        de los demás.
    6.- Procedimiento para insertar en la tabla COPIA_FISICA generando automáticamente
        su primary key y los datos por defecto. Como no se puede incluir un procedimiento
        dentro de otro, lo encontrará debajo del término de este, comentado, para sólo
        tener que descomentarlo y probarlo.
    7.- Procedimiento para generar un listado de balance anual. Al igual que el procedimiento
        anterior está comentado. Debido a la longitud del mismo, se recomienda mirar la 
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
            --Caso con éxito:
            DBMS_OUTPUT.PUT_LINE('-- Caso correcto --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('br',2015));
            --Fallo de año fuera de rango:
            DBMS_OUTPUT.PUT_LINE('-- Errores de año fuera de rango --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('br',2014));
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('br',2030));
            --Fallo de formato erróneo:
            DBMS_OUTPUT.PUT_LINE('-- Error de formato erróneo --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('beta',2015));
            --Fallo de no_data_found:
            DBMS_OUTPUT.PUT_LINE('-- Error de data not found --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('br',2019));
            --Fallo de error de tipo de datos, lo recoge el propio bloque anonimo:
            DBMS_OUTPUT.PUT_LINE('-- Error de tipo de datos incorrecto --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_porcentaje_formato ('br','pepe'));
        WHEN v_opc = 2 THEN 
            --Caso con éxito:
            DBMS_OUTPUT.PUT_LINE('-- Caso correcto --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_alquileres_genero_anio ('ciencia ficción',2015));
            --Fallo de año fuera de rango:
            DBMS_OUTPUT.PUT_LINE('-- Errores de año fuera de rango --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_alquileres_genero_anio ('ciencia ficción',2014));
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_alquileres_genero_anio ('ciencia ficción',2030));
            --Fallo de no_data_found:
            DBMS_OUTPUT.PUT_LINE('-- Error de data not found --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_alquileres_genero_anio ('pepe',2019));
            --Fallo de error de tipo de datos, lo recoge el propio bloque anonimo:
            DBMS_OUTPUT.PUT_LINE('-- Error de tipo de datos incorrecto --');
            DBMS_OUTPUT.PUT_LINE('La función devuelve: '||f_alquileres_genero_anio ('ciencia ficción','pepe'));
        WHEN v_opc = 3 THEN
            --Añadimos sin problemas un email al cliente con numero de socio 2:            
            UPDATE CLIENTE SET email = 'mailtest@test.com' WHERE NUM_SOCIO=2;            
            ROLLBACK;--No quiero mantener los datos.             
        WHEN v_opc = 4 THEN
            --Intentamos modificar el número de socio y se interrumpe el programa.
            UPDATE CLIENTE SET NUM_SOCIO = 1 WHERE NUM_SOCIO=2;
        WHEN v_opc = 5 THEN
            INSERT INTO PELICULA VALUES ('SOLRYA','Salvar al soldado Ryan','Steven Spielberg','Tom Hanks','Matt Damon','Dreamworks Pictures','1998','Bélica');
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
            DBMS_OUTPUT.PUT_LINE('No ha seleccionado una opción válida. Elija entre 0 y 5 por favor.');
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
--6.- PRUEBAS DEL PROCEDIMIENTO PARA INSERTAR COPIAS FÍSICAS DE LAS PELÍCULAS:
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
--Con fallos de rango de año:
EXEC p_listado_balance_anual ('2014');
EXEC p_listado_balance_anual ('2030');
--Con fallo de parámetro incorrecto:
EXEC p_listado_balance_anual ('pepe');
--Correcto:
EXEC p_listado_balance_anual ('2015');
*/

    