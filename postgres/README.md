# PostgreSQL - Arquitectura de Tres Capas para Optimal

Este directorio contiene la configuración de PostgreSQL para el proyecto Optimal, implementando una arquitectura de tres capas para el manejo de datos.

Imagen basada en [bitnami/postgresql:17.6.0](https://hub.docker.com/r/bitnami/postgresql)

## 🏗️ Arquitectura de Datos

### **Schema `raw`**
- **Propósito**: Almacenar datos crudos extraídos de APIs y fuentes externas
- **Características**: 
  - Columnas de tipo `TEXT` para máxima flexibilidad
  - Nomenclatura: `raw.supermarket_YYYYMMDD`
  - Solo `data_ingestor` puede escribir
  - `optimal_backend` solo puede leer (para auditoría)

### **Schema `staging`**
- **Propósito**: Consolidar y transformar datos con tipos bien definidos
- **Características**:
  - Tabla particionada por fecha (`extracted_date`)
  - Tipos de datos optimizados (`VARCHAR`, `DECIMAL`, `JSONB`)
  - `data_ingestor` escribe, `optimal_backend` lee
  - Ideal para análisis y transformaciones

### **Schema `prod`**
- **Propósito**: Datos finales optimizados para consumo de APIs
- **Características**:
  - Estructura normalizada con restricciones
  - Índices optimizados para consultas de API
  - Ambos roles pueden leer y escribir
  - Campo `is_active` para soft deletes

### **Schema `optimal`**
- **Propósito**: Aplicación principal y configuración del sistema
- **Características**:
  - Configuración de roles y permisos
  - Tablas del sistema de la aplicación

## 🔐 Modelo de Seguridad

### **Roles del Sistema**
- `optimal_owner`: Propietario de todos los schemas
- `optimal_rw`: Acceso de lectura/escritura
- `optimal_ro`: Acceso de solo lectura
- `data_ingestor`: Usuario para ingesta de datos
- `optimal_backend`: Usuario para la aplicación backend

### **Matriz de Permisos**
| Schema | data_ingestor | optimal_backend |
|--------|---------------|-----------------|
| `raw`  | RW            | R               |
| `staging` | RW        | R               |
| `prod` | RW            | RW              |
| `optimal` | RW         | RW              |

## 🚀 Despliegue Rápido

Build:
```bash
docker build -t optimal-postgres:17.6.0 .
```
Example usage (docker run):
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

## 📁 Estructura de Archivos

```
infra/postgres/
├── Dockerfile                 # Imagen de PostgreSQL
├── init-db.sh                 # Script de inicialización
├── README.md                  # Esta documentación
└── initdb/                    # Scripts de inicialización
    ├── 01-users.sh           # Creación de usuarios y roles
    ├── 02-schema.sql         # Configuración de schemas y permisos
    └── 03-defaults-app-creators.sql  # Privilegios por defecto
```

## 📚 Recursos Adicionales

- [Documentación oficial de PostgreSQL](https://www.postgresql.org/docs/)
- [Docker Compose](https://docs.docker.com/compose/)
- [PostgreSQL Schemas](https://www.postgresql.org/docs/current/ddl-schemas.html)
- [PostgreSQL Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html)
