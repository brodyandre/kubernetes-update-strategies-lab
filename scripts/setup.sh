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

log_info "Validating required tools..."
require_commands
ensure_docker_running

if cluster_exists; then
  log_ok "Cluster '${CLUSTER_NAME}' already exists."
else
  log_info "Creating k3d cluster '${CLUSTER_NAME}'..."
  k3d cluster create "${CLUSTER_NAME}" --agents 2
  log_ok "Cluster '${CLUSTER_NAME}' created successfully."
fi

log_info "Switching kubectl context to '${CONTEXT_NAME}'..."
kubectl config use-context "${CONTEXT_NAME}" >/dev/null
log_ok "kubectl context is now '${CONTEXT_NAME}'."

log_info "Cluster nodes:"
kubectl get nodes -o wide

log_ok "Environment is ready for the lab."
