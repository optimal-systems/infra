# Optimal Postgres 🐘

Imagen basada en [bitnami/postgresql:17.6.0](https://hub.docker.com/r/bitnami/postgresql):

- **Base de datos** `optimal`
- **Esquema dedicado** `optimal` (no usa `public`)
- **Roles de grupo** (`optimal_owner`, `optimal_rw`, `optimal_ro`)
- **Usuarios de aplicación** (`data_ingestor`, `optimal_backend`)
- **Permisos y privilegios por defecto** (principio de mínimo privilegio)

---

## Build
```bash
docker build -t optimal-postgres:17.6.0 ./postgres
```
---

## Environment variables

| Variable                    | Description                                                                  | Example value        |
|----------------------------|------------------------------------------------------------------------------|----------------------|
| `POSTGRESQL_USERNAME`      | Usuario administrador inicial (superuser creado por Bitnami).                | `postgres`           |
| `POSTGRESQL_PASSWORD`      | Contraseña del superuser inicial.                                            | `supersecret`        |
| `POSTGRESQL_DATABASE`      | Nombre de la base de datos que se creará en el primer arranque.              | `optimal`            |
| `OPTIMAL_INGESTOR_PASSWORD`| Contraseña para el usuario `data_ingestor` (miembro de `optimal_rw`).        | `di_supersecret`     |
| `OPTIMAL_BACKEND_PASSWORD` | Contraseña para el usuario `optimal_backend` (miembro de `optimal_rw`).      | `backend_supersecret`|

---

## Example usage (docker run)

```bash
docker run -d --name optimal-db \
  -e POSTGRESQL_USERNAME=postgres \
  -e POSTGRESQL_PASSWORD=supersecret \
  -e POSTGRESQL_DATABASE=optimal \
  -e OPTIMAL_INGESTOR_PASSWORD=di_supersecret \
  -e OPTIMAL_BACKEND_PASSWORD=backend_supersecret \
  -p 5432:5432 \
  -v optimal_pg_data:/bitnami/postgresql \
  optimal-postgres:17.6.0
```
---

## Example usage (docker-compose)
```yaml
services:
  db:
    image: optimal-postgres:17.6.0
    container_name: optimal-db
    restart: unless-stopped
    environment:
      POSTGRESQL_USERNAME: postgres
      POSTGRESQL_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRESQL_DATABASE: optimal
      OPTIMAL_INGESTOR_PASSWORD: ${OPTIMAL_INGESTOR_PASSWORD}
      OPTIMAL_BACKEND_PASSWORD: ${OPTIMAL_BACKEND_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - optimal_pg_data:/bitnami/postgresql

volumes:
  optimal_pg_data:
```

**.env**
```yaml
POSTGRES_PASSWORD=supersecret
OPTIMAL_INGESTOR_PASSWORD=di_supersecret
OPTIMAL_BACKEND_PASSWORD=backend_supersecret
```

---

## Repository layout
```bash
postgres/
├─ Dockerfile
└─ initdb/
    ├─ 01-users.sh                  # crea usuarios LOGIN con contraseñas de env
    ├─ 02-schema.sql                # roles NOLOGIN, esquema, grants base
    └─ 03-defaults-app-creators.sql # default privileges para objetos creados por los usuarios de app
```

> **Orden de ejecución:** los archivos en `/docker-entrypoint-initdb.d/` se ejecutan por **orden lexicográfico** en el primer arranque (datadir vacío). Mantén los prefijos `01-`, `02-`, `03-`.  
> **Permisos:** recuerda hacer ejecutable el script:  
> `chmod +x postgres/initdb/01-users.sh`

---

## Roles y permisos

- **optimal_owner** → dueño del esquema `optimal`, crea/alter y define *default privileges*.
- **optimal_rw** → lectura/escritura en tablas, uso/actualización de secuencias, `EXECUTE` en funciones.
- **optimal_ro** → solo lectura en tablas, `USAGE/SELECT` en secuencias, `EXECUTE` en funciones.
- **data_ingestor** → miembro de `optimal_rw`.
- **optimal_backend** → miembro de `optimal_rw` (pásalo a `optimal_ro` si necesitas solo lectura).

---

## Default privileges (muy importante)

El archivo `03-defaults-app-creators.sql` asegura que **los objetos nuevos** creados por `data_ingestor` y `optimal_backend` hereden permisos adecuados en el esquema `optimal`:

- `optimal_ro` → `SELECT` en tablas y `USAGE/SELECT` en secuencias.
- `optimal_rw` → `SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER` en tablas y `USAGE/SELECT/UPDATE` en secuencias.
- Ambos → `EXECUTE` en funciones.

Para **objetos ya existentes** antes de aplicar defaults, sincroniza permisos con:
```sql
\connect optimal
GRANT SELECT ON ALL TABLES IN SCHEMA optimal TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA optimal TO optimal_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA optimal TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA optimal TO optimal_rw;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA optimal TO optimal_ro, optimal_rw;
```
---

## Verificación rápida (vía `docker exec` + `psql`)

**1) Abrir sesión `psql` como superusuario dentro del contenedor**
```bash
docker exec -it optimal-db psql -U postgres -d optimal
```

**2) Checks básicos dentro de `psql`**
```sql
-- Contexto de sesión
SELECT current_user, current_database(), current_schema();

-- Roles y membresías
\du+

-- Esquemas y ACLs básicas
\dn+

-- Default privileges definidos
\ddp+
```

**3) Prueba end-to-end usando `SET ROLE` (sin credenciales de otros usuarios)**
```sql
-- Simular al usuario de ingesta
SET ROLE data_ingestor;
SELECT 'as data_ingestor' AS whoami, current_user, current_schema;
CREATE TABLE IF NOT EXISTS optimal.smoketest_permissions(
  id serial PRIMARY KEY,
  who text NOT NULL,
  ts  timestamptz NOT NULL DEFAULT now()
);
INSERT INTO optimal.smoketest_permissions(who) VALUES (current_user);
RESET ROLE;

-- Simular al backend (lectura/escritura por defecto)
SET ROLE optimal_backend;
SELECT 'as optimal_backend' AS whoami, current_user, current_schema;
TABLE optimal.smoketest_permissions;           -- leer
INSERT INTO optimal.smoketest_permissions(who) -- escribir (fallará si backend es solo lectura)
VALUES (current_user);
RESET ROLE;

-- Verificar como superusuario
TABLE optimal.smoketest_permissions;

-- Limpieza (opcional)
DROP TABLE IF EXISTS optimal.smoketest_permissions;
```

> Si cambio `optimal_backend` a **solo lectura** (`optimal_ro`), el `INSERT` fallará con `ERROR: permission denied`, lo cual es esperado.

---

## Healthcheck (opcional)

Añade al `Dockerfile`:
```Dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD \
  pg_isready -U ${POSTGRESQL_USERNAME:-postgres} -d ${POSTGRESQL_DATABASE:-optimal} -h localhost || exit 1
```
---

## Notas

- Los scripts de `initdb/` solo se ejecutan en el **primer arranque** con volumen de datos vacío.
- **No** “hardcodeamos” secretos en la imagen. Se pasan por variables de entorno o secrets de tu orquestador.
- Si cambias membresías (p.ej. `optimal_backend` → `optimal_ro`), ajusta grants/defaults según tu política.
