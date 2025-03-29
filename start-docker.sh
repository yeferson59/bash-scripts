#!/bin/bash

echo "Entering backend folder..."
if [ -d "./backend" ]; then
  cd ./backend || { echo "❌ Error: No se pudo acceder al directorio 'backend'"; exit 1; }
else
  echo "❌ Error: El directorio 'backend' no existe."
  exit 1
fi

# Verificar si docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
  echo "❌ Error: docker-compose no está instalado."
  exit 1
fi

# Verificar si ya hay contenedores corriendo
if docker-compose ps | grep -q "Up"; then
  echo "📦 La base de datos ya está en ejecución."
else
  echo "🚀 Iniciando la base de datos..."
  docker-compose up -d > /dev/null
  if [ $? -ne 0 ]; then
    echo "❌ Error al iniciar la base de datos."
    exit 1
  fi
  echo "✅ Base de datos iniciada correctamente."
fi

# Salir del directorio backend
cd .. || { echo "❌ Error: No se pudo regresar al directorio anterior."; exit 1; }

echo "🚀 Base de datos lista. Ahora puedes ejecutar: node --run start:dev"