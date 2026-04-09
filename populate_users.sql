-- Crear tabla (si ya existe, no pasa nada)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255),
    password VARCHAR(255)
);

-- Limpiar por si quedó algo roto
TRUNCATE TABLE users;

-- Inserción con ID explícito (CLAVE)
INSERT INTO users (id, name, email, password)
SELECT
    gs,
    'User_' || gs,
    'user' || gs || '@uptc.edu.co',
    md5(random()::text)
FROM generate_series(1, 5000000) AS gs;

ANALYZE users;

SELECT COUNT(*) FROM users;
