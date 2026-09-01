# Project Layout

Terminal utility package: create/edit GitHub repos (`make-repo`) and fork with remote
rewiring (`fork-repo`). Two self-contained Bash scripts wrapping `gh`/`git` — no
`k8-lib`, no `lib/`. Install to `~/.local/bin` via `make install` (or monorepo
`make install-utilities`).

Plain tree: [`PROJ-LAYOUT.summary.md`](PROJ-LAYOUT.summary.md). Arch: [`PROJ-ARCH.md`](PROJ-ARCH.md).

```
make-repo/
├── bin/                            # CLIs installed to ~/.local/bin
│   ├── make-repo                   #   Create/edit GitHub repos (~995 lines bash)
│   └── fork-repo                   #   Fork + rewire origin/upstream (~432 lines bash)
├── tests/
│   └── run.sh                      #   Isolated fake-gh integration suite
├── docs/
│   ├── PROJ-ARCH.md(+.summary)     #   Architecture + flow diagrams
│   ├── PROJ-LAYOUT.md(+.summary)   #   This file + tree-only companion
│   ├── PROJ-HOWTO.md(+.summary)    #   Task guides (install, create, fork, edit)
│   ├── PROJ-FAQ.md(+.summary)      #   Common questions
│   └── howto/
│       └── avoid-submodule-conversion.md  # Parent integration: none/subtree/submodule
├── .gitignore                      # Editor swap, .env, .envrc.local
├── CHANGELOG.md                    # Package changelog
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
