--Con este pequeño disparador nos aseguramos de perder la consistencia de la secuencia de creación de usuario. 

CREATE OR REPLACE TRIGGER t_numSocio_control
    BEFORE UPDATE OF NUM_SOCIO ON CLIENTE
    ENABLE
BEGIN
    RAISE_APPLICATION_ERROR(-20005,'El número de socio no puede ser cambiado, sólo creado o eliminado.');
END;
/
