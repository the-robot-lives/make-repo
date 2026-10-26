# Threat Model — Summary

Full model: [`THREAT-MODEL.md`](THREAT-MODEL.md).

**Posture:** operator-run Bash CLIs on a developer workstation. No listener, no ingress, no
queue, no data at rest. Privilege = ambient `gh` token scope + local filesystem. Crown
jewels: the operator's gh credential scope, the target org's repo/team config, and the
parent repo's working tree and `.git` metadata.

## Trust Boundaries

1. Workstation → GitHub API (ambient `gh` token; never minted or narrowed here)
2. cwd → parent repository (detection walks outward; integration then stages, commits, `git rm`s, rewrites `.gitmodules` and `push-subtrees.sh`)
3. cwd → local git metadata (`.git` moved aside; `.git/modules/<path>` removed; restored from backup)

## Register at a Glance

| ID | Severity | Concern | Status |
|----|----------|---------|--------|
| T-001 | Medium | `--groups` grants team push/admin under `--yes` | Partial (role allowlist, explicit flag) |
| T-002 | Medium | `--origin` swap re-points checkout | Mitigated (prompt, `--swap-origin`, dry-run) |
| T-003 | High | Subtree/submodule `.git` move + `rm -rf` | Mitigated (backups + restore + `:?` guard) |
| T-004 | High | Submodule conversion deletes dir | Mitigated (`cp -a` backup, verify, restore) |
| T-005 | Medium | Rewrites parent `push-subtrees.sh` | Mitigated (clean check, idempotent, separate commit) |
| T-006 | Medium | Remote history overwrite | Mitigated (`safe_push`, never force) |
| T-007 | Medium | Full ambient `gh` scope, no scoped token | **Open — accepted** |
| T-008 | Low | Values reach `gh`/`git` args | Partial (quoted, no eval; arg-position only) |
| T-009 | Medium | Accidental public repo | Mitigated (private default) |
| T-010 | Medium | `.gitmodules` URL rewrite + `submodule sync` | Partial (consent, dirty-abort, no auto-commit) |
| T-011 | Low | Parent commits under operator identity | Accepted |
| T-012 | Low | `copy.<dirname>` backup left on disk | Mitigated (explicit removal message) |

## Coverage

3 mitigated · 5 partial · 3 accepted · 1 open (T-007). No Critical entries; no
network-facing component.

## Residual Risk

- T-007 accepted: an operator who can run `gh` can already do all of this; narrowing scope
  would break the `bash`/`git`/`gh`-only contract.
- T-003/T-004 accepted with backups; deleting `copy.<dirname>` early forfeits the net.
- No secret handling by design: no `.envrc` read, no token printed; auth check is
  `gh auth status` exit status only.
