#!/usr/bin/env bash
# Runs dependabot-core (local checkout) against this repo's consumer chart for
# each versioning strategy, capturing transcripts.
#
# Requires:
#   - ruby (3.4.x), helm, oras, and regctl on PATH (or run inside
#     `bin/docker-dev-shell helm`, which bundles them)
#   - LOCAL_GITHUB_ACCESS_TOKEN exported (a PAT; avoids rate limiting / private access)
#   - DEPENDABOT_CORE pointing at a dependabot-core checkout on the
#     casey/helm-versioning-strategy branch (defaults to ../dependabot-core)
set -euo pipefail

DEPENDABOT_CORE="${DEPENDABOT_CORE:-../dependabot-core}"
REPO="casey-robertson-paypal/dependabot-helm"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/transcripts"

# bin/dry-run.rb normally requires the dependabot dev container; this flag lets
# it run standalone (we provide helm/oras/regctl on PATH instead).
export ALLOW_DRY_RUN_STANDALONE=true

for s in bump_versions bump_versions_if_necessary widen_ranges; do
  echo "=== strategy: $s ==="
  (cd "$DEPENDABOT_CORE" && \
    bundle exec ruby bin/dry-run.rb helm "$REPO" \
      --dir=/consumer \
      --requirements-update-strategy="$s") 2>&1 | tee "$ROOT/transcripts/$s.txt"
  echo
done

# Build a human-readable matrix from the transcripts. For each dependency in the
# consumer chart, show the new requirement written under each strategy, or
# "no change" when the resolved version already satisfies the constraint.
summarize() {
  local md
  md="$(
    echo "## Helm \`versioning-strategy\` dry-run results"
    echo
    echo "Repo \`$REPO\`, directory \`/consumer\`. \"no change\" = no PR proposed (latest already in range)."
    echo
    echo "| Dependency | Constraint | increase | increase-if-necessary | widen |"
    echo "|---|---|---|---|---|"
    while read -r dep constraint; do
      local row="| \`$dep\` | \`$constraint\` |"
      for s in bump_versions bump_versions_if_necessary widen_ranges; do
        local newreq
        newreq="$(awk -v d="$dep" '
          $0 ~ ("=> bump " d " from ") { cap = 1; next }
          cap && /^[[:space:]]*\+[[:space:]]+version:/ {
            sub(/^.*version:[[:space:]]*/, ""); print; cap = 0
          }
        ' "$ROOT/transcripts/$s.txt" | head -1)"
        if [ -n "$newreq" ]; then row="$row \`$newreq\` |"; else row="$row no change |"; fi
      done
      echo "$row"
    done < <(awk '/- name:/{name=$3} /^[[:space:]]*version:/{if(name!=""){print name, $2; name=""}}' \
                  "$ROOT/consumer/Chart.yaml")
  )"
  echo
  echo "$md" | tee "$ROOT/transcripts/SUMMARY.md"
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then echo "$md" >> "$GITHUB_STEP_SUMMARY"; fi
}

summarize
