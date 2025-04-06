#!/bin/bash
set -e

VPS_USER="root"
VPS_HOST="127.0.0.1"
STACK_NAME="joxicrochet"

while getopts "u:h:s:" opt; do
  case $opt in
    u) VPS_USER="$OPTARG";;
    h) VPS_HOST="$OPTARG";;
    s) STACK_NAME="$OPTARG";;
    \?) echo "Opción inválida: -$OPTARG" >&2; exit 1;;
  esac
done

DEPLOY_PATH="/home/admin/${STACK_NAME}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Función para mostrar mensajes
log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
  exit 1
}

cleanup() {
  log "Cleaning up temporary files..."
  rm -rf docker-images
}
trap cleanup EXIT

command -v ssh >/dev/null 2>&1 || error "SSH is required but not installed"
command -v scp >/dev/null 2>&1 || error "SCP is required but not installed"

log "Estableciendo conexión SSH con el servidor VPS..."
ssh $VPS_USER@$VPS_HOST "mkdir -p $DEPLOY_PATH/scripts $DEPLOY_PATH/backend" || error "No se pudo crear directorios en el VPS."

log "Transfiriendo archivos al VPS..."
scp scripts/*.sh $VPS_USER@$VPS_HOST:$DEPLOY_PATH/scripts/ || error "Falló la transferencia de scripts"
scp backend/.env $VPS_USER@$VPS_HOST:$DEPLOY_PATH/backend/ || error "Falló la transferencia de variables de entorno"

log "Ejecutando comandos en el VPS..."
ssh $VPS_USER@$VPS_HOST "bash -s" << EOF || error "Deployment failed"
  set -e

  DEPLOY_PATH="${DEPLOY_PATH}"

  echo "🔄 Entrando en la carpeta '$DEPLOY_PATH'..."
  cd "$DEPLOY_PATH" || { echo "❌ Error: No se pudo acceder al directorio '$DEPLOY_PATH'"; exit 1; }


  if [ -d "./backend" ]; then
    cd ./backend || { echo "❌ Error: No se pudo acceder al directorio 'backend'"; exit 1; }
    git pull || { echo "❌ Error: No se pudo hacer git pull"; exit 1; }
  else
    git clone git@github.com:yeferson59/joxicrochet-backend.git backend || { echo "❌ Error: No se pudo clonar el repositorio de backend."; exit 1; }
    cd ./backend || { echo "❌ Error: No se pudo acceder al directorio 'backend'"; exit 1; }
  fi

  if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker no está instalado."
    exit 1
  fi

  if ! systemctl is-active --quiet docker; then
    echo "❌ Error: Docker no está corriendo. Inícialo con 'sudo systemctl start docker'"
    exit 1
  fi

  if ! docker info | grep -q "Swarm: active"; then
    echo "🔄 Inicializando Docker Swarm..."
    docker swarm init || { echo "❌ Error al inicializar Swarm"; exit 1; }
  fi

  chmod +x ../scripts/*.sh
  cd ..
  ./scripts/create-backend.sh || { echo "❌ Error: Error al crear el contenedor de backend."; exit 1; }

  echo "delete files and folders saved in backend folder"
  rm -rf ./backend/.env
  rm -rf ./scripts

  echo "✅ Proceso finalizado con éxito."
EOF
