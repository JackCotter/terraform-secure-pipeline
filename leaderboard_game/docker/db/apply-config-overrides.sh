#!/bin/sh
# Runs once, automatically, after initdb creates the data directory —
# appends our overrides and swaps in the hardened pg_hba.conf.
set -e

cat /etc/postgresql/postgresql.conf.override >> "$PGDATA/postgresql.conf"
cp /etc/postgresql/pg_hba.conf "$PGDATA/pg_hba.conf"
