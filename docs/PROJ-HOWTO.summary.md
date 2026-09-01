# PROJ-HOWTO.summary

Task list for `make-repo`/`fork-repo`. Full guides: [PROJ-HOWTO.md](PROJ-HOWTO.md).

- **Install the tools** — get `make-repo` and `fork-repo` on your `PATH` via `make install`.
- **Create a GitHub repo from the current directory** — turn the directory you're standing in into a pushed GitHub repo, with review before anything is created.
- **Preview a repo creation without creating anything** — see exactly what org/name/visibility/description would be used, with zero side effects.
- **Set org, visibility, description, or team access without the prompt** — script a repo creation end-to-end with flags, no interactive step.
- **Edit an existing repo's settings** — flip visibility, update the description, or grant team access on a repo that's already on GitHub.
- **Fork a repo and wire up remotes** — fork a GitHub repo and end up with correct local `origin`/`upstream` remotes, without manual `git remote` surgery.
- **Bind or swap origin on an existing checkout** — `make-repo --origin` attaches or swaps `origin` (park old as `{owner}-origin`); submodules also update `.gitmodules`.
- **Choose subtree, submodule, or no parent integration** — publish a project directory, then deliberately register it in the parent or leave the parent unchanged. → [howto/avoid-submodule-conversion.md](howto/avoid-submodule-conversion.md)
- **Pin values that beat parent-repo detection** — force an org, prefix, name, description, or visibility even when `make-repo` would otherwise inherit it from a containing repo.
- **Create a repo without inheriting the parent repo's org/visibility** — get a clean-slate org/visibility resolution even when run inside a subdirectory of an existing git repo, e.g. publishing to a personal account from a work monorepo checkout.
