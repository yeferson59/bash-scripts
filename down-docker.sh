#!/bin/bash

cd ./backend || { echo "❌ Error: No se pudo acceder al directorio 'backend'"; exit 1; }

# Verificar si docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
  echo "❌ Error: docker-compose no está instalado."
  exit 1
fi
# Función para detener Docker al salir
cleanup() {
  echo "🛑 Deteniendo los contenedores de Docker..."
  docker-compose down
  echo "✅ Contenedores detenidos correctamente."
}

# Verificar si ya hay contenedores corriendo
if docker-compose ps | grep -q "Up"; then
  echo "🚀 Deteniendo los contenedores de Docker..."
  cleanup
else
  echo "✅ No hay contenedores corriendo."
fi

cd .. || { echo "❌ Error: No se pudo regresar al directorio anterior."; exit 1; }