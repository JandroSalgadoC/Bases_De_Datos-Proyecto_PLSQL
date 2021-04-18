
CREATE TABLE PELICULA
(
    COD_PEL VARCHAR2(10)CONSTRAINT PEL_COD_PK PRIMARY KEY,
    NOMBRE VARCHAR2(30)CONSTRAINT PEL_NOM_NN NOT NULL,
    DIRECTOR VARCHAR2(20)CONSTRAINT PEL_DIR_NN NOT NULL,
    INTERPRETE1 VARCHAR2(20),
    INTERPRETE2 VARCHAR2(20),
    PRODUCTORA VARCHAR2(20),
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
    EMAIL VARCHAR2(20),
    DEUDA NUMBER(5,2)
);


CREATE TABLE DISTRIBUIDOR
(
    NIF_DIST VARCHAR2(9)CONSTRAINT DIS_NIF_PK PRIMARY KEY,
    NOMBRE VARCHAR2(20)CONSTRAINT DIS_NOM_NN NOT NULL CONSTRAINT DIS_NOM_UK UNIQUE,
    DIRECCION VARCHAR2(30)CONSTRAINT DIS_DIR_NN NOT NULL,
    TELEFONO NUMBER(11) CONSTRAINT DIS_TEL_NN NOT NULL, 
    EMAIL VARCHAR2(20),
    NOMBRE_CONTACTO VARCHAR2(20)
);

CREATE TABLE COPIA_FISICA
(
    COD_COPIA VARCHAR2(11)CONSTRAINT COP_COD_PK PRIMARY KEY,
    COD_PEL VARCHAR2(5)CONSTRAINT COP_COD_NN NOT NULL CONSTRAINT COP_COD_FK REFERENCES PELICULA,
    NIF_DIST VARCHAR2(9)CONSTRAINT COP_NIF_NN NOT NULL CONSTRAINT COP_NIF_FK REFERENCES DISTRIBUIDOR,
    FORMATO VARCHAR2(3)CONSTRAINT COP_FOR_CK CHECK (FORMATO IN ('DVD','VHS','BR')),
    PRESTADO CHAR(1) DEFAULT 'N' CONSTRAINT COP_PRE_NN NOT NULL CONSTRAINT COP_PRE_CK CHECK(UPPER(PRESTADO)IN('S','N')) 
);

CREATE TABLE PRESTAMO
(
    COD_COPIA VARCHAR2(11)CONSTRAINT PRE_COD_FK REFERENCES COPIA_FISICA,
    DNI_CLIENTE CHAR(9)CONSTRAINT PRE_DNI_FK REFERENCES CLIENTE,
    FECHA_INICIO DATE, 
    FECHA_FIN DATE,
    PRECIO NUMBER(4,2),
    PAGADO CHAR(1) DEFAULT 'N' CONSTRAINT PRE_PAG_NN NOT NULL CONSTRAINT PRE_PAG_CK CHECK(UPPER(PAGADO)IN('S','N')),
    CONSTRAINT PRE_CDF_PK PRIMARY KEY(COD_COPIA,DNI_CLIENTE,FECHA_INICIO),
    CONSTRAINT PRE_FEF_CK CHECK (FECHA_FIN>=FECHA_INICIO)
);




