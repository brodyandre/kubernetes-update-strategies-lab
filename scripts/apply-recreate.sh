#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="update-strategies-lab"
CONTEXT_NAME="k3d-${CLUSTER_NAME}"
NAMESPACE="update-strategies"

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

use_cluster_context() {
  log_info "Switching kubectl context to '${CONTEXT_NAME}'..."
  kubectl config use-context "${CONTEXT_NAME}" >/dev/null
}

show_resource_summary() {
  echo
  log_info "Pods in namespace '${NAMESPACE}':"
  kubectl get pods -n "${NAMESPACE}" -o wide

  echo
  log_info "Deployments in namespace '${NAMESPACE}':"
  kubectl get deployments -n "${NAMESPACE}" -o wide

  echo
  log_info "Services in namespace '${NAMESPACE}':"
  kubectl get services -n "${NAMESPACE}" -o wide
}

log_info "Validating required tools..."
require_commands
ensure_docker_running
ensure_cluster_exists
use_cluster_context

log_info "Applying namespace manifest..."
kubectl apply -f "${ROOT_DIR}/manifests/00-namespace/namespace.yaml"

log_info "Applying Recreate service manifest..."
kubectl apply -f "${ROOT_DIR}/manifests/01-recreate/service.yaml"

log_info "Applying Recreate deployment with blue version..."
kubectl apply -f "${ROOT_DIR}/manifests/01-recreate/deployment-blue.yaml"

log_info "Waiting for rollout of deployment 'recreate-demo'..."
kubectl rollout status deployment/recreate-demo -n "${NAMESPACE}" --timeout=120s

log_ok "Recreate strategy applied successfully with the blue version."
show_resource_summary

echo
log_info "Next step to update to green:"
echo "kubectl apply -f manifests/01-recreate/deployment-green.yaml"
