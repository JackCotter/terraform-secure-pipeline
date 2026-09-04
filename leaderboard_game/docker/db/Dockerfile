FROM postgres:16-alpine

# Custom auth rules (scram-sha-256 only, no trust) and logging/connection
# limits, layered on top of the official image's sane defaults.
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
COPY postgresql.conf /etc/postgresql/postgresql.conf.override

# The official entrypoint sources any *.conf dropped into
# /docker-entrypoint-initdb.d only for init SQL — config overrides need to be
# appended to the real postgresql.conf after initdb creates it. We do this
# via a small init script instead of a static COPY to /var/lib/postgresql/data,
# since that directory is created fresh by the entrypoint at first run.
COPY apply-config-overrides.sh /docker-entrypoint-initdb.d/apply-config-overrides.sh
RUN chmod +x /docker-entrypoint-initdb.d/apply-config-overrides.sh

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
    CMD pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" || exit 1
