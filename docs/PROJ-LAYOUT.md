# Project Layout

```
make-repo/
├── bin/
│   ├── make-repo               # CLI entry point — create/edit GitHub repos (bash, ~775 lines)
│   └── fork-repo               # CLI entry point — fork repos + configure remotes (bash, ~435 lines)
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
| `bin/make-repo` | Creates or edits GitHub repos via `gh` CLI with interactive confirmation, parent-repo inheritance, team access grants, and env-var configuration (precedence: flags → override env vars → parent repo → base env vars → defaults) |
| `bin/fork-repo` | Forks a repo via `gh` CLI — local clone mode (fork cwd's repo, rewire origin/upstream) or remote slug mode (`fork-repo org/repo`, optional `--clone`) |
| `Makefile` | `make install` copies both bin scripts to `~/.local/bin` (skips when already the same file); `compile`/`test` are no-ops |
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
