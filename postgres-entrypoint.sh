#!/bin/sh
set -e

export POSTGRES_USER=$(cat /run/secrets/POSTGRES_USER)
export POSTGRES_PASSWORD=$(cat /run/secrets/POSTGRES_PASSWORD)
export POSTGRES_DB=$(cat /run/secrets/POSTGRES_DB)
