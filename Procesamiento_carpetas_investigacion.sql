-- SHP de códigos postales de CDMX: https://datos.cdmx.gob.mx/dataset/codigos-postales

/* ======================                 FUNCIONES                 ======================             */

-- Validar fechas --
CREATE OR REPLACE FUNCTION
    valida_fecha(fecha_str VARCHAR) RETURNS DATE
    AS
    $$
    DECLARE
        dia VARCHAR;
        mes VARCHAR;
        anio VARCHAR;
        formato_fecha VARCHAR := 'YYYY-MM-DD';
    BEGIN
        IF fecha_str~'^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$' THEN -- formato YYYY-MM-DD
            RETURN TO_DATE(fecha_str, formato_fecha);

        ELSIF fecha_str~'^(0?[1-9]|[12][0-9]|3[01])\-(0?[1-9]|1[012])\-\d{4}$' THEN -- formato DD-MM-YYYY
            SELECT INTO dia SUBSTRING(fecha_str FROM 1 FOR 2);
            SELECT INTO mes SUBSTRING(fecha_str FROM 4 FOR 2);
            SELECT INTO anio SUBSTRING(fecha_str FROM 7 FOR 4);

            RETURN TO_DATE(anio || '-' || mes || '-' || dia, formato_fecha);

        ELSIF fecha_str~'^\d{4}\/(0?[1-9]|1[012])\/(0?[1-9]|[12][0-9]|3[01])$' THEN --formato YYYY/MM/DD
            SELECT INTO anio SUBSTRING(fecha_str FROM 1 FOR 4);
            SELECT INTO mes SUBSTRING(fecha_str FROM 6 FOR 2);
            SELECT INTO dia SUBSTRING(fecha_str FROM 9 FOR 2);

            RETURN TO_DATE(anio || '-' || mes || '-' || dia, formato_fecha);

        ELSIF fecha_str~'^(0?[1-9]|[12][0-9]|3[01])\/(0?[1-9]|1[012])\/\d{4}$' THEN -- formato DD/MM/YYYY
            SELECT INTO dia SUBSTRING(fecha_str FROM 1 FOR 2);
            SELECT INTO mes SUBSTRING(fecha_str FROM 4 FOR 2);
            SELECT INTO anio SUBSTRING(fecha_str FROM 7 FOR 4);

            RETURN TO_DATE(anio || '-' || mes || '-' || dia, formato_fecha);

        ELSE
                RETURN TO_DATE(TO_CHAR(to_timestamp(0),'YYYY/MM/DD'), formato_fecha);

        END IF;
    END
    $$ LANGUAGE plpgsql;

-- validar horas

-- Crear carpeta de respaldo que contenga la información de carpetas_investigacion_cdmx
/*DROP TABLE IF EXISTS carpetas_investigacion_cdmx_respaldo;
CREATE TABLE carpetas_investigacion_cdmx_respaldo AS
    SELECT * FROM carpetas_investigacion_cdmx;*/

/* ======================          CREACIÓN DE TABLAS NECESARIAS     ======================             */

-- Crear tabla principal a partir de un respaldo
DROP TABLE IF EXISTS carpetas_investigacion_cdmx;
CREATE TABLE carpetas_investigacion_cdmx AS
    SELECT * FROM carpetas_investigacion_cdmx_con_codigos_postales;


/* ======================         RENOMBRAR COLUMNAS     ======================             */

ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN categoria_ TO categoria_delito;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN competenci TO competencia;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN unidad_inv TO unidad_investigacion;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN colonia_he TO colonia_hecho;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN colonia_ca TO colonia_catalogo;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN alcaldia_h TO alcaldia_hecho;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN alcaldia_c TO alcaldia_catalogo;
ALTER TABLE carpetas_investigacion_cdmx RENAME COLUMN municipio_ TO municipio_hecho;


/* ==================== ELIMINAR ACENTOS DE LAS COLUMNAS ======================             */

-- IMPORTANTE: es necesario instalar en la BDD la extensión de Postgres 'unaccent'

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    delito = unaccent(delito) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    categoria_delito = unaccent(categoria_delito) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    competencia = unaccent(competencia) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    unidad_investigacion = unaccent(unidad_investigacion) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    colonia_hecho = unaccent(colonia_hecho) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    colonia_catalogo = unaccent(colonia_catalogo) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    alcaldia_hecho = unaccent(alcaldia_hecho) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    alcaldia_catalogo = unaccent(alcaldia_catalogo) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    municipio_hecho = unaccent(municipio_hecho) WHERE TRUE;

/* ======================            COLUMNAS DE 'inicio'            ======================             */

-- Añadir columna 'fecha_inicio' a partir de la columna 'fecha_inic'. Convirtiendo datos de tipo varchar a date
    -- Nota: en PostgreSQL el operador '<>' es equivalente a '!='

ALTER TABLE carpetas_investigacion_cdmx ADD COLUMN fecha_inicio DATE;
UPDATE carpetas_investigacion_cdmx t SET fecha_inicio = valida_fecha(t.fecha_inic) WHERE TRUE;

ALTER TABLE carpetas_investigacion_cdmx ADD COLUMN  hora_inicio TIME;
UPDATE carpetas_investigacion_cdmx SET hora_inicio = to_timestamp(hora_inici,'HH24:MI:SS') WHERE hora_inici <> 'NA';

-- Combinar ambas columnas en una sola
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS fecha_y_hora_inicio,
    ADD COLUMN  fecha_y_hora_inicio TIMESTAMP;

UPDATE carpetas_investigacion_cdmx SET
    fecha_y_hora_inicio = (fecha_inicio+hora_inicio)::TIMESTAMP AT TIME ZONE 'America/Mexico_City' WHERE fecha_inicio IS NOT NULL OR hora_inicio IS NOT NULL;

/* ======================            COLUMNAS DE 'hecho'            ======================             */

-- Añadir columna 'fecha_hecho' a partir de la columna 'fecha_hech'. Convirtiendo datos de tipo varchar a date
    -- Nota: en PostgreSQL el operador '<>' es equivalente a '!='
ALTER TABLE carpetas_investigacion_cdmx ADD COLUMN fecha_hecho DATE;
 UPDATE carpetas_investigacion_cdmx t SET fecha_hecho = valida_fecha(t.fecha_hech) WHERE TRUE;

ALTER TABLE carpetas_investigacion_cdmx ADD COLUMN hora_hechos TIME;
UPDATE carpetas_investigacion_cdmx SET hora_hechos = to_timestamp(hora_hecho,'HH24:MI:SS') WHERE hora_hecho <> 'NA';

-- Combinar ambas columnas en una sola
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS fecha_y_hora_hecho,
    ADD COLUMN  fecha_y_hora_hecho TIMESTAMP;

UPDATE carpetas_investigacion_cdmx SET
    fecha_y_hora_hecho = (fecha_hecho+hora_hechos)::TIMESTAMP AT TIME ZONE 'America/Mexico_City' WHERE fecha_inicio IS NOT NULL OR hora_inicio IS NOT NULL;

/* ======================           CREACIÓN DE CATÁLOGOS           ======================             */

--                                 ** Categoría de delitos **

-- Eliminar acentos de la columna
UPDATE carpetas_investigacion_cdmx SET
    categoria_delito = unaccent(categoria_delito);

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_categoria_delito CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_categoria_delito(
    id SERIAL PRIMARY KEY ,
    categoria_delito varchar(254)
);

-- Insertar las categorías de delito seleccionándolos de la tabla principal
INSERT INTO catalogo_categoria_delito (categoria_delito)
    SELECT DISTINCT categoria_delito FROM carpetas_investigacion_cdmx;

-- Crear columna 'categoria_delito' como referencia a llave foráneo en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_categoria_delito,
    ADD COLUMN id_categoria_delito INT
    REFERENCES catalogo_categoria_delito;

-- Actualizar los valores de la columna 'categoria_delito' utilizando la tabla de catalogo y la columna
-- 'categoria_' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_categoria_delito = b.id
        FROM catalogo_categoria_delito AS b
        WHERE a.categoria_delito = b.categoria_delito;


--                                     ** Delitos **

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_delito CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_delito(
    id SERIAL PRIMARY KEY ,
    delito varchar(254)
);

-- Insertar las categorías de delito seleccionándolos de la tabla principal
INSERT INTO catalogo_delito (delito)
    SELECT DISTINCT delito FROM carpetas_investigacion_cdmx;

-- Crear columna 'delito' como referencia a llave foránea en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_delito,
    ADD COLUMN id_delito INT
    REFERENCES catalogo_delito;

-- Actualizar los valores de la columna 'categoria_delito' utilizando la tabla de catalogo y la columna
-- 'categoria_' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_delito = b.id
        FROM catalogo_delito AS b
        WHERE a.delito = b.delito;

--                                     ** Competencia **

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_competencia CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_competencia(
    id SERIAL PRIMARY KEY ,
    competencia varchar(254)
);

-- Insertar las categorías de competencia seleccionándolas de la tabla principal
INSERT INTO catalogo_competencia (competencia)
    SELECT DISTINCT competencia FROM carpetas_investigacion_cdmx;

-- Crear columna 'competencia' como referencia a llave foráneo en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_competencia,
    ADD COLUMN id_competencia INT
    REFERENCES catalogo_competencia;

-- Actualizar los valores de la columna 'competencia' utilizando la tabla de catalogo y la columna
-- 'competencia' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_competencia = b.id
        FROM catalogo_competencia AS b
        WHERE a.competencia = b.competencia;

--                                     ** Fiscalía **

--Limpiar datos de columna 'fiscalia' (eliminar caracteres 'enter' en las filas, character ASCII código. 13)
UPDATE carpetas_investigacion_cdmx
    SET fiscalia = replace(fiscalia, chr(13),'');

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_fiscalia CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_fiscalia(
    id SERIAL PRIMARY KEY ,
    fiscalia varchar(254)
);

-- Insertar las categorías de competencia seleccionándolas de la tabla principal
INSERT INTO catalogo_fiscalia (fiscalia)
    SELECT DISTINCT fiscalia FROM carpetas_investigacion_cdmx;

-- Crear columna 'id_fiscalia' como referencia a llave foránea en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_fiscalia,
    ADD COLUMN id_fiscalia INT
    REFERENCES catalogo_fiscalia;

-- Actualizar los valores de la columna 'competencia' utilizando la tabla de catalogo y la columna
-- 'fiscalia' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_fiscalia = b.id
        FROM catalogo_fiscalia AS b
        WHERE a.fiscalia = b.fiscalia;


--                                     ** Agencia **

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_agencia CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_agencia(
    id SERIAL PRIMARY KEY ,
    agencia varchar(254)
);

-- Insertar las categorías de competencia seleccionándolas de la tabla principal
INSERT INTO catalogo_agencia (agencia)
    SELECT DISTINCT agencia FROM carpetas_investigacion_cdmx;

-- Crear columna 'id_agencia' como referencia a llave foránea en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_agencia,
    ADD COLUMN id_agencia INT
    REFERENCES catalogo_agencia;

-- Actualizar los valores de la columna 'id_agencia' utilizando la tabla de catalogo y la columna
-- 'agencia' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_agencia = b.id
        FROM catalogo_agencia AS b
        WHERE a.agencia = b.agencia;


--                                     ** Unidad de investigación **

UPDATE carpetas_investigacion_cdmx
    SET unidad_investigacion = replace(unidad_investigacion, chr(160),'');

--Crear tabla que contiene el catálogo
DROP TABLE IF EXISTS  catalogo_unidad_investigacion CASCADE; -- CASCADE: elimina llaves foráneas dependientes de esta tabla
CREATE TABLE catalogo_unidad_investigacion(
    id SERIAL PRIMARY KEY ,
    unidad_investigacion varchar(254)
);

-- Insertar las categorías de competencia seleccionándolas de la tabla principal
INSERT INTO catalogo_unidad_investigacion (unidad_investigacion)
    SELECT DISTINCT unidad_investigacion FROM carpetas_investigacion_cdmx;

-- Crear columna 'id_unidad_investigacion' como referencia a llave foránea en la tabla principal
ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS id_unidad_investigacion,
    ADD COLUMN id_unidad_investigacion INT
    REFERENCES catalogo_unidad_investigacion;

-- Actualizar los valores de la columna 'id_unidad_investigacion' utilizando la tabla de catalogo y la columna
-- 'unidad_investigacion' de la tabla principal

UPDATE carpetas_investigacion_cdmx AS a
        SET id_unidad_investigacion = b.id
        FROM catalogo_unidad_investigacion AS b
        WHERE a.unidad_investigacion = b.unidad_investigacion;

/* ======================

    PROCESAMIENTO TABLA CATÁLOGO DE CÓDIGOS POSTALES


   ======================             */

DROP TABLE IF EXISTS  catalogo_codigo_postal_cdmx;
CREATE TABLE catalogo_codigo_postal_cdmx(
    codigo_postal_asentamiento VARCHAR(5) PRIMARY KEY,
    nombre_asentamiento VARCHAR(254),
    tipo_asentamiento VARCHAR(25),
    nombre_municipio VARCHAR(254),
    nombre_entidad VARCHAR (254),
    nombre_ciudad VARCHAR (254),
    codigo_postal_administracion_postal VARCHAR(5),
    clave_entidad VARCHAR(1),
    clave_tipo_asentamiento INT,
    clave_municipio INT,
    id_asentamiento INT,
    zona_asentamiento VARCHAR(10),
    clave_ciudad INT
);

-- Usar Import/Export de DataGrip para importar el archivo CSV en la tabla de códigos postales
-- https://www.correosdemexico.gob.mx/SSLServicios/ConsultaCP/CodigoPostal_Exportar.aspx

-- Eliminar columnas redundantes
ALTER TABLE catalogo_codigo_postal_cdmx
    DROP COLUMN IF EXISTS nombre_entidad,
    DROP COLUMN IF EXISTS nombre_ciudad,
    DROP COLUMN IF EXISTS clave_entidad;

/* ==================== ELIMINAR ACENTOS DE LAS COLUMNAS ======================             */

-- IMPORTANTE: es necesario instalar en la BDD la extensión de Postgres 'unaccent'

-- Eliminar acentos de la columna
UPDATE catalogo_codigo_postal_cdmx SET
    codigo_postal_asentamiento = unaccent(codigo_postal_asentamiento) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE catalogo_codigo_postal_cdmx SET
    nombre_asentamiento = unaccent(nombre_asentamiento) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE catalogo_codigo_postal_cdmx SET
    tipo_asentamiento = unaccent(tipo_asentamiento) WHERE TRUE;

-- Eliminar acentos de la columna
UPDATE catalogo_codigo_postal_cdmx SET
    nombre_municipio = unaccent(nombre_municipio) WHERE TRUE;



/* ======================           CÓDIGOS POSTALES          ======================             */

ALTER TABLE carpetas_investigacion_cdmx
    DROP COLUMN IF EXISTS codigo_postal_colonia_hecho,
    ADD COLUMN codigo_postal_colonia_hecho VARCHAR(5) REFERENCES catalogo_codigo_postal_cdmx;

UPDATE carpetas_investigacion_cdmx a SET codigo_postal_colonia_hecho = codigo_postal_asentamiento FROM
    catalogo_codigo_postal_cdmx b WHERE (a.d_cp = b.codigo_postal_asentamiento) OR
    (
        a.colonia_catalogo = b.nombre_asentamiento AND a.alcaldia_catalogo = b.nombre_municipio
    );

ALTER TABLE carpetas_investigacion_cdmx
DROP COLUMN IF EXISTS anio_inici,
DROP COLUMN IF EXISTS mes_inicio,
DROP COLUMN IF EXISTS fecha_inic,
DROP COLUMN IF EXISTS hora_inici,
DROP COLUMN IF EXISTS anio_hecho,
DROP COLUMN IF EXISTS mes_hecho,
DROP COLUMN IF EXISTS fecha_hech,
DROP COLUMN IF EXISTS hora_hecho,
DROP COLUMN IF EXISTS fecha_inicio,
DROP COLUMN IF EXISTS fecha_hecho,
DROP COLUMN IF EXISTS d_cp,
DROP COLUMN IF EXISTS hora_hechos;
