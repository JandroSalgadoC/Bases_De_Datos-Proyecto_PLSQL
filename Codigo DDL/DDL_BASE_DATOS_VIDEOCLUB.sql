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
    NUM_SOCIO NUMBER(4) CONSTRAINT CLI_NUM_NN NOT NULL,
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



