# Laboratorio de Monitoreo — Sistemas Distribuidos UPTC

## Arquitectura implementada

```
HOST
├── nginx (puerto 80 expuesto)       ← balanceador de carga
│   └── app x3 réplicas             ← Spring Boot :8080
│       └── db (PostgreSQL)         ← red interna backend
│
└── Monitoreo (red monitoring)
    ├── Prometheus :9090             ← recolecta métricas
    ├── Grafana :3000                ← dashboards
    ├── Alertmanager                 ← envía alertas a Telegram
    ├── cAdvisor                     ← métricas de contenedores
    ├── node_exporter                ← métricas del host
    └── postgres_exporter            ← métricas de PostgreSQL
```

---

## Paso 1 — Actualizar la app Spring Boot

### 1.1 Reemplazar `pom.xml`
Copia el `pom.xml` de este paquete al repo de la app. Agrega Actuator y Micrometer.

### 1.2 Reemplazar `application.properties`
Copia `application.properties` a `src/main/resources/`. 
⚠️ El cambio más importante: `ddl-auto=validate` (antes era `create-drop`).

### 1.3 Hacer commit y push
```bash
git add pom.xml src/main/resources/application.properties
git commit -m "feat: add Spring Actuator and Prometheus metrics"
git push origin main
```

---

## Paso 2 — Configurar Telegram

1. Abre Telegram → busca **@BotFather**
2. Escribe `/newbot` → sigue instrucciones → guarda el **BOT_TOKEN**
3. Busca **@userinfobot** → envíale cualquier mensaje → guarda el **CHAT_ID**
4. Edita `monitoring/alertmanager.yml`:
   - Reemplaza `TELEGRAM_BOT_TOKEN` con tu token
   - Reemplaza `TELEGRAM_CHAT_ID` con tu chat_id (número entero, sin comillas)

---

## Paso 3 — Variables de entorno

Crea o actualiza el archivo `.env` en la raíz del proyecto (junto al docker-compose.yml):

```env
# Base de datos
POSTGRES_DB=uptcdb
POSTGRES_USER=uptcuser
POSTGRES_PASSWORD=uptcpass123

# App Spring Boot
DB_URL=jdbc:postgresql://db:5432/uptcdb
DB_USER_NAME=uptcuser
DB_PASSWORD=uptcpass123

# Grafana
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin123
```

---

## Paso 4 — Levantar la infraestructura

```bash
# Construir y levantar todo
docker compose up -d --build

# Verificar que todos los contenedores están corriendo
docker compose ps

# Ver logs de la app
docker compose logs -f app

# Ver logs de prometheus
docker compose logs -f prometheus
```

---

## Paso 5 — Poblar la base de datos (5 millones de registros)

⚠️ **IMPORTANTE**: Hacer esto DESPUÉS de que los contenedores estén corriendo.
⚠️ El script asume que la tabla ya fue creada por Spring Boot al arrancar.

```bash
# Opción A: desde el archivo SQL (recomendada)
docker compose exec db psql -U uptcuser -d uptcdb < populate_users.sql

# Opción B: copiar el archivo al contenedor primero
docker compose cp populate_users.sql db:/tmp/populate_users.sql
docker compose exec db psql -U uptcuser -d uptcdb -f /tmp/populate_users.sql

# Verificar conteo
docker compose exec db psql -U uptcuser -d uptcdb -c 'SELECT COUNT(*) FROM "USERS";'
```

Tiempo estimado: **3-8 minutos**.

---

## Paso 6 — Acceder a los dashboards

| Servicio      | URL                        | Usuario  | Contraseña  |
|---------------|----------------------------|----------|-------------|
| App           | http://localhost/getAllUsers | —        | —           |
| Prometheus    | http://localhost:9090       | —        | —           |
| Grafana       | http://localhost:3000       | admin    | admin123    |
| Alertmanager  | http://localhost:9093       | —        | —           |

### Importar dashboards en Grafana

1. Ir a **Dashboards → Import**
2. Importar por ID:
   - **1860** → Node Exporter Full (métricas del host)
   - **893** → Docker and system monitoring (cAdvisor)
   - **9628** → PostgreSQL Database
   - **4701** → JVM Micrometer (Spring Boot)

---

## Paso 7 — Verificar alertas

Para probar que Telegram funciona, puedes disparar una alerta manualmente:

```bash
# Parar la BD para disparar la alerta PostgresDown
docker compose stop db

# Esperar ~1 minuto → deberías recibir mensaje en Telegram

# Volver a levantar
docker compose start db
```

---

## Estructura de archivos

```
DockerBaseConfiguration/
├── docker-compose.yml          ← REEMPLAZAR con el de este paquete
├── nginx.conf                  ← REEMPLAZAR con el de este paquete
├── Dockerfile                  ← sin cambios
├── .env                        ← crear/actualizar
├── populate_users.sql          ← script de poblado (nuevo)
└── monitoring/
    ├── prometheus.yml
    ├── alert.rules.yml
    ├── alertmanager.yml        ← editar con tokens de Telegram
    └── grafana/
        └── provisioning/
            └── datasources/
                └── prometheus.yml
```

---

## Puntos críticos de la infraestructura (análisis)

### Host
- **CPU saturada**: todas las réplicas y BD comparten el mismo host
- **Memoria agotada**: sin límites de memoria en los contenedores
- **Disco lleno**: la BD con 5M+ registros crece continuamente
- **Reinicio del host**: apaga toda la infraestructura simultáneamente

### Balanceador (nginx)
- **SPOF (Single Point of Failure)**: es el único punto de entrada
- **Sin SSL/TLS**: tráfico HTTP plano
- **Sin rate limiting**: vulnerable a ataques de denegación de servicio

### Aplicación
- **`ddl-auto=create-drop`** (original): borraba datos al reiniciar ← **CORREGIDO**
- **Sin límites de memoria JVM**: puede causar OOM del contenedor
- **Sin autenticación en /actuator**: métricas expuestas sin protección

### Base de datos
- **Sin réplica**: único contenedor de BD es SPOF
- **Sin backup automático**: pérdida total de datos si el volumen se corrompe
- **Puerto no expuesto** ← correcto, solo accesible por red interna

### Contenedores
- **Sin resource limits**: un contenedor puede consumir todos los recursos del host
- **Sin health checks en app/nginx**: Docker no sabe si realmente responden
