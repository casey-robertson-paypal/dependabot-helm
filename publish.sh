#!/usr/bin/env bash
# Publishes the producer charts to GHCR OCI at controlled versions.
# Requires: helm, and `helm registry login ghcr.io` with a token carrying write:packages.
set -euo pipefail

REGISTRY="oci://ghcr.io/casey-robertson-paypal/dependabot-helm"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# publish <chart> <version>...
publish() {
  local chart="$1"; shift
  for v in "$@"; do
    rm -rf "$WORK/$chart"
    cp -r "$ROOT/producers/$chart" "$WORK/$chart"
    # stamp the version into Chart.yaml
    sed -i.bak "s/^version: .*/version: $v/" "$WORK/$chart/Chart.yaml"
    rm -f "$WORK/$chart/Chart.yaml.bak"
    helm package "$WORK/$chart" --destination "$WORK"
    helm push "$WORK/$chart-$v.tgz" "$REGISTRY"
    rm -f "$WORK/$chart-$v.tgz"
  done
}

publish app-base  1.0.0 1.0.5        # caret, latest in range
publish cron-base 1.0.0 2.0.0        # caret, latest out of range
publish db-base   1.0.0 1.5.0        # exact pin
publish web-base  1.2.0 1.2.9        # tilde, latest in range
publish api-base  1.0.0 1.5.0 2.5.0  # explicit range, latest out of range

echo
echo "Done. Now set the GHCR packages (app-base, cron-base, db-base, web-base, api-base) to PUBLIC"
echo "so dry-run can pull unauthenticated:"
echo "  https://github.com/users/casey-robertson-paypal/packages"
