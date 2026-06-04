# dependabot-helm

End-to-end verification that the **Helm `versioning-strategy`** support proposed
in [dependabot/dependabot-core#15216](https://github.com/dependabot/dependabot-core/issues/15216)
works across the full pipeline (file fetch → parse → live OCI registry
resolution → file update → proposed change), for all three strategies.

> **Honest caveat:** pre-merge, the GitHub-hosted Dependabot service cannot run
> the proposed branch — it only runs released code. Everything here runs the
> [`casey/helm-versioning-strategy`](https://github.com/casey-robertson-paypal/dependabot-core/tree/casey/helm-versioning-strategy)
> branch via `bin/dry-run.rb`, executed either locally or in this repo's CI. It
> demonstrates the branch's behavior; it is not the hosted Dependabot opening
> real PRs.

## What's here

- `producers/` — three trivial charts published to
  `oci://ghcr.io/casey-robertson-paypal/dependabot-helm` at controlled versions.
- `consumer/Chart.yaml` — consumes them via OCI with different constraint styles.
- `publish.sh` — one-time publish of the producer charts to GHCR.
- `verify.sh` — runs the three strategies against a local dependabot-core checkout.
- `transcripts/` — committed dry-run output.
- `.github/workflows/verify.yml` — CI that reproduces the matrix and uploads transcripts.

## Producer version histories

| Producer chart | Published versions | Highest |
|---|---|---|
| `app-base` | `1.0.0`, `1.0.5` | `1.0.5` |
| `cron-base` | `1.0.0`, `2.0.0` | `2.0.0` |
| `db-base` | `1.0.0`, `1.5.0` | `1.5.0` |

## Consumer constraints + expected results

`consumer/Chart.yaml` pins:

| dep | constraint | highest | `increase` (`bump_versions`) | `increase-if-necessary` (`bump_versions_if_necessary`) | `widen` (`widen_ranges`) |
|---|---|---|---|---|---|
| app-base | `^1.0.0` | 1.0.5 (in range) | PR → `^1.0.5` | **no PR** ⭐ | **no PR** |
| cron-base | `^1.0.0` | 2.0.0 (out of range) | PR → `^2.0.0` | PR → `^2.0.0` | PR → `^2.0.0` |
| db-base | `1.0.0` | 1.5.0 | PR → `1.5.0` | PR → `1.5.0` | PR → `1.5.0` |

⭐ The headline behavior: an in-range patch produces **no PR** under
`increase-if-necessary`/`widen`, instead of being exact-pinned as Dependabot
does today.

## Reproduce locally

Prerequisites: `helm`, `oras` (`brew install oras`), Ruby 3.4.x, and a checkout
of the branch as a sibling directory:

```bash
git clone -b casey/helm-versioning-strategy \
  https://github.com/casey-robertson-paypal/dependabot-core.git ../dependabot-core
(cd ../dependabot-core/helm && bundle install)

export LOCAL_GITHUB_ACCESS_TOKEN=<your_github_pat>
./verify.sh           # writes transcripts/<strategy>.txt
```

If you don't have `oras`/`helm` locally, run inside the dependabot-core dev
shell instead: `bin/docker-dev-shell helm`, then run `verify.sh` from this repo
(it bundles helm + oras).

## Reproduce in CI

The **verify** workflow (Actions tab, or `workflow_dispatch`) checks out the
branch, installs the toolchain, runs `verify.sh`, and uploads the transcripts as
a build artifact.

## For dependabot-core maintainers

This repo is intended as a ready-made public fixture for reviewing
[dependabot/dependabot-core#15216](https://github.com/dependabot/dependabot-core/issues/15216).
If you'd like to confirm the behavior with your own tooling (e.g. a custom
updater image built from the branch, as was done for the `go.work` PR via a
dedicated test repo), point it at `casey-robertson-paypal/dependabot-helm`,
directory `/consumer`, with `versioning-strategy: increase-if-necessary`. The
committed `transcripts/` and the **verify** workflow show the expected results.

## Republishing / new scenarios

Edit the version lists in `publish.sh` (e.g. add `1.0.6` or `3.0.0`) and re-run
it to spin up new in-range / out-of-range cases, then re-run `verify.sh`.
