--Procedimiento para que recibiendo un año, devuelva el balance del mismo, por mes.

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
    
BEGIN   
    --Compruebo que el rango de año es válido:
    IF v_anio < 2015 THEN
             RAISE_APPLICATION_ERROR(-20004,'Nuestro vidoclub abrió en 2015, no puede consultar datos de años previos.');
    ELSIF v_anio > TO_CHAR(SYSDATE, 'YYYY') THEN
         RAISE_APPLICATION_ERROR(-20005,'No puede consultar datos de años que aún no han ocurrido.');        
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
        
    EXCEPTION
        WHEN OTHERS THEN--Cualquier otra excepción que no podamos preveer.   
                dbms_output.put_line('Se ha producido el siguiente error: '||sqlerrm);
END;--Fin procedimiento.
/

EXEC p_listado_balance_anual ('2015');