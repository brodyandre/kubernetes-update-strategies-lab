#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLUE_APP_DIR="${ROOT_DIR}/apps/blue"
GREEN_APP_DIR="${ROOT_DIR}/apps/green"

log_info() {
  echo "[INFO] $*"
}

log_ok() {
  echo "[OK] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

require_commands() {
  local command_name

  for command_name in docker kubectl k3d; do
    if ! command -v "${command_name}" >/dev/null 2>&1; then
      log_error "Required command '${command_name}' was not found in PATH."
      exit 1
    fi
  done
}

ensure_docker_running() {
  if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not available. Start Docker Desktop and try again."
    exit 1
  fi
}

log_info "Validating required tools..."
require_commands
ensure_docker_running

if [[ ! -d "${BLUE_APP_DIR}" || ! -d "${GREEN_APP_DIR}" ]]; then
  log_error "Application directories were not found. Check the project structure."
  exit 1
fi

log_info "Building image 'update-demo-blue:v1'..."
docker build -t update-demo-blue:v1 "${BLUE_APP_DIR}"

log_info "Building image 'update-demo-green:v2'..."
docker build -t update-demo-green:v2 "${GREEN_APP_DIR}"

log_ok "Docker images built successfully."
log_info "Available lab images:"
docker image ls --filter=reference='update-demo-*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
