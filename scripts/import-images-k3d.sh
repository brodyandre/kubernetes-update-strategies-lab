#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="update-strategies-lab"
CONTEXT_NAME="k3d-${CLUSTER_NAME}"

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

cluster_exists() {
  k3d cluster list 2>/dev/null | awk 'NR > 1 { print $1 }' | grep -Fxq "${CLUSTER_NAME}"
}

ensure_cluster_exists() {
  if ! cluster_exists; then
    log_error "Cluster '${CLUSTER_NAME}' was not found. Run ./scripts/setup.sh first."
    exit 1
  fi
}

ensure_images_exist() {
  local image_name

  for image_name in update-demo-blue:v1 update-demo-green:v2; do
    if ! docker image inspect "${image_name}" >/dev/null 2>&1; then
      log_error "Docker image '${image_name}' was not found. Run ./scripts/build-images.sh first."
      exit 1
    fi
  done
}

log_info "Validating required tools..."
require_commands
ensure_docker_running
ensure_cluster_exists
ensure_images_exist

log_info "Switching kubectl context to '${CONTEXT_NAME}'..."
kubectl config use-context "${CONTEXT_NAME}" >/dev/null

log_info "Importing image 'update-demo-blue:v1' into cluster '${CLUSTER_NAME}'..."
k3d image import update-demo-blue:v1 -c "${CLUSTER_NAME}"

log_info "Importing image 'update-demo-green:v2' into cluster '${CLUSTER_NAME}'..."
k3d image import update-demo-green:v2 -c "${CLUSTER_NAME}"

log_ok "Images were imported successfully into cluster '${CLUSTER_NAME}'."
