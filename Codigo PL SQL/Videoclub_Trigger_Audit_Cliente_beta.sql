
CREATE OR REPLACE TRIGGER t_audit_cliente
    AFTER INSERT OR DELETE OR UPDATE ON cliente
    FOR EACH ROW
    ENABLE
    DECLARE
        v_old VARCHAR2(60);
        v_new VARCHAR2(60);
        v_opc NUMBER(1);
    BEGIN                
        CASE
        WHEN INSERTING THEN
            v_opc:=1;
            v_old:=NULL;
            v_new:=(:NEW.NUM_SOCIO||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.NOMBRE||'*'||:NEW.APELLIDO1||'*'||:NEW.APELLIDO2||'*'||:NEW.DOMICILIO||'*'||:NEW.EMAIL||'*'||:NEW.DEUDA);
                
        WHEN UPDATING THEN
            v_opc:=2;
            v_old:=(:OLD.NUM_SOCIO||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.NOMBRE||'*'||:OLD.APELLIDO1||'*'||:OLD.APELLIDO2||'*'||:OLD.DOMICILIO||'*'||:OLD.EMAIL||'*'||:OLD.DEUDA);
            v_new:=(:NEW.NUM_SOCIO||'*'||:NEW.DNI_CLIENTE||'*'||:NEW.NOMBRE||'*'||:NEW.APELLIDO1||'*'||:NEW.APELLIDO2||'*'||:NEW.DOMICILIO||'*'||:NEW.EMAIL||'*'||:NEW.DEUDA);
                
        WHEN DELETING THEN
            v_opc:=3;
            v_new:=(NULL);
            v_old:=(:OLD.NUM_SOCIO||'*'||:OLD.DNI_CLIENTE||'*'||:OLD.NOMBRE||'*'||:OLD.APELLIDO1||'*'||:OLD.APELLIDO2||'*'||:OLD.DOMICILIO||'*'||:OLD.EMAIL||'*'||:OLD.DEUDA);

        END CASE;
        INSERT INTO audit_cliente VALUES (USER, SYSTIMESTAMP, v_opc, v_old, v_new);
        
        EXCEPTION
        WHEN OTHERS THEN--Cualquier otra excepción que no podamos preveer.   
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END t_audit_cliente;
/