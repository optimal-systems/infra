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

-- 5) Esquemas dedicados con owner claro
DO $$
BEGIN
  -- Schema optimal para aplicación principal
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'optimal') THEN
    EXECUTE 'CREATE SCHEMA optimal AUTHORIZATION optimal_owner';
  END IF;
  
  -- Schema raw para datos crudos extraídos
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'raw') THEN
    EXECUTE 'CREATE SCHEMA raw AUTHORIZATION optimal_owner';
  END IF;
  
  -- Schema staging para datos consolidados y transformados
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'staging') THEN
    EXECUTE 'CREATE SCHEMA staging AUTHORIZATION optimal_owner';
  END IF;
  
  -- Schema prod para datos finales de producción
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'prod') THEN
    EXECUTE 'CREATE SCHEMA prod AUTHORIZATION optimal_owner';
  END IF;
END $$;

-- 6) Permisos de esquema
GRANT USAGE ON SCHEMA optimal TO optimal_ro, optimal_rw;
GRANT CREATE ON SCHEMA optimal TO optimal_owner, optimal_rw;

GRANT USAGE ON SCHEMA raw TO optimal_ro, optimal_rw;
GRANT CREATE ON SCHEMA raw TO optimal_owner, optimal_rw;

GRANT USAGE ON SCHEMA staging TO optimal_ro, optimal_rw;
GRANT CREATE ON SCHEMA staging TO optimal_owner, optimal_rw;

GRANT USAGE ON SCHEMA prod TO optimal_ro, optimal_rw;
GRANT CREATE ON SCHEMA prod TO optimal_owner, optimal_rw;

-- 7) search_path para usuarios de app (incluyendo los nuevos schemas)
-- data_ingestor: Acceso completo a raw, staging, prod + optimal
ALTER ROLE data_ingestor IN DATABASE optimal SET search_path = raw, staging, prod, optimal, public;

-- optimal_backend: Acceso a prod (escritura), optimal (escritura), raw y staging solo lectura
ALTER ROLE optimal_backend IN DATABASE optimal SET search_path = prod, optimal, staging, raw, public;

-- 8) Permisos sobre OBJETOS EXISTENTES (por si ya hay tablas/secuencias/funciones)
-- Schema optimal
GRANT SELECT ON ALL TABLES IN SCHEMA optimal TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA optimal TO optimal_rw;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA optimal TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA optimal TO optimal_rw;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA optimal TO optimal_ro, optimal_rw;

-- Schema raw (data_ingestor RW, optimal_backend RO)
GRANT SELECT ON ALL TABLES IN SCHEMA raw TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA raw TO optimal_rw;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA raw TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA raw TO optimal_rw;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA raw TO optimal_ro, optimal_rw;

-- Schema staging (data_ingestor RW, optimal_backend RO)
GRANT SELECT ON ALL TABLES IN SCHEMA staging TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA staging TO optimal_rw;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA staging TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA staging TO optimal_rw;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA staging TO optimal_ro, optimal_rw;

-- Schema prod (ambos roles RW)
GRANT SELECT ON ALL TABLES IN SCHEMA prod TO optimal_ro;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON ALL TABLES IN SCHEMA prod TO optimal_rw;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA prod TO optimal_ro;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA prod TO optimal_rw;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA prod TO optimal_ro, optimal_rw;

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

-- Defaults para schema raw
ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA raw
  GRANT SELECT ON TABLES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA raw
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA raw
  GRANT USAGE, SELECT ON SEQUENCES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA raw
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA raw
  GRANT EXECUTE ON FUNCTIONS TO optimal_ro, optimal_rw;

-- Defaults para schema staging
ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA staging
  GRANT SELECT ON TABLES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA staging
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA staging
  GRANT USAGE, SELECT ON SEQUENCES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA staging
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA staging
  GRANT EXECUTE ON FUNCTIONS TO optimal_ro, optimal_rw;

-- Defaults para schema prod
ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA prod
  GRANT SELECT ON TABLES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA prod
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA prod
  GRANT USAGE, SELECT ON SEQUENCES TO optimal_ro;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA prod
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO optimal_rw;

ALTER DEFAULT PRIVILEGES FOR ROLE optimal_owner IN SCHEMA prod
  GRANT EXECUTE ON FUNCTIONS TO optimal_ro, optimal_rw;
