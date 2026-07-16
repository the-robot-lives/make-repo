# PROJ-FAQ.summary

Question index for `make-repo`/`fork-repo`. Full answers: [PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I use this instead of `gh repo create` directly?
- Why does it auto-detect org/visibility from a parent repo instead of just asking me every time?
- Why a 5-tier precedence chain instead of just CLI flags and defaults?

## Fit
- When is this the wrong tool for publishing a monorepo project?
- When should I not run this non-interactively?

## Comparison
- How does `make-repo` differ from `fork-repo`?
- How does `--no-inherit` differ from `--no-submodule` — do I need both?
- How does editing with `--edit` differ from just re-running `make-repo`?

## Capability
- Can it generate a repo description for me automatically?
- Can I grant team access without touching the GitHub UI?

## Caveats
- What happens if I forget `--no-submodule` and it converts my directory?
- What are the risks of running `fork-repo` inside a submodule?
- Does it depend on the monorepo's shared shell library?

## Trust
- Does anything get pushed to GitHub before I confirm?
- Does it store or transmit my GitHub credentials?
