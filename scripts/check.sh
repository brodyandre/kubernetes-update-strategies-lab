#!/usr/bin/env bash
set -euo pipefail

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

ensure_cluster_exists() {
  if ! cluster_exists; then
    log_error "Cluster '${CLUSTER_NAME}' was not found. Run ./scripts/setup.sh first."
    exit 1
  fi
}

use_cluster_context() {
  log_info "Switching kubectl context to '${CONTEXT_NAME}'..."
  kubectl config use-context "${CONTEXT_NAME}" >/dev/null
}

log_info "Validating required tools..."
require_commands
ensure_docker_running
ensure_cluster_exists
use_cluster_context

if ! kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  log_warn "Namespace '${NAMESPACE}' was not found. Apply one of the strategies first."
  exit 0
fi

log_info "Namespace details:"
kubectl get namespace "${NAMESPACE}" --show-labels

echo
log_info "Pods in namespace '${NAMESPACE}':"
kubectl get pods -n "${NAMESPACE}" -o wide

echo
log_info "Deployments in namespace '${NAMESPACE}':"
kubectl get deployments -n "${NAMESPACE}" -o wide

echo
log_info "Services in namespace '${NAMESPACE}':"
kubectl get services -n "${NAMESPACE}" -o wide

echo
log_info "Endpoints in namespace '${NAMESPACE}':"
kubectl get endpoints -n "${NAMESPACE}"

echo
log_info "Rollout status for deployments in namespace '${NAMESPACE}':"
mapfile -t DEPLOYMENTS < <(kubectl get deployments -n "${NAMESPACE}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

if [[ "${#DEPLOYMENTS[@]}" -eq 0 ]]; then
  log_warn "No deployments were found. Rollout status is not applicable."
else
  for deployment_name in "${DEPLOYMENTS[@]}"; do
    if [[ -z "${deployment_name}" ]]; then
      continue
    fi

    echo
    log_info "Rollout status for deployment '${deployment_name}':"
    if ! kubectl rollout status "deployment/${deployment_name}" -n "${NAMESPACE}" --timeout=5s; then
      log_warn "Deployment '${deployment_name}' is not fully rolled out yet or requires further inspection."
    fi
  done
fi

log_ok "Resource check completed."
