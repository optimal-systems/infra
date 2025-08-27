FROM bitnami/postgresql:17.6.0

COPY --chmod=+x initdb/ /docker-entrypoint-initdb.d/

ENV POSTGRESQL_DATABASE=optimal

# Healthcheck de cortesía (marca el contenedor como healthy si responde)
HEALTHCHECK --interval=30s --timeout=10s --retries=5 CMD \
  pg_isready -U ${POSTGRESQL_USERNAME:-postgres} -d ${POSTGRESQL_DATABASE:-optimal} -h localhost || exit 1
