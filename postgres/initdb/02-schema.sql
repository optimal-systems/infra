\connect optimal

-- 1) Roles/grupos NOLOGIN (owner, rw, ro)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'optimal_owner') THEN
    CREATE ROLE optimal_owner NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'optimal_rw') THEN
    CREATE ROLE optimal_rw NOLOGIN;  -- lectura/escritura
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'optimal_ro') THEN
    CREATE ROLE optimal_ro NOLOGIN;  -- solo lectura
  END IF;
END $$;

-- 2) Membresías (principio de mínimo privilegio)
GRANT optimal_rw TO data_ingestor;
GRANT optimal_rw TO optimal_backend;
-- Si quieres backend solo lectura:
-- REVOKE optimal_rw FROM optimal_backend; GRANT optimal_ro TO optimal_backend;

-- 3) Seguridad a nivel BD
REVOKE CONNECT ON DATABASE optimal FROM PUBLIC;
GRANT  CONNECT ON DATABASE optimal TO optimal_rw, optimal_ro;

-- 4) Bloquear 'public' para evitar fugas de permisos
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- 5) Esquema dedicado 'optimal' con owner claro
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'optimal') THEN
    EXECUTE 'CREATE SCHEMA optimal AUTHORIZATION optimal_owner';
  END IF;
END $$;

-- 6) Permisos de esquema
GRANT USAGE ON SCHEMA optimal TO optimal_ro, optimal_rw;
GRANT CREATE ON SCHEMA optimal TO optimal_owner, optimal_rw;

-- 7) search_path para usuarios de app (solo en esta BD)
ALTER ROLE data_ingestor   IN DATABASE optimal SET search_path = optimal, public;
ALTER ROLE optimal_backend IN DATABASE optimal SET search_path = optimal, public;

-- 8) Permisos sobre OBJETOS EXISTENTES (por si ya hay tablas/secuencias/funciones)
GRANT SELECT ON ALL TABLES IN SCHEMA optimal TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA optimal TO optimal_rw;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA optimal TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA optimal TO optimal_rw;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA optimal TO optimal_ro, optimal_rw;

-- 9) (Opcional) Defaults para objetos creados por 'optimal_owner'
ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA optimal
  GRANT SELECT ON TABLES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA optimal
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA optimal
  GRANT USAGE, SELECT ON SEQUENCES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA optimal
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA optimal
  GRANT EXECUTE ON FUNCTIONS TO optimal_ro, optimal_rw;

-- (Opcional) Extensiones dentro del esquema 'optimal'
-- CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA optimal;
