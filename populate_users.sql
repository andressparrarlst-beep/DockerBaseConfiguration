-- ─────────────────────────────────────────────────────────────────────────────
-- Script para poblar la tabla USERS con 5 millones de registros
-- Uso: docker exec -i <nombre_contenedor_db> psql -U $POSTGRES_USER -d $POSTGRES_DB < populate_users.sql
--
-- Tiempo estimado: 3-8 minutos dependiendo del hardware
-- ─────────────────────────────────────────────────────────────────────────────

-- Crear la secuencia si no existe (Spring la crea con ddl-auto, pero por si acaso)
CREATE SEQUENCE IF NOT EXISTS user_seq START 1 INCREMENT 50;

-- Crear la tabla si no existe
CREATE TABLE IF NOT EXISTS "USERS" (
    id       BIGINT PRIMARY KEY DEFAULT nextval('user_seq'),
    name     VARCHAR(255),
    email    VARCHAR(255),
    password VARCHAR(255)
);

-- Desactivar logs WAL para inserción masiva (mucho más rápido)
SET synchronous_commit = OFF;

-- Insertar 5 millones de registros usando generate_series
-- Se insertan en bloques de 500k para no saturar la memoria
DO $$
DECLARE
    batch_size  INT := 500000;
    total       INT := 5000000;
    i           INT := 0;
BEGIN
    WHILE i < total LOOP
        INSERT INTO "USERS" (name, email, password)
        SELECT
            'User_' || (i + gs),
            'user' || (i + gs) || '@uptc.edu.co',
            md5(random()::text)   -- contraseña aleatoria hasheada
        FROM generate_series(1, batch_size) AS gs;

        i := i + batch_size;
        RAISE NOTICE 'Insertados % / % registros', i, total;
    END LOOP;
END;
$$;

-- Volver a modo normal
SET synchronous_commit = ON;

-- Actualizar estadísticas para que el query planner funcione bien
ANALYZE "USERS";

-- Verificar el resultado
SELECT COUNT(*) AS total_registros FROM "USERS";
