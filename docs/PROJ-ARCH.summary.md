# Architecture Summary

Two-tool Bash CLI package wrapping `gh`: `make-repo` (create/edit GitHub repos) and `fork-repo` (fork + remote rewiring). No k8-lib dependency — portable outside the Noizu monorepo.

**make-repo flow**: Parse CLI flags → detect parent repo context → resolve values through 5-tier precedence (CLI > _OVERRIDE env > parent > base env > defaults) → interactive confirm or `--yes` → create/edit repo → optionally grant team access via gh API.

**fork-repo flow**: Local clone mode (fork cwd's repo, origin→upstream, fork becomes origin) or remote slug mode (`fork-repo org/repo`, optional `--clone`). Target org: `--org` > `GH_FORK_TARGET_ORG_OVERRIDE` > `GH_FORK_TARGET_ORG` > user.

**Components**: CLI parsers, parent repo detector, value resolvers, interactive prompts, repo creator, team granter, edit mode, remote rewirer.

**Install**: `make install` copies both scripts to `~/.local/bin` (symlink-aware skip); compile/test no-ops match monorepo `make install-utilities` convention.

**Design**: Only `gh` + `git` required. Interactive by default, scriptable with `--yes`/`--dry-run`. Parent inheritance reduces boilerplate in monorepo/subtree workflows. `generate_description()` stubbed for future AI descriptions.
