#!/usr/bin/env bash
# Runs dependabot-core (local checkout) against this repo's consumer chart for
# each versioning strategy, capturing transcripts.
#
# Requires:
#   - oras + helm on PATH (or run inside `bin/docker-dev-shell helm`)
#   - LOCAL_GITHUB_ACCESS_TOKEN exported (a PAT; avoids rate limiting / private access)
#   - DEPENDABOT_CORE pointing at a dependabot-core checkout on the
#     casey/helm-versioning-strategy branch (defaults to ../dependabot-core)
set -euo pipefail

DEPENDABOT_CORE="${DEPENDABOT_CORE:-../dependabot-core}"
REPO="casey-robertson-paypal/dependabot-helm"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/transcripts"

for s in bump_versions bump_versions_if_necessary widen_ranges; do
  echo "=== strategy: $s ==="
  (cd "$DEPENDABOT_CORE" && \
    bin/dry-run.rb helm "$REPO" \
      --dir=/consumer \
      --requirements-update-strategy="$s") 2>&1 | tee "$ROOT/transcripts/$s.txt"
  echo
done
