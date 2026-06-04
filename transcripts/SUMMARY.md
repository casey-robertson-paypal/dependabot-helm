## Helm `versioning-strategy` dry-run results

Repo `casey-robertson-paypal/dependabot-helm`, directory `/consumer`. "no PR" = no update proposed (latest already in range).

| Dependency | Constraint | increase | increase-if-necessary | widen |
|---|---|---|---|---|
| `app-base` | `^1.0.0` | `^1.0.5` | no PR | no PR |
| `cron-base` | `^1.0.0` | `^2.0.0` | `^2.0.0` | `^2.0.0` |
| `db-base` | `1.0.0` | `1.5.0` | `1.5.0` | `1.5.0` |
| `web-base` | `~1.2.0` | `~1.2.9` | no PR | no PR |
| `api-base` | `>=1.0.0 <2.0.0` | `>=1.0.0 <3.0.0` | `>=1.0.0 <3.0.0` | `>=1.0.0 <3.0.0` |
