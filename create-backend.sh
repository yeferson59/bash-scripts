#!/bin/bash

set -e  # Detiene la ejecución si ocurre un error

echo "🔄 Entrando en la carpeta 'backend'..."
if [ -d "./backend" ]; then
  cd ./backend || { echo "❌ Error: No se pudo acceder al directorio 'backend'"; exit 1; }
else
  echo "❌ Error: El directorio 'backend' no existe."
  exit 1
fi

if ! command -v pnpm &> /dev/null; then
  sudo curl -fsSL https://get.pnpm.io/install.sh | sh -
  export PATH="$HOME/.local/share/pnpm:$HOME/.pnpm-global/bin:$PATH"
fi

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker no está instalado."
  exit 1
fi

pnpm install

IMAGE_NAME="joxicrochet-ecommerce-backend:latest"
CONTAINER_NAME="joxicrochet-ecommerce-backend"


# Verificar si el contenedor ya existe
if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
  echo "⚠️  El contenedor '$CONTAINER_NAME' ya existe. Eliminándolo..."
  docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
  echo "✅ Contenedor eliminado."
fi

echo "🚀 Creando la imagen de Docker: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" --target production .
echo "✅ Imagen de Docker creada correctamente."

# Verificar si el archivo .env existe antes de usarlo en docker run
ENV_FILE_FLAG=""
if [ -f ".env" ]; then
  ENV_FILE_FLAG="--env-file .env"
else
  echo "⚠️ Advertencia: No se encontró el archivo .env. El contenedor podría no tener las variables necesarias."
fi

# Inicializar swarm si no está activo
if ! docker info | grep -q "Swarm: active"; then
  docker swarm init
fi

## Crear secretos desde .env (cada línea se convierte en un secret individual)
if [ -f ".env" ]; then
  echo "🔐 Creando secrets desde .env..."
  # Crear un archivo temporal para el Docker Compose
  echo "version: '3.8'" > /tmp/secrets.yml
  echo "secrets:" >> /tmp/secrets.yml

  # Leer el archivo .env y crear definiciones de secretos
  while IFS= read -r line || [ -n "$line" ]; do
    # Saltar líneas vacías y comentarios
    [[ -z "$line" || "$line" == \#* ]] && continue
    
    # Extraer clave y valor sin comillas
    key=$(echo "$line" | cut -d '=' -f1 | tr -d ' ')
    value=$(echo "$line" | cut -d '=' -f2- | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//')
    
    # Crear archivo temporal para este secreto
    echo -n "$value" > "/tmp/$key.secret"
    
    # Añadir definición al archivo de compose
    echo "  $key:" >> /tmp/secrets.yml
    echo "    file: /tmp/$key.secret" >> /tmp/secrets.yml
  done < .env

  # Desplegar los secretos
  docker stack deploy -c /tmp/secrets.yml secrets_stack

  # Limpiar archivos temporales
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    key=$(echo "$line" | cut -d '=' -f1 | tr -d ' ')
    rm "/tmp/$key.secret"
  done < .env
  rm /tmp/secrets.yml
else
  echo "⚠️ Advertencia: No se encontró el archivo .env. El backend podría no tener variables necesarias."
fi

echo "🚀 Iniciando contenedores con Docker stack..."
docker stack deploy -c docker-compose.yml backend
echo "✅ Contenedores de Docker Compose iniciados correctamente."

cd .. || { echo "❌ Error: No se pudo regresar al directorio anterior."; exit 1; }

echo "🎉 Proceso finalizado con éxito."