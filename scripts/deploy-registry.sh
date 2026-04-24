#!/usr/bin/env bash
# deploy-registry.sh — Deploy or upgrade the registry Helm chart.
#
# This script is self-contained. Copy it to any machine with helm and kubectl
# and run it directly — no local clone of the repo needed.
#
# Usage:
#   ./deploy-registry.sh [OPTIONS]
#
# Options:
#   -r, --release NAME        Helm release name           (default: registry)
#   -n, --namespace NS        Kubernetes namespace        (default: registry)
#   -f, --values FILE         Extra values file to merge
#       --version VERSION     Chart version to install    (default: 0.1.0)
#       --auth-user USER      Enable auth and add a user  (repeatable)
#       --auth-password PASS  Password for the last --auth-user (required when --auth-user is set)
#       --auth-secret SECRET  Use a pre-existing htpasswd Secret instead of --auth-user
#       --proxy               Enable pull-through proxy mode
#       --proxy-url URL       Upstream registry URL       (default: https://registry-1.docker.io)
#       --existing-claim PVC  Share an existing PVC instead of creating one
#       --dry-run             Pass --dry-run to Helm (renders templates, no cluster changes)
#   -h, --help                Show this help and exit

set -euo pipefail

GITHUB_RAW="https://raw.githubusercontent.com/harrisonwaffel/dev-tools/master/packages"

# ---------- defaults ----------
RELEASE="registry"
NAMESPACE="registry"
VALUES_FILE=""
CHART_VERSION="0.1.0"
AUTH_USERS=()
AUTH_PASSWORDS=()
AUTH_SECRET=""
PROXY=false
PROXY_URL="https://registry-1.docker.io"
EXISTING_CLAIM=""
DRY_RUN=false

# ---------- helpers ----------
usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

die() { echo "ERROR: $*" >&2; exit 1; }

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--release)         RELEASE="$2";           shift 2 ;;
    -n|--namespace)       NAMESPACE="$2";         shift 2 ;;
    -f|--values)          VALUES_FILE="$2";       shift 2 ;;
    --version)            CHART_VERSION="$2";     shift 2 ;;
    --auth-user)          AUTH_USERS+=("$2");     shift 2 ;;
    --auth-password)      AUTH_PASSWORDS+=("$2"); shift 2 ;;
    --auth-secret)        AUTH_SECRET="$2";       shift 2 ;;
    --proxy)              PROXY=true;             shift   ;;
    --proxy-url)          PROXY_URL="$2";         shift 2 ;;
    --existing-claim)     EXISTING_CLAIM="$2";    shift 2 ;;
    --dry-run)            DRY_RUN=true;           shift   ;;
    -h|--help)            usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

# ---------- validation ----------
[[ ${#AUTH_USERS[@]} -ne ${#AUTH_PASSWORDS[@]} ]] && \
  die "Each --auth-user must be followed by an --auth-password."

[[ -n "$AUTH_SECRET" && ${#AUTH_USERS[@]} -gt 0 ]] && \
  die "--auth-secret and --auth-user are mutually exclusive."

[[ -n "$VALUES_FILE" && ! -f "$VALUES_FILE" ]] && \
  die "Values file not found: $VALUES_FILE"

CHART_URL="${GITHUB_RAW}/registry-${CHART_VERSION}.tgz"

# ---------- build helm args ----------
HELM_ARGS=(
  upgrade --install
  "$RELEASE" "$CHART_URL"
  --namespace "$NAMESPACE"
  --create-namespace
)

# Auth via inline users
if [[ ${#AUTH_USERS[@]} -gt 0 ]]; then
  HELM_ARGS+=(--set auth.enabled=true)
  for i in "${!AUTH_USERS[@]}"; do
    HELM_ARGS+=(
      --set "auth.users[$i].username=${AUTH_USERS[$i]}"
      --set "auth.users[$i].password=${AUTH_PASSWORDS[$i]}"
    )
  done
fi

# Auth via pre-existing Secret
if [[ -n "$AUTH_SECRET" ]]; then
  HELM_ARGS+=(
    --set auth.enabled=true
    --set "auth.existingSecret=$AUTH_SECRET"
  )
fi

# Proxy / pull-through cache
if [[ "$PROXY" == true ]]; then
  HELM_ARGS+=(
    --set proxy.enabled=true
    --set "proxy.remoteUrl=$PROXY_URL"
  )
fi

# Shared PVC
if [[ -n "$EXISTING_CLAIM" ]]; then
  HELM_ARGS+=(--set "persistence.existingClaim=$EXISTING_CLAIM")
fi

# Extra values file
if [[ -n "$VALUES_FILE" ]]; then
  HELM_ARGS+=(-f "$VALUES_FILE")
fi

# Dry-run
if [[ "$DRY_RUN" == true ]]; then
  HELM_ARGS+=(--dry-run)
fi

# ---------- deploy ----------
echo "Deploying registry chart v${CHART_VERSION}"
echo "  Source:    $CHART_URL"
echo "  Release:   $RELEASE"
echo "  Namespace: $NAMESPACE"
[[ ${#AUTH_USERS[@]} -gt 0 ]] && echo "  Auth:      enabled (${#AUTH_USERS[@]} user(s))"
[[ -n "$AUTH_SECRET" ]]       && echo "  Auth:      existing secret '$AUTH_SECRET'"
[[ "$PROXY" == true ]]        && echo "  Proxy:     $PROXY_URL"
[[ -n "$EXISTING_CLAIM" ]]    && echo "  PVC:       existing claim '$EXISTING_CLAIM'"
[[ "$DRY_RUN" == true ]]      && echo "  Mode:      dry-run"
echo ""

helm "${HELM_ARGS[@]}"

if [[ "$DRY_RUN" != true ]]; then
  echo ""
  echo "Registry deployed. In-cluster endpoint:"
  echo "  http://docker-registry.$NAMESPACE.svc.cluster.local:5000"
  echo ""
  echo "Port-forward for local access:"
  echo "  kubectl port-forward -n $NAMESPACE svc/docker-registry 5000:5000"
fi
