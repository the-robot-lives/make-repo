# Project Layout

```
make-repo/
├── bin/
│   ├── make-repo               # CLI entry point — create/edit/integrate GitHub repos (bash)
│   └── fork-repo               # CLI entry point — fork repos + configure remotes (bash, ~435 lines)
├── tests/
│   └── run.sh                  # Isolated fake-gh integration tests for none/subtree/submodule
├── docs/
│   ├── PROJ-ARCH.md            # Architecture notes
│   ├── PROJ-ARCH.summary.md    # Compact architecture reference
│   ├── PROJ-LAYOUT.md          # This file
│   └── PROJ-LAYOUT.summary.md  # Compact tree reference
├── .gitignore                  # Editor swap files, .env, .envrc.local
├── Makefile                    # `make install` → symlink-aware copy of bin/* to ~/.local/bin
└── README.md                   # Usage guide, CLI flags, env vars, examples
```

## Key Files

| File | Purpose |
|------|---------|
| `bin/make-repo` | Creates or edits GitHub repos via `gh` CLI with interactive confirmation, parent-repo inheritance, team access grants, and optional subtree/submodule integration |
| `bin/fork-repo` | Forks a repo via `gh` CLI — local clone mode (fork cwd's repo, rewire origin/upstream) or remote slug mode (`fork-repo org/repo`, optional `--clone`) |
| `tests/run.sh` | Creates temporary parent/child repositories and uses a fake `gh` to test default-none, subtree, wrapper registration/discovery, submodule, dry-run, and flag-conflict behavior |
| `Makefile` | `make install` copies both bin scripts to `~/.local/bin`; `make test` runs the integration suite |
| `README.md` | Full documentation: install, quick start, precedence rules, all flags and env vars, edit mode, prerequisites |

## Setup

Install to `~/.local/bin`:

```bash
make install
```

Or add `bin/` to your PATH:

```bash
export PATH="$PATH:/path/to/make-repo/bin"
```

Requires: `gh` CLI authenticated (`gh auth login`).
