#!/bin/bash
set -euo pipefail

: "${POSTGRESQL_USERNAME:?Missing POSTGRESQL_USERNAME}"
: "${POSTGRESQL_PASSWORD:?Missing POSTGRESQL_PASSWORD}"
: "${POSTGRESQL_DATABASE:=optimal}"
: "${OPTIMAL_INGESTOR_PASSWORD:?Missing OPTIMAL_INGESTOR_PASSWORD}"
: "${OPTIMAL_BACKEND_PASSWORD:?Missing OPTIMAL_BACKEND_PASSWORD}"

export PGPASSWORD="${POSTGRESQL_PASSWORD}"

psql -U "${POSTGRESQL_USERNAME}" -d "${POSTGRESQL_DATABASE}" \
  -v ingestor_pw="${OPTIMAL_INGESTOR_PASSWORD}" \
  -v backend_pw="${OPTIMAL_BACKEND_PASSWORD}" <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'data_ingestor') THEN
    EXECUTE format('CREATE ROLE data_ingestor LOGIN PASSWORD %L', :'ingestor_pw');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'optimal_backend') THEN
    EXECUTE format('CREATE ROLE optimal_backend LOGIN PASSWORD %L', :'backend_pw');
  END IF;
END $$;
SQL
