/*
ESTE SCRIPT CREA NUESTRA BASE DE DATOS COMPLETAMENTE:
    -Eliminación de la base de datos previa.
    -Creación de tablas
    -Creación de secuencias
    -Creación de funciones, procedimientos y disparadores
    -Inserción de datos
    -Commit de la transacción
*/
SET SERVEROUT ON;

DROP TABLE PRESTAMO;
DROP TABLE COPIA_FISICA;
DROP TABLE DISTRIBUIDOR;
DROP TABLE CLIENTE;
DROP TABLE PELICULA;
DROP SEQUENCE SEQ_NUM_SOCIO;
DROP TABLE AUDIT_PRESTAMO;
DROP TABLE AUDIT_COPIA_FISICA;
DROP TABLE AUDIT_DISTRIBUIDOR;
DROP TABLE AUDIT_CLIENTE;
DROP TABLE AUDIT_PELICULA;


--SCRIPT DE CREACIÓN DE TABLAS Y SECUENCIAS:
CREATE TABLE PELICULA
(
    COD_PEL VARCHAR2(10)CONSTRAINT PEL_COD_PK PRIMARY KEY,
    NOMBRE VARCHAR2(60)CONSTRAINT PEL_NOM_NN NOT NULL,
    DIRECTOR VARCHAR2(30)CONSTRAINT PEL_DIR_NN NOT NULL,
    INTERPRETE1 VARCHAR2(30),
    INTERPRETE2 VARCHAR2(30),
    PRODUCTORA VARCHAR2(40),
    FECHA_SALIDA NUMBER (4),
    GENERO VARCHAR2(20)    
);

CREATE TABLE CLIENTE
(
    NUM_SOCIO NUMBER(4) CONSTRAINT CLI_NUM_NN NOT NULL UNIQUE,
    DNI_CLIENTE CHAR(9)CONSTRAINT CLI_DNI_PK PRIMARY KEY,
    NOMBRE VARCHAR2(15)CONSTRAINT CLI_NOM_NN NOT NULL,
    APELLIDO1 VARCHAR2(15)CONSTRAINT CLI_AP1_NN NOT NULL,
    APELLIDO2 VARCHAR2(15),
    DOMICILIO VARCHAR2(30),
    EMAIL VARCHAR2(30),
    DEUDA NUMBER(5,2)
);


CREATE TABLE DISTRIBUIDOR
(
    NIF_DIST VARCHAR2(9)CONSTRAINT DIS_NIF_PK PRIMARY KEY,
    NOMBRE VARCHAR2(50)CONSTRAINT DIS_NOM_NN NOT NULL CONSTRAINT DIS_NOM_UK UNIQUE,
    DIRECCION VARCHAR2(50)CONSTRAINT DIS_DIR_NN NOT NULL,
    TELEFONO NUMBER(11) CONSTRAINT DIS_TEL_NN NOT NULL, 
    EMAIL VARCHAR2(40),
    NOMBRE_CONTACTO VARCHAR2(20)
);

CREATE TABLE COPIA_FISICA
(
    COD_COPIA VARCHAR2(12)CONSTRAINT COP_COD_PK PRIMARY KEY,
    COD_PEL VARCHAR2(10)CONSTRAINT COP_COD_NN NOT NULL CONSTRAINT COP_COD_FK REFERENCES PELICULA,
    NOMBRE VARCHAR2(55)CONSTRAINT COP_NOM_NN NOT NULL,
    NIF_DIST VARCHAR2(9)CONSTRAINT COP_NIF_NN NOT NULL CONSTRAINT COP_NIF_FK REFERENCES DISTRIBUIDOR,
    FORMATO VARCHAR2(3)CONSTRAINT COP_FOR_CK CHECK (FORMATO IN ('DVD','VHS','BR')),
    PRESTADO CHAR(1) DEFAULT 'N' CONSTRAINT COP_PRE_NN NOT NULL CONSTRAINT COP_PRE_CK CHECK(UPPER(PRESTADO)IN('S','N')) 
);

CREATE TABLE PRESTAMO
(
    COD_COPIA VARCHAR2(12)CONSTRAINT PRE_COD_FK REFERENCES COPIA_FISICA,
    DNI_CLIENTE CHAR(9)CONSTRAINT PRE_DNI_FK REFERENCES CLIENTE,
    FECHA_INICIO DATE, 
    FECHA_FIN DATE,
    PRECIO NUMBER(4,2),
    PAGADO CHAR(1) DEFAULT 'N' CONSTRAINT PRE_PAG_NN NOT NULL CONSTRAINT PRE_PAG_CK CHECK(UPPER(PAGADO)IN('S','N')),
    CONSTRAINT PRE_CDF_PK PRIMARY KEY(COD_COPIA,DNI_CLIENTE,FECHA_INICIO),
    CONSTRAINT PRE_FEF_CK CHECK (FECHA_FIN>=FECHA_INICIO)
);

CREATE TABLE AUDIT_CLIENTE (    
    USUARIO	VARCHAR2(40),
    FECHA_HORA	TIMESTAMP,
    OPCION	NUMBER(1),
    OLD_REG	VARCHAR2(200),
    NEW_REG	VARCHAR2(200)
);

CREATE TABLE AUDIT_COPIA_FISICA (    
    USUARIO	VARCHAR2(40),
    FECHA_HORA	TIMESTAMP,
    OPCION	NUMBER(1),
    OLD_REG	VARCHAR2(200),
    NEW_REG	VARCHAR2(200)
);

CREATE TABLE AUDIT_DISTRIBUIDOR (    
    USUARIO	VARCHAR2(40),
    FECHA_HORA	TIMESTAMP,
    OPCION	NUMBER(1),
    OLD_REG	VARCHAR2(200),
    NEW_REG	VARCHAR2(200)
);

CREATE TABLE AUDIT_PELICULA (    
    USUARIO	VARCHAR2(40),
    FECHA_HORA	TIMESTAMP,
    OPCION	NUMBER(1),
    OLD_REG	VARCHAR2(200),
    NEW_REG	VARCHAR2(200)
);

CREATE TABLE AUDIT_PRESTAMO (    
    USUARIO	VARCHAR2(40),
    FECHA_HORA	TIMESTAMP,
    OPCION	NUMBER(1),
    OLD_REG	VARCHAR2(200),
    NEW_REG	VARCHAR2(200)
);

CREATE SEQUENCE SEQ_NUM_SOCIO
    START WITH 1
    MAXVALUE 9999;
    
--SCRIPT DE CREACIÓN DE PROCEDIMIENTOS, FUNCIONES Y DISPARADORES:
/*
    Este procedimiento tiene como objetivos:
    a) Controlar los datos que recibe para comprobar la coherencia en la base de datos.
    b) Una vez hecho eso, generar automáticamente el código de copia, que es PK de la tabla.
    c) Insertar en la tabla COPIA_FISICA los datos correctamente
*/
--Creo el procedimiento, que recibirá el codigo de la pelicula, el nif del distribuidor y el formato de la copia.
CREATE OR REPLACE PROCEDURE p_insertar_copia (v_cod_pel VARCHAR2, v_nif_dist VARCHAR2, v_formato VARCHAR2) 
    IS
        r_pelicula pelicula.nombre%TYPE;
        r_distribuidor distribuidor.nombre%TYPE;
        v_cont_copias NUMBER;     
        v_cod_copia VARCHAR2(11);
        v_redflag BOOLEAN:=FALSE; --Esta variable nos permitirá, al final del programa, controlar en que momento del código se han generado excepciones.
        e_formato EXCEPTION;
    BEGIN
        --Compruebo que el formato se encuentra entre los aceptados y lanzo excepción:
        IF v_formato NOT IN ('VHS','DVD','BR') OR (v_formato IS NULL) THEN
             RAISE e_formato;
        END IF;
        --Almaceno el nombre de la película. Si no existe, recojo la excepción en el bloque final:
        SELECT p.nombre INTO r_pelicula
        FROM pelicula p
        WHERE p.cod_pel = v_cod_pel;      
        v_redflag:=TRUE; --Actualizo la variable de control de excepciones para contemplar la otra posibilidad de fallo.
        --Almaceno el nombre del distribuidor. Si no existe, recojo la excepción en el bloque final:
        SELECT d.nombre INTO r_distribuidor
        FROM distribuidor d
        WHERE d.nif_dist = v_nif_dist;  
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
            WHEN e_formato THEN
                dbms_output.put_line('ERROR ORA--20003: Formato incorrecto. Ha introducido '||v_formato||'. Debe ser VHS, DVD o BR.');
            WHEN no_data_found THEN --Las dos primeras gracias a la variable de control:
                IF (v_redflag = FALSE) THEN
                    dbms_output.put_line('ERROR ORA-20001: Parámetro de entrada incorrecto. No existe en nuestra base de datos la película con código: '||v_cod_pel);
                ELSE
                    dbms_output.put_line('ERROR ORA-20002: Parámetro de entrada incorrecto. No existe en nuestra base de datos el distribuidor con NIF: '||v_nif_dist);
                END IF;
            WHEN OTHERS THEN --Cualquier otra que no podamos preveer.   
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);    
END;--Fin del procedimiento
/

--Procedimiento para generar un listado anual. Recibe un año y muestra en consola los datos relativos al mismo. 
CREATE OR REPLACE PROCEDURE p_listado_balance_anual (v_anio VARCHAR2) IS
    --Cursor para obtener todos los alquileres de un año:
    CURSOR c_periodo IS
        SELECT DISTINCT TO_CHAR (p.fecha_inicio,'MM/YYYY') AS Periodo
        FROM prestamo p
        where TO_CHAR (p.fecha_inicio, 'YYYY')=v_anio
        ORDER BY Periodo;
    r_periodo c_periodo%ROWTYPE; --Registro para el cursor periodo.
    
    --Cursor para obtener todos los clientes que han realizado movimientos ese mes:
    CURSOR c_clientes (periodo VARCHAR2)IS
        SELECT DISTINCT c.apellido1||', '||c.nombre AS "CLIENTE",c.num_socio, c.dni_cliente
        FROM prestamo p, cliente c
        where p.dni_cliente=c.dni_cliente
        AND TO_CHAR(p.fecha_inicio,'MM/YYYY') = periodo
        ORDER BY CLIENTE;
    r_clientes c_clientes%ROWTYPE;--Registro para el cursor clientes.
    
    --Cursor que dado un cliente y un periodo, nos devuelva todos los alquileres que ha hecho:
    CURSOR c_prestamos (periodo VARCHAR2, cliente VARCHAR2) IS
        SELECT p.cod_copia, p.fecha_inicio, p.fecha_fin, p.precio, p.pagado
        FROM prestamo p
        WHERE TO_CHAR(p.fecha_inicio,'MM/YYYY') = periodo
        AND p.dni_cliente = cliente;
    r_prestamos c_prestamos%ROWTYPE;--Registro para el cursor préstamos.
    
    --Declaramos las variables que vamos a necesitar por clientes, total por mes y total anual:
    v_anual_alquileres NUMBER :=0;
    v_anual_br NUMBER :=0;
    v_anual_dvd NUMBER :=0;
    v_anual_vhs NUMBER :=0;
    v_anual_deuda NUMBER :=0;
    v_anual_pagos NUMBER :=0;
    v_anual_sin_devolver NUMBER:=0;
    v_anual_lista_sin_devolver VARCHAR2(30000);
    v_mes_alquileres NUMBER :=0;
    v_mes_br NUMBER :=0;
    v_mes_dvd NUMBER :=0;
    v_mes_vhs NUMBER :=0;
    v_mes_deuda NUMBER :=0;
    v_mes_pagos NUMBER :=0;
    v_mes_sin_devolver NUMBER:=0;
    v_mes_lista_sin_devolver VARCHAR2(30000);
    v_alquileres NUMBER :=0;
    v_dvd NUMBER :=0;
    v_br NUMBER :=0;
    v_vhs NUMBER :=0;
    v_pagos NUMBER:=0;
    v_deuda NUMBER:=0;
    v_lista_sin_devolver VARCHAR2(30000);
    v_sin_devolver NUMBER:=0;
    
    --Declaro excepciones:
    e_aniomenor EXCEPTION;
    e_aniomayor EXCEPTION;
    
BEGIN   
    --Compruebo que el rango de año es válido:
    IF v_anio < 2015 THEN
        RAISE e_aniomenor;
    ELSIF v_anio > TO_CHAR(SYSDATE, 'YYYY') THEN
         RAISE e_aniomayor;        
    END IF;
    --Muestro el inicio del listado con el año a resumir:
    DBMS_OUTPUT.PUT_LINE('BALANCE TOTAL AÑO: '|| v_anio); 
    OPEN c_periodo;--Abro cursor del periodo.    
    LOOP--Lo recorremos almacenando en el registro.        
        FETCH c_periodo INTO r_periodo;
        EXIT WHEN c_periodo%NOTFOUND;--Hasta que no haya más valores.
        DBMS_OUTPUT.PUT_LINE('##########################################################################################################');
        DBMS_OUTPUT.PUT_LINE('MES/AÑO: '|| r_periodo.periodo);--Muestro el mes que vamos a resumir.        
        FOR r_clientes IN c_clientes(r_periodo.periodo) LOOP --Recorremos el segundo cursor completo, pasandole el periodo:
            DBMS_OUTPUT.PUT_LINE('-- CLIENTE: ' || r_clientes.CLIENTE|| '   Nº Socio: '|| r_clientes.num_socio||'   DNI: '|| r_clientes.dni_cliente);
            FOR r_prestamos IN c_prestamos(r_periodo.periodo,r_clientes.dni_cliente)LOOP --Recorremos el segundo cursor completo, pasandole el periodo y el dni del cliente:
            --Gestionamos la inserción de variables que vamos a necesitar, en función a lo que devuelva la consulta:
                CASE    
                    WHEN r_prestamos.cod_copia LIKE '%VHS%' THEN 
                        v_vhs:=v_vhs+1; 
                    WHEN r_prestamos.cod_copia LIKE '%DVD%' THEN 
                        v_dvd:=v_dvd+1; 
                    WHEN r_prestamos.cod_copia LIKE '%BR%' THEN 
                        v_br:=v_br+1;           
                END CASE; 
                
                CASE    
                    WHEN r_prestamos.pagado = 'S' THEN 
                        v_pagos:=v_pagos+r_prestamos.precio; 
                    WHEN r_prestamos.pagado = 'N' AND r_prestamos.fecha_fin IS NOT NULL THEN  
                        v_deuda:=v_deuda+r_prestamos.precio; 
                    WHEN r_prestamos.fecha_fin IS NULL THEN 
                        v_lista_sin_devolver:=CONCAT(v_lista_sin_devolver,'#'||r_prestamos.cod_copia);
                        v_sin_devolver:=v_sin_devolver+1;                        
                END CASE;     
            END LOOP;--cursor prestamos
            --Mostramos la información de cliente:
            v_alquileres:=v_vhs+v_dvd+v_br;
            DBMS_OUTPUT.PUT_LINE('  - Nº Alquileres: ' || v_alquileres||'     De los cuales:  VHS: '||v_vhs||'     DVD: '||v_dvd||'     BR: '||v_br);
            DBMS_OUTPUT.PUT_LINE('  - Películas sin devolver: ' || v_sin_devolver);
            IF v_sin_devolver>0 THEN--Condicional para mostrar la lista de códigos solo si existe tal lista.
                DBMS_OUTPUT.PUT_LINE('    Lista de códigos: ' || v_lista_sin_devolver);
            END IF;
            DBMS_OUTPUT.PUT_LINE('  - Total pagado: ' || v_pagos||'     Total a deber: '||v_deuda);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------------------------------------------');
            --Almaceno las variables totales por mes:
            v_mes_alquileres:=v_mes_alquileres+v_alquileres;
            v_mes_vhs:=v_mes_vhs+v_vhs;
            v_mes_dvd:=v_mes_dvd+v_dvd;
            v_mes_br:=v_mes_br+v_br;
            v_mes_sin_devolver:=v_mes_sin_devolver+v_sin_devolver;
            v_mes_lista_sin_devolver:=CONCAT(v_mes_lista_sin_devolver,v_lista_sin_devolver);
            v_mes_pagos:=v_mes_pagos+v_pagos;
            v_mes_deuda:=v_mes_deuda+v_deuda;             
            --Reseteo las variables para el próximo cliente:
            v_alquileres:=0;
            v_dvd:=0;
            v_br:=0;
            v_vhs:=0;
            v_pagos:=0;
            v_deuda:=0;
            v_sin_devolver:=0;
            v_lista_sin_devolver:='';            
        END LOOP;--cursor clientes.   
        --Muestro el balance por mes:
         DBMS_OUTPUT.PUT_LINE('BALANCE TOTAL FIN MES/AÑO: '|| r_periodo.periodo); 
         DBMS_OUTPUT.PUT_LINE('  - Nº Alquileres: ' || v_mes_alquileres||'     De los cuales:  VHS: '||v_mes_vhs||'     DVD: '||v_mes_dvd||'     BR: '||v_mes_br);
            DBMS_OUTPUT.PUT_LINE('  - Películas sin devolver: ' || v_mes_sin_devolver);
            IF v_mes_sin_devolver>0 THEN
                DBMS_OUTPUT.PUT_LINE('    Lista de códigos: ' || v_mes_lista_sin_devolver);
            END IF;
            DBMS_OUTPUT.PUT_LINE('  - Total pagado: ' || v_mes_pagos||'     Total a deber: '||v_mes_deuda);        
        --Almaceno las variables totales de año:
        v_anual_alquileres:=v_mes_alquileres+v_anual_alquileres;
        v_anual_vhs:=v_mes_vhs+v_anual_vhs;
        v_anual_dvd:=v_mes_dvd+v_anual_dvd;
        v_anual_br:=v_mes_br+v_anual_br;
        v_anual_sin_devolver:=v_mes_sin_devolver+v_anual_sin_devolver;
        v_anual_lista_sin_devolver:=CONCAT(v_anual_lista_sin_devolver,v_mes_lista_sin_devolver);
        v_anual_pagos:=v_mes_pagos+v_anual_pagos;
        v_anual_deuda:=v_mes_deuda+v_anual_deuda;          
        --Reseteo las de mes para el próximo periodo:
        v_mes_alquileres:=0;
        v_mes_vhs:=0;
        v_mes_dvd:=0;
        v_mes_br:=0;
        v_mes_sin_devolver:=0;
        v_mes_lista_sin_devolver:='';
        v_mes_pagos:=0;
        v_mes_deuda:=0;    
    END LOOP;--cursor periodo.
     DBMS_OUTPUT.PUT_LINE('##########################################################################################################');
     DBMS_OUTPUT.PUT_LINE('BALANCE TOTAL FIN AÑO: '|| v_anio); 
     DBMS_OUTPUT.PUT_LINE('  - Nº Alquileres: ' || v_anual_alquileres||'     De los cuales:  VHS: '||v_anual_vhs||'     DVD: '||v_anual_dvd||'     BR: '||v_anual_br);
            DBMS_OUTPUT.PUT_LINE('  - Películas sin devolver: ' || v_anual_sin_devolver);
            IF v_anual_sin_devolver>0 THEN
                DBMS_OUTPUT.PUT_LINE('    Lista de códigos: ' || v_anual_lista_sin_devolver);
            END IF;
            DBMS_OUTPUT.PUT_LINE('  - Total pagado: ' || v_anual_pagos||'     Total a deber: '||v_anual_deuda);
    CLOSE c_periodo;--Cierro cursor principal.  
        
    EXCEPTION--Recojo excepciones:
        WHEN e_aniomenor THEN
            dbms_output.put_line('ERROR ORA-20004: Nuestro videoclub abrió en 2015, no puede consultar datos de años previos.');
        WHEN e_aniomayor THEN    
            dbms_output.put_line('ERROR ORA-20005: No puede consultar datos de años posteriores al actual.');
        WHEN OTHERS THEN--Cualquier otra excepción que no podamos preveer.   
            dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END;--Fin procedimiento.
/

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
--Creo los triggers para las auditorías, comento el primero nada más, el resto solo se diferencian en el nombre de tabla y atributos:
CREATE OR REPLACE TRIGGER t_audit_cliente
    AFTER INSERT OR DELETE OR UPDATE ON cliente --Siempre que se haga una sentencia de modificación con éxito en la tabla.
    FOR EACH ROW --Uso FOR EACH para acceder a los valores NEW y OLD
    ENABLE --Cuando compile con éxito, que se active por defecto.
    DECLARE
        v_old VARCHAR2(200); --Variables para almacenar los registros
        v_new VARCHAR2(200);
        v_opc NUMBER(1);--Esta variable nos permite hacer luego la búsqueda de procesos de auditoría de manera más eficiente.
    BEGIN                
        CASE--Inicio del case para controlar si es inserción, modificación o borrado.
        WHEN INSERTING THEN --La estructura es la misma, almaceno la opción en el number y concateno todos los atributos de la tabla en una sola linea.
            v_opc:=1;
            v_old:=(NULL);
            v_new:=(:NEW.NUM_SOCIO||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.NOMBRE||'*'||:NEW.APELLIDO1||'*'||:NEW.APELLIDO2||'*'||:NEW.DOMICILIO||'*'||:NEW.EMAIL||'*'||:NEW.DEUDA);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.NUM_SOCIO||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.NOMBRE||'*'||:OLD.APELLIDO1||'*'||:OLD.APELLIDO2||'*'||:OLD.DOMICILIO||'*'||:OLD.EMAIL||'*'||:OLD.DEUDA);
            v_new:=(:NEW.NUM_SOCIO||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.NOMBRE||'*'||:NEW.APELLIDO1||'*'||:NEW.APELLIDO2||'*'||:NEW.DOMICILIO||'*'||:NEW.EMAIL||'*'||:NEW.DEUDA);
             
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=NULL;
            v_old:=(:OLD.NUM_SOCIO||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.NOMBRE||'*'||:OLD.APELLIDO1||'*'||:OLD.APELLIDO2||'*'||:OLD.DOMICILIO||'*'||:OLD.EMAIL||'*'||:OLD.DEUDA);

        END CASE;--Terminamos el case.
        INSERT INTO audit_cliente VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);--Hacemos la inserción con las opciones.
        
        EXCEPTION
        WHEN OTHERS THEN--Cualquier excepción que no podamos preveer.   
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_cliente;
/

CREATE OR REPLACE TRIGGER t_audit_copia_fisica
    AFTER INSERT OR DELETE OR UPDATE ON copia_fisica
    FOR EACH ROW
    ENABLE
    DECLARE
        v_old VARCHAR2(200);
        v_new VARCHAR2(200);
        v_opc NUMBER(1);
    BEGIN                
        CASE
        WHEN INSERTING THEN
            v_opc:=1;
            v_old:=NULL;
            v_new:=(:NEW.COD_COPIA||'*'||:NEW.COD_PEL||'*'||:NEW.NOMBRE||'*'||:NEW.NIF_DIST||'*'||:NEW.FORMATO||'*'||:NEW.PRESTADO);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.COD_COPIA||'*'||:OLD.COD_PEL||'*'||:OLD.NOMBRE||'*'||:OLD.NIF_DIST||'*'||:OLD.FORMATO||'*'||:OLD.PRESTADO);
            v_new:=(:NEW.COD_COPIA||'*'||:NEW.COD_PEL||'*'||:NEW.NOMBRE||'*'||:NEW.NIF_DIST||'*'||:NEW.FORMATO||'*'||:NEW.PRESTADO);
                
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=NULL;
            v_old:=(:OLD.COD_COPIA||'*'||:OLD.COD_PEL||'*'||:OLD.NOMBRE||'*'||:OLD.NIF_DIST||'*'||:OLD.FORMATO||'*'||:OLD.PRESTADO);

        END CASE;
        INSERT INTO audit_copia_fisica VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);
        
        EXCEPTION
        WHEN OTHERS THEN
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_copia_fisica;
/

CREATE OR REPLACE TRIGGER t_audit_distribuidor
    AFTER INSERT OR DELETE OR UPDATE ON distribuidor
    FOR EACH ROW
    ENABLE
    DECLARE
        v_old VARCHAR2(200);
        v_new VARCHAR2(200);
        v_opc NUMBER(1);
    BEGIN                
        CASE
        WHEN INSERTING THEN
            v_opc:=1;
            v_old:=NULL;
            v_new:=(:NEW.NIF_DIST||'*'||:NEW.NOMBRE||'*'||:NEW.DIRECCION||'*'||:NEW.TELEFONO||'*'||:NEW.EMAIL||'*'||:NEW.NOMBRE_CONTACTO);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.NIF_DIST||'*'||:OLD.NOMBRE||'*'||:OLD.DIRECCION||'*'||:OLD.TELEFONO||'*'||:OLD.EMAIL||'*'||:OLD.NOMBRE_CONTACTO);
            v_new:=(:NEW.NIF_DIST||'*'||:NEW.NOMBRE||'*'||:NEW.DIRECCION||'*'||:NEW.TELEFONO||'*'||:NEW.EMAIL||'*'||:NEW.NOMBRE_CONTACTO);
                
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=NULL;
            v_old:=(:OLD.NIF_DIST||'*'||:OLD.NOMBRE||'*'||:OLD.DIRECCION||'*'||:OLD.TELEFONO||'*'||:OLD.EMAIL||'*'||:OLD.NOMBRE_CONTACTO);

        END CASE;
        INSERT INTO audit_distribuidor VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);
        
        EXCEPTION
        WHEN OTHERS THEN
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_distribuidor;
/

CREATE OR REPLACE TRIGGER t_audit_pelicula
    AFTER INSERT OR DELETE OR UPDATE ON pelicula
    FOR EACH ROW
    ENABLE
    DECLARE
        v_old VARCHAR2(200);
        v_new VARCHAR2(200);
        v_opc NUMBER(1);
    BEGIN                
        CASE
        WHEN INSERTING THEN
            v_opc:=1;
            v_old:=NULL;
            v_new:=(:NEW.COD_PEL||'*'||:NEW.NOMBRE||'*'||:NEW.DIRECTOR||'*'||:NEW.INTERPRETE1||'*'||:NEW.INTERPRETE2||'*'||:NEW.PRODUCTORA||'*'||:NEW.FECHA_SALIDA||'*'||:NEW.GENERO);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.COD_PEL||'*'||:OLD.NOMBRE||'*'||:OLD.DIRECTOR||'*'||:OLD.INTERPRETE1||'*'||:OLD.INTERPRETE2||'*'||:OLD.PRODUCTORA||'*'||:OLD.FECHA_SALIDA||'*'||:OLD.GENERO);
            v_new:=(:NEW.COD_PEL||'*'||:NEW.NOMBRE||'*'||:NEW.DIRECTOR||'*'||:NEW.INTERPRETE1||'*'||:NEW.INTERPRETE2||'*'||:NEW.PRODUCTORA||'*'||:NEW.FECHA_SALIDA||'*'||:NEW.GENERO);
                
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=NULL;
            v_old:=(:OLD.COD_PEL||'*'||:OLD.NOMBRE||'*'||:OLD.DIRECTOR||'*'||:OLD.INTERPRETE1||'*'||:OLD.INTERPRETE2||'*'||:OLD.PRODUCTORA||'*'||:OLD.FECHA_SALIDA||'*'||:OLD.GENERO);

        END CASE;
        INSERT INTO audit_pelicula VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);
        
        EXCEPTION
        WHEN OTHERS THEN
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_pelicula;
/

CREATE OR REPLACE TRIGGER t_audit_prestamo
    AFTER INSERT OR DELETE OR UPDATE ON prestamo
    FOR EACH ROW
    ENABLE
    DECLARE
        v_old VARCHAR2(200);
        v_new VARCHAR2(200);
        v_opc NUMBER(1);
    BEGIN                
        CASE
        WHEN INSERTING THEN
            v_opc:=1;
            v_old:=NULL;
            v_new:=(:NEW.COD_COPIA||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.FECHA_INICIO||'*'||:NEW.FECHA_FIN||'*'||:NEW.PRECIO||'*'||:NEW.PAGADO);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.COD_COPIA||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.FECHA_INICIO||'*'||:OLD.FECHA_FIN||'*'||:OLD.PRECIO||'*'||:OLD.PAGADO);
            v_new:=(:NEW.COD_COPIA||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.FECHA_INICIO||'*'||:NEW.FECHA_FIN||'*'||:NEW.PRECIO||'*'||:NEW.PAGADO);
                
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=NULL;
            v_old:=(:OLD.COD_COPIA||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.FECHA_INICIO||'*'||:OLD.FECHA_FIN||'*'||:OLD.PRECIO||'*'||:OLD.PAGADO);

        END CASE;
        INSERT INTO audit_prestamo VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);
        
        EXCEPTION
        WHEN OTHERS THEN
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_prestamo;
/
--Con este pequeño disparador nos aseguramos de perder la consistencia de la secuencia de creación de usuario. 
CREATE OR REPLACE TRIGGER t_numSocio_control
    BEFORE UPDATE OF NUM_SOCIO ON CLIENTE
    ENABLE
BEGIN
    RAISE_APPLICATION_ERROR(-20005,'El número de socio no puede ser cambiado, sólo creado o eliminado.');
END;
/

--INSERCIÓN DE DATOS

INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'34950782M','Alejandro', 'Salgado', 'Cerdeira', 'Montequinto', 'ragg@hotmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'85641873Q','Laura', 'Minguet', 'Criado', 'Utrera', null,0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'08920704Q','Mario', 'García', 'Navarro', 'Sevilla', 'jupot@gmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'58005550X','Javier', 'Farratel', null, 'Sevilla', 'amra@yahoo.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'28494432P','Pablo', 'Vilches', null, 'Ctra. Cartuja', 'akodo@terra.es',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'75868435Z','Magdalena', 'Cerdeira', 'Gayol', 'Ortiguera', 'mila@hotmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'37905847F','Francisco', 'Salgado', 'Jiménez', 'Carmona', 'vandalia@gmail.com',5.2);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'48241838M','María', 'Minguet', 'Criado', 'Utrera', null,0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'40236732A','Laura', 'García', 'Navarro', 'Bda. San Diego', 'haru@gmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'51284287Z','Julio', 'Barrientos', 'Natera', 'Oxford', 'desajado@gmail.es',3.5);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'03047335L','Ester', 'Villalobos', 'Gutiérrez', 'Tomares', null,0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'29985612Y','Alejandro', 'Vilches', null, 'San Jerónimo', 'akka@gmail.com',10);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'46142863X','Juan Manuel', 'Marrufo', 'Lagares', 'Avda. La Salle', 'juanmez@terra.es',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'56711900H','Francisco', 'Mulero', 'Arenillas', 'Dos Hermanas', 'cabinadenemo@gmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'81525016K','Pedro', 'Román', null, 'Dos Hermanas', 'darkdroo@outlook.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'22958825H','Vicente', 'Pluma', null, 'Avda. de la Cruz del Campo', 'quoththeraven@gmail.es',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'23161510G','Javier', 'Díaz', 'Barragán', 'Valladolid', 'jdb@gmail.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'07783618G','Adrián', 'Yuste', 'González', 'Castilleja de la Cuesta', 'adri@hotmail.com',4.5);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'80470083Y','David', 'Chamizo', null, 'Tomares', 'harleymix@yahoo.com',0);
INSERT INTO cliente VALUES (SEQ_NUM_SOCIO.nextval,'60657362Z','Belén', 'Rodríguez', 'Márquez', 'Montequinto', 'berm@gmail.com',0);

INSERT INTO pelicula VALUES ('JPI','Jurassic Park','Steven Spielberg','Sam Neill','Laura Dern','Universal Pictures','1993','Ciencia Ficción');
INSERT INTO pelicula VALUES ('JPII','Jurassic Park II: El Mundo Perdido','Steven Spielberg','Jeff Goldblum','Julianne Moore','Universal Pictures','1997','Ciencia Ficción');
INSERT INTO pelicula VALUES ('JPIII','Jurassic Park III','Joe Johnston','Sam Neill','William H. Macy','Universal Pictures','2001','Ciencia Ficción');
INSERT INTO pelicula VALUES ('JUWOI','Jurassic World','Colin Trevorrow','Chris Pratt','Bryce Dallas Howard','Universal Pictures','2015','Ciencia Ficción');
INSERT INTO pelicula VALUES ('JUWOII','Jurassic World II: El Reino Caido','J.A. Bayona','Chris Pratt','Bryce Dallas Howard','Universal Pictures','2018','Ciencia Ficción');
INSERT INTO pelicula VALUES ('KOYQAT','Koyaanisqatsi','Godfrey Reggio',null,null,'American Zoetrope','1982','Documental');
INSERT INTO pelicula VALUES ('ACPOT','El acorazado Potemkin','Sergei M. Eisenstein','Aleksandr Antonov','Vladimir Barskiy','Goskino','1925','Drama');
INSERT INTO pelicula VALUES ('SEPSEL','El séptimo sello','Ingmar Bergman','Gunnar Björnstrand','Bengt Ekerot','Svensk Filmindustri','1957','Drama');
INSERT INTO pelicula VALUES ('CARFAN','La carreta fantasma','Victor Sjöström','Victor Sjöström','Hilda Borgström','Svensk Filmindustri','1921','Drama');
INSERT INTO pelicula VALUES ('BRUTIE','La brujería a través de los tiempos','Benjamin Christensen','Maren Pedersen','Clara Pontoppidan','Svensk Filmindustri','1922','Documental');
INSERT INTO pelicula VALUES ('CADRCA','El gabinete del Dr. Caligari','Robert Wiene','Werner Krauss','Conrad Veidt','Decla-Bioscop AG','1920','Terror');
INSERT INTO pelicula VALUES ('NOSFER','Nosferatu','F.W. Murnau','Max Schreck','Greta Schröder','Jofa-Atelier Berlin-Johannisthal','1922','Terror');
INSERT INTO pelicula VALUES ('METROP','Metrópolis','Fritz Lang','Alfred Abel','Brigitte Helm','Universum Film','1927','Ciencia Ficción');
INSERT INTO pelicula VALUES ('BLASIE','Blancanieves y los siete enanitos','William Cottrell','Adriana Caselotti','Roy Atwell','Walt Disney Pictures','1931','Animación');
INSERT INTO pelicula VALUES ('FANTAS','Fantasía','Variado','Leopold Stokowski','The Philadelphia Orchestra','Walt Disney Pictures','1940','Animación');
INSERT INTO pelicula VALUES ('CFI','Los Cazafantasmas','Ivan Reitman','Bill Murray','Dan Aykroyd','Columbia Pictures','1984','Comedia');
INSERT INTO pelicula VALUES ('CFII','Los Cazafantasmas II','Ivan Reitman','Bill Murray','Dan Aykroyd','Columbia Pictures','1989','Comedia');
INSERT INTO pelicula VALUES ('MTRXI','Matrix ','Las hermanas Wachowski','Keanu Reeves','Carrie-Anne Moss','Warner Bros','1999','Ciencia Ficción');
INSERT INTO pelicula VALUES ('MTRXII','Matrix II: Reloaded ','Las hermanas Wachowski','Keanu Reeves','Carrie-Anne Moss','Warner Bros','2003','Ciencia Ficción');
INSERT INTO pelicula VALUES ('MTRXIII','Matrix III: Revolutions ','Las hermanas Wachowski','Keanu Reeves','Carrie-Anne Moss','Warner Bros','2003','Ciencia Ficción');
INSERT INTO pelicula VALUES ('MTRXAN','Animatrix','Variado','Tara Strong','John DiMaggio','Warner Bros','2003','Animación');
INSERT INTO pelicula VALUES ('MMFR','Mad Max: Furia en la carretera','George Miller','Tom Hardy','Charlize Theron','Warner Bros','2015','Acción');
INSERT INTO pelicula VALUES ('LOTRAN','El señor de los anillos','Ralph Bakshi','John Hurt','Anthony Daniels','Bakshi Productions','1978','Animación');
INSERT INTO pelicula VALUES ('LOTRI','El señor de los anillos: La Comunidad del Anillo','Peter Jackson','Elijah Wood','Ian McKellen','New Line Cinema','2001','Fantasía');
INSERT INTO pelicula VALUES ('LOTRII','El señor de los anillos: Las Dos Torres','Peter Jackson','Elijah Wood','Andy Serkis','New Line Cinema','2002','Fantasía');
INSERT INTO pelicula VALUES ('LOTRIII','El señor de los anillos: El Retorno del Rey','Peter Jackson','Elijah Wood','Viggo Mortensen','New Line Cinema','2003','Fantasía');
INSERT INTO pelicula VALUES ('MALVEN','Maldita Venganza','David Chamizo','Chema Álvarez','María Espejo','Bobina Verde','2015','Road-Movie');
INSERT INTO pelicula VALUES ('TPIANO','El piano','Jane Campion','Holly Hunter','Sam Neill','CiBy 2000','1993','Drama');
INSERT INTO pelicula VALUES ('AGORA','Ágora','Alejandro Amenábar','Rachel Weisz','Oscar Isaac','Mod Producciones','2009','Drama');
INSERT INTO pelicula VALUES ('POSIJA','Por siempre jamás','Andy Tennant','Drew Barrymore','Anjelica Huston',' Twentieth Century Fox','1998','Romance');
INSERT INTO pelicula VALUES ('PERSEP','Persépolis','Marjane Satrapi','Chiara Mastroianni','Danielle Darrieux','2.4.7. Films','2007','Animación');
INSERT INTO pelicula VALUES ('EMENI','El Mundo es Nuestro','Alfonso Sánchez','Alberto López','Alfonso Sánchez','Mundoficción Producciones','2012','Comedia');
INSERT INTO pelicula VALUES ('ELMESI','El Mundo es Suyo','Alfonso Sánchez','Alberto López','Alfonso Sánchez','Mundoficción Producciones','2018','Comedia');
INSERT INTO pelicula VALUES ('VDVEN','V de Vendetta','James McTeigue','Hugo Weaving','Natalie Portman','Warner Bros','2005','Acción');
INSERT INTO pelicula VALUES ('HEREDI','Hereditary','Ari Aster','Toni Collette','Alex Wolff','A24','2018','Terror');
INSERT INTO pelicula VALUES ('MIDSOM','Midsommar','Ari Aster','Florence Pugh','Jack Reynor','A24','2019','Terror');
INSERT INTO pelicula VALUES ('AMORIM','Los amores imaginarios','Xavier Dolan','Xavier Dolan','Anne Dorval','Alliance Atlantis','2010','Romance');

INSERT INTO DISTRIBUIDOR VALUES ('D05095732','A CONTRACORRIENTE FILMS SL','C/ Lincoln, 11, Barcelona', 935398536,'ventas@acontracorrientefilms.com','Carles Bodell');
INSERT INTO DISTRIBUIDOR VALUES ('R4914917B','EONE FILMS','Avd. de Burgos,12, Madrid',917684800,'info@eone.es','Sara Gurruchaga');
INSERT INTO DISTRIBUIDOR VALUES ('E63674246','PARAMOUNT PICTURES SPAIN','C/ Albacete,3, Madrid',913225800,'sales@paramountpictures.es','Jack Torance');
INSERT INTO DISTRIBUIDOR VALUES ('R6409255D','SONY PICTURES RELEASING DE ESPAÑA','Pedro de Valdivia,10, Madrid',913777100,'info@sonyspain.com','Jonah Jameson');
INSERT INTO DISTRIBUIDOR VALUES ('R5267199G','UNIVERSAL PICTURES INTERNATIONAL SPAIN','Pº de la Castellana,95, Madrid', 915227261,'info@universalpictures.es','Jacinto Molina');
INSERT INTO DISTRIBUIDOR VALUES ('W5922977C','BUENA VISTA INTERNATIONAL SPAIN','C/ José Bardasanos Baos,9,Madrid',913830732,'help@disney.co.uk','Paul Naschy');
INSERT INTO DISTRIBUIDOR VALUES ('B28860534','WARNER BROS. PICTURES INTERNATIONAL ESPAÑA','C/Martínez Villergas,52,Madrid',912160699,'belen.caballero@warnerbros.com','Belén Caballero');
INSERT INTO DISTRIBUIDOR VALUES ('B90080078','Bobina Verde','Glorieta del Agua, Tomares',955879663,'info@bobinaverde.es','Jandro Salgado');
INSERT INTO DISTRIBUIDOR VALUES ('B63061857','Selectavision ','Calle Calatrava,6, Barcelona',934022222,'info@selecta-vision.com','Miguel Sanjulian');
INSERT INTO DISTRIBUIDOR VALUES ('B91945550','Acheron Films','Calle Macasta,24,Sevilla',954953130,'ventas@acheron.es',null);

EXEC p_insertar_copia('JPI','D05095732','DVD');
EXEC p_insertar_copia('JPI','D05095732','DVD');
EXEC p_insertar_copia('JPI','R6409255D','VHS');
EXEC p_insertar_copia('JPI','D05095732','BR');
EXEC p_insertar_copia('JPI','D05095732','BR');
EXEC p_insertar_copia('JPI','R5267199G','BR');
EXEC p_insertar_copia('JPII','R5267199G','BR');
EXEC p_insertar_copia('JPII','R5267199G','BR');
EXEC p_insertar_copia('JPII','R5267199G','BR');
EXEC p_insertar_copia('JPII','R6409255D','VHS');
EXEC p_insertar_copia('JPIII','R6409255D','VHS');
EXEC p_insertar_copia('JPIII','R5267199G','BR');
EXEC p_insertar_copia('JPIII','R5267199G','BR');
EXEC p_insertar_copia('JPIII','R5267199G','BR');
EXEC p_insertar_copia('JPIII','W5922977C','DVD');
EXEC p_insertar_copia('JUWOI','B63061857','BR');
EXEC p_insertar_copia('JUWOI','B63061857','BR');
EXEC p_insertar_copia('JUWOI','B63061857','BR');
EXEC p_insertar_copia('JUWOII','B63061857','BR');
EXEC p_insertar_copia('JUWOII','B63061857','BR');
EXEC p_insertar_copia('JUWOII','B63061857','BR');
EXEC p_insertar_copia('KOYQAT','B90080078','VHS');
EXEC p_insertar_copia('KOYQAT','R6409255D','DVD');
EXEC p_insertar_copia('KOYQAT','R6409255D','DVD');
EXEC p_insertar_copia('KOYQAT','R6409255D','DVD');
EXEC p_insertar_copia('KOYQAT','E63674246','BR');
EXEC p_insertar_copia('ACPOT','R4914917B','BR');
EXEC p_insertar_copia('ACPOT','W5922977C','DVD');
EXEC p_insertar_copia('SEPSEL','W5922977C','DVD');
EXEC p_insertar_copia('CARFAN','R4914917B','VHS');
EXEC p_insertar_copia('BRUTIE','R4914917B','VHS');
EXEC p_insertar_copia('CADRCA','B91945550','DVD');
EXEC p_insertar_copia('CADRCA','B91945550','DVD');
EXEC p_insertar_copia('NOSFER','B90080078','DVD');
EXEC p_insertar_copia('NOSFER','B90080078','DVD');
EXEC p_insertar_copia('NOSFER','B90080078','BR');
EXEC p_insertar_copia('METROP','W5922977C','DVD');
EXEC p_insertar_copia('BLASIE','W5922977C','VHS');
EXEC p_insertar_copia('BLASIE','W5922977C','VHS');
EXEC p_insertar_copia('BLASIE','W5922977C','DVD');
EXEC p_insertar_copia('BLASIE','W5922977C','BR');
EXEC p_insertar_copia('FANTAS','W5922977C','VHS');
EXEC p_insertar_copia('FANTAS','W5922977C','DVD');
EXEC p_insertar_copia('CFI','R5267199G','VHS');
EXEC p_insertar_copia('CFI','R5267199G','VHS');
EXEC p_insertar_copia('CFI','R5267199G','VHS');
EXEC p_insertar_copia('CFI','R5267199G','DVD');
EXEC p_insertar_copia('CFI','R5267199G','BR');
EXEC p_insertar_copia('CFII','R5267199G','VHS');
EXEC p_insertar_copia('CFII','R5267199G','VHS');
EXEC p_insertar_copia('CFII','R5267199G','DVD');
EXEC p_insertar_copia('MTRXI','B28860534','DVD');
EXEC p_insertar_copia('MTRXI','B28860534','DVD');
EXEC p_insertar_copia('MTRXI','B28860534','DVD');
EXEC p_insertar_copia('MTRXI','B28860534','BR');
EXEC p_insertar_copia('MTRXI','B28860534','BR');
EXEC p_insertar_copia('MTRXI','B28860534','BR');
EXEC p_insertar_copia('MTRXII','B28860534','BR');
EXEC p_insertar_copia('MTRXII','B28860534','BR');
EXEC p_insertar_copia('MTRXII','B28860534','BR');
EXEC p_insertar_copia('MTRXII','B28860534','DVD');
EXEC p_insertar_copia('MTRXIII','B28860534','BR');
EXEC p_insertar_copia('MTRXIII','B28860534','BR');
EXEC p_insertar_copia('MTRXAN','B28860534','VHS');
EXEC p_insertar_copia('MTRXAN','B28860534','DVD');
EXEC p_insertar_copia('MTRXAN','B28860534','DVD');
EXEC p_insertar_copia('MMFR','D05095732','BR');
EXEC p_insertar_copia('MMFR','D05095732','BR');
EXEC p_insertar_copia('MMFR','D05095732','BR');
EXEC p_insertar_copia('LOTRAN','B63061857','VHS');
EXEC p_insertar_copia('LOTRAN','B63061857','DVD');
EXEC p_insertar_copia('LOTRI','E63674246','DVD');
EXEC p_insertar_copia('LOTRI','E63674246','DVD');
EXEC p_insertar_copia('LOTRI','E63674246','DVD');
EXEC p_insertar_copia('LOTRI','E63674246','BR');
EXEC p_insertar_copia('LOTRI','E63674246','BR');
EXEC p_insertar_copia('LOTRI','E63674246','BR');
EXEC p_insertar_copia('LOTRII','E63674246','BR');
EXEC p_insertar_copia('LOTRII','E63674246','BR');
EXEC p_insertar_copia('LOTRII','E63674246','BR');
EXEC p_insertar_copia('LOTRII','E63674246','DVD');
EXEC p_insertar_copia('LOTRIII','E63674246','BR');
EXEC p_insertar_copia('LOTRIII','E63674246','BR');
EXEC p_insertar_copia('MALVEN','B63061857','BR');
EXEC p_insertar_copia('MALVEN','B63061857','BR');
EXEC p_insertar_copia('TPIANO','R4914917B','DVD');
EXEC p_insertar_copia('AGORA','R6409255D','DVD');
EXEC p_insertar_copia('AGORA','R6409255D','DVD');
EXEC p_insertar_copia('AGORA','R6409255D','BR');
EXEC p_insertar_copia('POSIJA','R6409255D','DVD');
EXEC p_insertar_copia('PERSEP','B63061857','DVD');
EXEC p_insertar_copia('PERSEP','B63061857','BR');
EXEC p_insertar_copia('EMENI','B91945550','DVD');
EXEC p_insertar_copia('EMENI','B91945550','BR');
EXEC p_insertar_copia('ELMESI','B91945550','BR');
EXEC p_insertar_copia('VDVEN','B28860534','DVD');
EXEC p_insertar_copia('VDVEN','B28860534','DVD');
EXEC p_insertar_copia('VDVEN','B28860534','BR');
EXEC p_insertar_copia('VDVEN','B28860534','BR');
EXEC p_insertar_copia('HEREDI','R4914917B','BR');
EXEC p_insertar_copia('HEREDI','R4914917B','BR');
EXEC p_insertar_copia('MIDSOM','R4914917B','BR');
EXEC p_insertar_copia('MIDSOM','R4914917B','BR');
EXEC p_insertar_copia('AMORIM','R4914917B','DVD');

INSERT INTO PRESTAMO VALUES ('JPIBR1','34950782M','07-03-2015','10-03-2015',9,'S');
INSERT INTO PRESTAMO VALUES ('JPIIVHS1','34950782M','07-03-2015','10-03-2015',3,'S');
INSERT INTO PRESTAMO VALUES ('KOYQATDVD1','48241838M','11-06-2015','13-06-2015',4,'S');
INSERT INTO PRESTAMO VALUES ('CFIBR1','81525016K','05-12-2015','06-12-2015',1,'S');
INSERT INTO PRESTAMO VALUES ('CFIVHS1','56711900H','25-05-2015','28-05-2015',3,'S');
INSERT INTO PRESTAMO VALUES ('BLASIEBR1','85641873Q','07-04-2015','09-04-2015',6,'S');
INSERT INTO PRESTAMO VALUES ('LOTRANVHS1','08920704Q','29-10-2015','31-10-2015',2,'S');
INSERT INTO PRESTAMO VALUES ('LOTRIDVD2','08920704Q','29-10-2015','31-10-2015',4,'S');
INSERT INTO PRESTAMO VALUES ('MTRXIDVD3','48241838M','15-02-2015','18-02-2015',6,'S');
INSERT INTO PRESTAMO VALUES ('AGORADVD1','75868435Z','18-09-2015','20-09-2015',4,'S');
INSERT INTO PRESTAMO VALUES ('NOSFERDVD2','22958825H','05-08-2015','06-08-2015',2,'S');
INSERT INTO PRESTAMO VALUES ('MIDSOMBR1','46142863X','12-12-2015',NULL,NULL,'N');
INSERT INTO PRESTAMO VALUES ('VDVENDVD2','58005550X','08-01-2015','12-01-2015',8,'N');
INSERT INTO PRESTAMO VALUES ('LOTRIBR3','29985612Y','06-05-2015','09-05-2015',9,'N');
INSERT INTO PRESTAMO VALUES ('JUWOIBR2','37905847F','05-07-2015',NULL,NULL,'N');
INSERT INTO PRESTAMO VALUES ('HEREDIBR2','40236732A','07-10-2015','10-10-2015',9,'N');

COMMIT;


    