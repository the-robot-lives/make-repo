# How to: choose parent integration after creating a repo

**Goal:** publish a project directory inside this monorepo and intentionally keep it unchanged, register it as a subtree, or convert it to a submodule.

**Prereqs:** installed (`make install`); standing inside the project directory you want to publish.

## Why this matters here

This monorepo's convention is **git subtrees, not submodules**. After creating and pushing a repository, `make-repo` asks whether to integrate it into the detected parent as a subtree or submodule. **No integration is the default.**

## Steps

1. For an interactive subtree conversion, run `make-repo` and select option 2 after creation:

   ```bash
   cd projects/some-app
   make-repo
   ```

   ```text
   [1] No (default)
   [2] Subtree
   [3] Submodule
   ```

2. For scripted use, make the choice explicit:

   ```bash
   make-repo --yes --subtree       # register as subtree
   make-repo --yes --submodule     # convert to submodule
   make-repo --yes                 # no parent integration
   ```

3. To document an explicit no-integration choice, use:

   ```bash
   make-repo --no-integration
   ```

   `--no-submodule` remains accepted as a legacy alias.

4. Preview the resolved behavior before creating anything:

   ```bash
   make-repo --subtree --dry-run
   ```

   Look for `Parent: will integrate ... as a subtree` in the output.

**Verify:** for a subtree, `git log -1 --format=%B` at the monorepo root includes `git-subtree-dir` and `git-subtree-split`, and the project directory has no nested `.git`. For a submodule, `.gitmodules` contains the project path and the project has a `.git` file pointing into the parent's `.git/modules/` directory.

## What each choice does

- **No:** leaves the parent working tree unchanged. The new repository remains nested and standalone.
- **Subtree:** removes the child's nested `.git`, stages only the child path in the parent, and creates a commit containing standard `git-subtree-dir` and `git-subtree-split` trailers. Later `git subtree pull`/`push` operations can use that metadata.
- **Submodule:** backs up the directory, replaces it with a gitlink via `git submodule add`, verifies the checkout against the backup, and commits the result.

For every subtree conversion, the tool prints direct `git subtree pull` and `git subtree push` commands that can be saved in parent-repository tooling. If both `push-subtrees.sh` and `pull-subtrees.sh` are already present at the parent root, it additionally configures a parent remote alias and appends the path to the registry in `push-subtrees.sh`. The pull wrapper consumes that same registry via `push-subtrees.sh --list`.

## Gotchas

- **`--yes` is safe by default.** Without `--subtree` or `--submodule`, it performs no parent integration.
- **Subtree is the normal choice in this monorepo.** Choose it explicitly for content under `projects/`, `utilities/`, and other subtree-managed areas.
- **If a submodule conversion already happened:** the tool backs up the original directory to `copy.<dirname>` before the destructive `git submodule add` step and verifies the new checkout against it. Do not delete the backup until the conversion is confirmed.
- **Already a submodule going in?** The tool detaches it to a standalone repository before publishing. The final integration choice determines whether it becomes a subtree, is re-added as a submodule, or remains standalone.
