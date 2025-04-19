#!/bin/bash
set -e

if [ -d "./backend" ]; then
  cd backend
else
  if [ -f ".env" ]; then
    echo "Estamos en backend"
  else
    exit 1
  fi
fi


if [ -f ".env" ]; then
  echo "🔐 Creando secrets desde .env..."
  while IFS= read -r line || [ -n "$line" ]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    key=$(echo "$line" | cut -d '=' -f1)
    value=$(echo "$line" | cut -d '=' -f2-)

    if docker secret inspect "$key" >/dev/null 2>&1; then
      docker secret rm "$key"
    fi

    echo $key=$value
    echo -n "$value" | docker secret create "$key" -
  done < .env
  echo "✅ Secrets creados exitosamente."
else
  echo "⚠️ Advertencia: No se encontró el archivo .env. El backend podría no tener variables necesarias."
fi
