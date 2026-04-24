#!/usr/bin/env bash
# package-chart.sh — Lint and package a Helm chart from the charts/ directory.
#
# Reads the chart version from Chart.yaml and writes the resulting .tgz to
# packages/. Fails fast if linting finds any errors.
#
# Usage:
#   ./scripts/package-chart.sh <chart-name>
#
# Example:
#   ./scripts/package-chart.sh registry

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHARTS_DIR="$REPO_ROOT/charts"
PACKAGES_DIR="$REPO_ROOT/packages"

# ---------- args ----------
[[ $# -lt 1 ]] && { echo "Usage: $(basename "$0") <chart-name>"; exit 1; }

CHART_NAME="$1"
CHART_DIR="$CHARTS_DIR/$CHART_NAME"
CHART_YAML="$CHART_DIR/Chart.yaml"

[[ -d "$CHART_DIR" ]]  || { echo "ERROR: chart not found: $CHART_DIR" >&2; exit 1; }
[[ -f "$CHART_YAML" ]] || { echo "ERROR: Chart.yaml not found in $CHART_DIR" >&2; exit 1; }

# ---------- read version ----------
VERSION="$(grep '^version:' "$CHART_YAML" | awk '{print $2}')"
[[ -n "$VERSION" ]] || { echo "ERROR: could not parse version from $CHART_YAML" >&2; exit 1; }

ARTIFACT="$PACKAGES_DIR/${CHART_NAME}-${VERSION}.tgz"

echo "Chart:   $CHART_NAME"
echo "Version: $VERSION"
echo ""

# ---------- lint ----------
echo "==> helm lint"
helm lint "$CHART_DIR"
echo ""

# ---------- check for existing artifact ----------
if [[ -f "$ARTIFACT" ]]; then
  echo "WARNING: $ARTIFACT already exists and will be overwritten." >&2
fi

# ---------- package ----------
echo "==> helm package"
mkdir -p "$PACKAGES_DIR"
helm package "$CHART_DIR" --destination "$PACKAGES_DIR"

echo ""
echo "Package written to: $ARTIFACT"
