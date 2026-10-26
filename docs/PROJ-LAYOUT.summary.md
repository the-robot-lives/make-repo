# Project Layout — Summary

Annotated tree: [`PROJ-LAYOUT.md`](PROJ-LAYOUT.md).

```
make-repo/
├── bin/
│   ├── make-repo               # create/edit GitHub repos (gh wrapper)
│   └── fork-repo               # fork + configure remotes
├── tests/
│   └── run.sh                  # fake-gh parent integration + origin-mode tests
├── docs/
│   ├── PROJ-ARCH*(.summary)    # architecture
│   ├── PROJ-SCHEMA*(.summary)  # data artifacts (env/flags/git; no DB)
│   ├── PROJ-LAYOUT*(.summary)  # this map
│   ├── PROJ-HOWTO*(.summary)   # task guides
│   ├── PROJ-FAQ*(.summary)     # FAQ
│   ├── THREAT-MODEL*(.summary) # attack surface, trust boundaries, risk register
│   └── howto/
│       └── avoid-submodule-conversion.md
├── .gitignore
├── AGENT.md                    # agent guidance (AGENTS.md sibling)
├── AGENTS.md
├── CHANGELOG.md
├── CLAUDE.md                   # agent guidance (Claude Code)
├── Makefile                    # install → ~/.local/bin; test → run.sh
└── README.md
```
