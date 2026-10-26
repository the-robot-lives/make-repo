# Project Layout

〚📁:c3ff4a05-4c38-5ae1-bf0a-87225b6da276〛 make-repo PROJ-LAYOUT :: Repository layout map: bin/, tests/, docs/, agent guidance files

Terminal utility package: create/edit GitHub repos (`make-repo`) and fork with remote
rewiring (`fork-repo`). Two self-contained Bash scripts wrapping `gh`/`git` — no
`k8-lib`, no `lib/`. Install to `~/.local/bin` via `make install` (or monorepo
`make install-utilities`).

Plain tree: [`PROJ-LAYOUT.summary.md`](PROJ-LAYOUT.summary.md). Arch: [`PROJ-ARCH.md`](PROJ-ARCH.md).

```
make-repo/
├── bin/                            # CLIs installed to ~/.local/bin
│   ├── make-repo                   #   Create/edit GitHub repos (~1557 lines bash)
│   └── fork-repo                   #   Fork + rewire origin/upstream (~435 lines bash)
├── tests/
│   └── run.sh                      #   Isolated fake-gh integration suite
├── docs/
│   ├── PROJ-ARCH.md(+.summary)     #   Architecture + flow diagrams
│   ├── PROJ-SCHEMA.md(+.summary)   #   Data artifacts: env vars, flags, git files (no DB)
│   ├── PROJ-LAYOUT.md(+.summary)   #   This file + tree-only companion
│   ├── PROJ-HOWTO.md(+.summary)    #   Task guides (install, create, fork, edit)
│   ├── PROJ-FAQ.md(+.summary)      #   Common questions
│   ├── THREAT-MODEL.md(+.summary)  #   Attack surface, trust boundaries, risk register
│   └── howto/
│       └── avoid-submodule-conversion.md  # Parent integration: none/subtree/submodule
├── .gitignore                      # Editor swap, .env, .envrc.local, .claude/worktrees/
├── AGENT.md                        # Agent guidance (Codex/Grok/Cursor; AGENTS.md sibling)
├── AGENTS.md                       # Same policy as AGENT.md for AGENTS.md tooling
├── CHANGELOG.md                    # Package changelog
├── CLAUDE.md                       # Agent guidance for Claude Code (worktree convention, PR policy)
├── Makefile                        # install → ~/.local/bin; test → tests/run.sh; compile no-op
└── README.md                       # Start here — flags, env vars, examples
```

## Key Files

| Path | Purpose |
|------|---------|
| `bin/make-repo` | Create or edit GitHub repos via `gh`; parent org/visibility inheritance; optional subtree/submodule integration (default: none) |
| `bin/fork-repo` | Fork current clone or `org/repo` slug; local mode rewires remotes; slug mode optional `--clone` |
| `tests/run.sh` | Temp parent/child repos + fake `gh`; covers none/subtree/submodule, `--origin` add/swap/attach/worktree/submodule, dry-run, headless, flag conflicts |
| `Makefile` | `make install` (symlink-aware copy of both bins); `make test` runs suite; `compile` is no-op |
| `docs/THREAT-MODEL.md` | Attack surface, trust boundaries, vulnerability register (`T-001`…) |
| `CLAUDE.md` / `AGENT.md` / `AGENTS.md` | Agent guidance for Claude Code and the Codex/Grok/Cursor harness family; same policy, worktrees + `develop`-targeted PRs |
| `docs/howto/avoid-submodule-conversion.md` | When/how to choose parent integration after create |

## Setup

```bash
make install          # copies bin/* → ~/.local/bin (755; skips if already same file)
make test             # fake-gh integration suite (no network)
```

Or: `export PATH="$PATH:/path/to/make-repo/bin"`.

**Requires:** `bash`, `git`, authenticated GitHub CLI (`gh auth login`). ShellCheck is
dev-only (`shellcheck bin/* tests/run.sh`).

## Notes

- No `lib/` or shared library — scripts are portable outside the monorepo.
- No `docs/layout/*` extract — package is two flat scripts + one test runner.
- Placement in catalog: shell/make-repo under `Portfolio/Utilities/` (see parent OVERVIEW).
