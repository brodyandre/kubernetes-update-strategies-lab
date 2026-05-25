#!/usr/bin/env bash
set -euo pipefail

# To delete the k3d cluster manually after cleanup, run:
# k3d cluster delete update-strategies-lab

CLUSTER_NAME="update-strategies-lab"
CONTEXT_NAME="k3d-${CLUSTER_NAME}"
NAMESPACE="update-strategies"

log_info() {
  echo "[INFO] $*"
}

log_ok() {
  echo "[OK] $*"
}

log_warn() {
  echo "[WARN] $*"
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

use_cluster_context() {
  log_info "Switching kubectl context to '${CONTEXT_NAME}'..."
  kubectl config use-context "${CONTEXT_NAME}" >/dev/null
}

log_info "Validating required tools..."
require_commands
ensure_docker_running

if ! cluster_exists; then
  log_warn "Cluster '${CLUSTER_NAME}' was not found. Nothing to clean in Kubernetes."
  log_info "If needed, create the cluster with ./scripts/setup.sh."
  exit 0
fi

use_cluster_context

log_warn "This will remove the namespace '${NAMESPACE}' and all lab resources inside it."
read -r -p "Type 'delete' to continue: " CONFIRMATION

if [[ "${CONFIRMATION}" != "delete" ]]; then
  log_info "Cleanup cancelled."
  exit 0
fi

log_info "Deleting namespace '${NAMESPACE}'..."
kubectl delete namespace "${NAMESPACE}" --ignore-not-found

log_ok "Namespace '${NAMESPACE}' was removed."
log_info "The k3d cluster was preserved."
log_info "To delete the cluster manually, run: k3d cluster delete ${CLUSTER_NAME}"
