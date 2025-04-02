#!/bin/sh

set +e  # Deshabilitar "exit on error" para evitar fallos si un secreto falta

echo "🔍 Configurando variables de entorno desde secretos..."

prefix="secrets_stack_"

# Cargar secretos si existen
echo "Cargando secretos..."
for secret in APP_NAME PORT HOST BETTER_AUTH_SECRET BETTER_AUTH_URL BASE_URL_FRONTEND \
               DATABASE_URL GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET FACEBOOK_CLIENT_ID \
               FACEBOOK_CLIENT_SECRET GITHUB_CLIENT_ID GITHUB_CLIENT_SECRET RESEND_API_KEY \
               REDIS_HOST REDIS_PORT REDIS_PASSWORD; do
    secret_path="/run/secrets/$secret"
    
    echo "🔎 Buscando secreto en: $secret_path"
    
    if [ -f "$secret_path" ]; then
        export "$secret"="$(cat "$secret_path")"
        echo "✅ Secreto $secret cargado correctamente."
    else
        echo "⚠️ Advertencia: El secreto $secret no está disponible."
    fi
done

set -e  # Habilitar "exit on error" nuevamente

# Ejecutar el comando original del contenedor con la configuración de entorno
exec dumb-init node dist/index.mjs