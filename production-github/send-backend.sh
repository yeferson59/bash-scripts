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

DEPLOY_PATH="/home/${VPS_USER}/${STACK_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
  echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
  echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
  exit 1
}

command -v ssh >/dev/null 2>&1 || error "SSH is required but not installed"
command -v scp >/dev/null 2>&1 || error "SCP is required but not installed"

log "Estableciendo conexión SSH con el servidor VPS..."
# Corregido: faltaba cerrar la comilla y el comando
ssh $VPS_USER@$VPS_HOST "mkdir -p $DEPLOY_PATH/scripts $DEPLOY_PATH/backend" || error "No se pudo crear directorios en el VPS."

log "Transfiriendo archivos al VPS..."
scp ./scripts/*.sh $VPS_USER@$VPS_HOST:$DEPLOY_PATH/scripts/ || error "Falló la transferencia de scripts"
scp ./scripts/production-github/*.sh $VPS_USER@$VPS_HOST:$DEPLOY_PATH/scripts/ || error "Falló la transferencia de scripts"
scp ./backend/.env $VPS_USER@$VPS_HOST:$DEPLOY_PATH/backend/ || error "Falló la transferencia de variables de entorno"

log "Ejecutando comandos en el VPS..."
ssh $VPS_USER@$VPS_HOST "bash -s" << EOF || error "Deployment failed"
  set -e

  DEPLOY_PATH="${DEPLOY_PATH}"

  cd "$DEPLOY_PATH" || { echo "❌ Error: No se pudo acceder al directorio '$DEPLOY_PATH' "; exit 1; }

  # Asegúrate de que este script existe en el servidor
  ./scripts/create-env.sh
EOF

log "Despliegue completado exitosamente"
