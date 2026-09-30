#!/usr/bin/env bash
# install-local-path.sh — Install the Rancher local-path provisioner if the
# local-path StorageClass is missing.
#
# K3s ships this out of the box. RKE2 and most other distros do not, and the
# registry chart's default storageClassName (local-path) needs it.
#
# This script is self-contained. Copy it to any machine with kubectl and run it
# directly — no local clone of the repo needed.
#
# Usage:
#   ./install-local-path.sh [OPTIONS]
#
# Options:
#       --version VERSION     Provisioner release to install (default: v0.0.37)
#       --default             Mark local-path as the cluster default StorageClass
#   -h, --help                Show this help and exit

set -euo pipefail

# ---------- defaults ----------
VERSION="v0.0.37"
MAKE_DEFAULT=false

# ---------- helpers ----------
usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

die() { echo "ERROR: $*" >&2; exit 1; }

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)   VERSION="$2";      shift 2 ;;
    --default)   MAKE_DEFAULT=true; shift   ;;
    -h|--help)   usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

command -v kubectl >/dev/null || die "kubectl not found in PATH."
kubectl version >/dev/null 2>&1 || die "Cannot reach the cluster. Check your kubeconfig."

MANIFEST_URL="https://raw.githubusercontent.com/rancher/local-path-provisioner/${VERSION}/deploy/local-path-storage.yaml"

# ---------- install ----------
if kubectl get storageclass local-path >/dev/null 2>&1; then
  echo "StorageClass 'local-path' already exists. Skipping install."
else
  echo "Installing local-path provisioner ${VERSION}"
  echo "  Source: $MANIFEST_URL"
  echo ""
  kubectl apply -f "$MANIFEST_URL"
  kubectl -n local-path-storage rollout status deployment/local-path-provisioner --timeout=120s
fi

# ---------- default class ----------
if [[ "$MAKE_DEFAULT" == true ]]; then
  kubectl patch storageclass local-path \
    -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
fi

echo ""
kubectl get storageclass
