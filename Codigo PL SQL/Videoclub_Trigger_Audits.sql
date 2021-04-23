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