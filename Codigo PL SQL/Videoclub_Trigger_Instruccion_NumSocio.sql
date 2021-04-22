--Con este peque�o disparador nos aseguramos de perder la consistencia de la secuencia de creaci�n de usuario. 

CREATE OR REPLACE TRIGGER t_numSocio_control
    BEFORE UPDATE OF NUM_SOCIO ON CLIENTE
    ENABLE
BEGIN
    RAISE_APPLICATION_ERROR(-20005,'El n�mero de socio no puede ser cambiado, s�lo creado o eliminado.');
END;
/
