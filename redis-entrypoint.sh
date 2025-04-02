#!/bin/sh
set -e

echo "🔍 Configurando variables de entorno desde secretos..."

export REDIS_PASSWORD=$(cat /run/secrets/REDIS_PASSWORD)

# Ejecutar Redis con la contraseña
exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD"