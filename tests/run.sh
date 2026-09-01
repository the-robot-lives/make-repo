#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAKE_REPO="${SCRIPT_DIR}/bin/make-repo"
TEST_ROOT="$(mktemp -d /tmp/make-repo-tests.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

export GIT_AUTHOR_NAME="make-repo test"
export GIT_AUTHOR_EMAIL="make-repo@example.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_ALLOW_PROTOCOL="file"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

strip_color() {
  sed $'s/\033\[[0-9;]*m//g'
}

make_fake_gh() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat >"${bin_dir}/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-} ${2:-}" in
  "auth status")
    exit 0
    ;;
  "repo view")
    slug="${3:-}"
    if [[ "$slug" == "owner/parent" ]]; then
      [[ "$*" == *"--json visibility"* ]] && printf 'PRIVATE\n'
      exit 0
    fi
    if [[ -n "${FAKE_GH_EXISTS:-}" && -f "${FAKE_GH_EXISTS}" ]]; then
      [[ "$*" == *"--json visibility"* ]] && printf 'PRIVATE\n'
      [[ "$*" == *"--json description"* ]] && printf '\n'
      exit 0
    fi
    [[ -f "${FAKE_GH_STATE}" ]]
    ;;
  "repo create")
    git init --bare -q "${FAKE_GH_REMOTE}"
    if [[ "$*" == *"--source"* ]]; then
      if git remote get-url origin >/dev/null 2>&1; then
        git remote set-url origin "${FAKE_GH_REMOTE}"
      else
        git remote add origin "${FAKE_GH_REMOTE}"
      fi
      branch="$(git branch --show-current)"
      git push -q -u origin "$branch"
    fi
    touch "${FAKE_GH_STATE}"
    ;;
  "repo edit")
    exit 0
    ;;
  *)
    echo "unexpected fake gh invocation: $*" >&2
    exit 2
    ;;
esac
GH
  chmod +x "${bin_dir}/gh"
}

make_parent() {
  local case_dir="$1"
  mkdir -p "${case_dir}/parent/child" "${case_dir}/bin"
  git -C "${case_dir}/parent" init -q
  git -C "${case_dir}/parent" config user.name "$GIT_AUTHOR_NAME"
  git -C "${case_dir}/parent" config user.email "$GIT_AUTHOR_EMAIL"
  git -C "${case_dir}/parent" config protocol.file.allow always
  printf 'parent\n' >"${case_dir}/parent/README.md"
  printf 'child\n' >"${case_dir}/parent/child/README.md"
  git -C "${case_dir}/parent" add README.md
  git -C "${case_dir}/parent" commit -qm "parent initial"
  git -C "${case_dir}/parent" remote add origin git@github.com:owner/parent.git
  make_fake_gh "${case_dir}/bin"
}

add_subtree_wrappers() {
  local case_dir="$1"
  local repo_root
  repo_root="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
  if [[ ! -f "${repo_root}/push-subtrees.sh" || ! -f "${repo_root}/pull-subtrees.sh" ]]; then
    echo "SKIP: subtree wrappers not at ${repo_root}"
    return 1
  fi
  cp "${repo_root}/push-subtrees.sh" "${case_dir}/parent/push-subtrees.sh"
  cp "${repo_root}/pull-subtrees.sh" "${case_dir}/parent/pull-subtrees.sh"
  chmod +x "${case_dir}/parent/push-subtrees.sh" "${case_dir}/parent/pull-subtrees.sh"
  git -C "${case_dir}/parent" add push-subtrees.sh pull-subtrees.sh
  git -C "${case_dir}/parent" commit -qm "add subtree wrappers"
}

run_make_repo_in() {
  local case_dir="$1"
  local cwd="$2"
  shift 2
  (
    export PATH="${case_dir}/bin:${PATH}"
    export FAKE_GH_STATE="${case_dir}/created"
    export FAKE_GH_REMOTE="${case_dir}/child.git"
    export FAKE_GH_EXISTS="${FAKE_GH_EXISTS:-}"
    export GIT_ALLOW_PROTOCOL="file"
    export GIT_SSH_COMMAND="false"
    export GIT_TERMINAL_PROMPT=0
    cd "$cwd"
    "$BASH" "$MAKE_REPO" --org owner --repo child --description test "$@"
  )
}

run_make_repo() {
  local case_dir="$1"
  shift
  run_make_repo_in "$case_dir" "${case_dir}/parent/child" "$@"
}

init_child_repo() {
  local case_dir="$1"
  git -C "${case_dir}/parent/child" init -q
  git -C "${case_dir}/parent/child" config user.name "$GIT_AUTHOR_NAME"
  git -C "${case_dir}/parent/child" config user.email "$GIT_AUTHOR_EMAIL"
  git -C "${case_dir}/parent/child" add README.md
  git -C "${case_dir}/parent/child" commit -qm "child initial"
}

origin_url() {
  git -C "$1" remote get-url origin 2>/dev/null || true
}

test_default_is_no_integration() {
  local case_dir="${TEST_ROOT}/default"
  local output
  make_parent "$case_dir"
  output="$(printf 'y\n\n' | run_make_repo "$case_dir" | strip_color)"

  assert_contains "$output" "Integrate with Parent Repo?"
  assert_contains "$output" "[1] No"
  assert_contains "$output" "[2] Subtree"
  assert_contains "$output" "[3] Submodule"
  assert_contains "$output" "Parent repo left unchanged."
  [[ -d "${case_dir}/parent/child/.git" ]] || fail "default choice removed child .git"
  [[ ! -e "${case_dir}/parent/.gitmodules" ]] || fail "default choice created .gitmodules"
}

test_subtree_integration() {
  local case_dir="${TEST_ROOT}/subtree"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --yes --subtree | strip_color)"

  assert_contains "$output" "Subtree registered"
  assert_contains "$output" "git subtree pull --prefix=child"
  assert_contains "$output" "git subtree push --prefix=child"
  assert_contains "$output" "commands were printed for manual placement"
  [[ ! -e "${case_dir}/parent/child/.git" ]] || fail "subtree retained nested .git"
  git -C "${case_dir}/parent" log -1 --format=%B | grep -q '^git-subtree-dir: child$' \
    || fail "subtree commit is missing git-subtree-dir"
  git -C "${case_dir}/parent" log -1 --format=%B | grep -q '^git-subtree-split: ' \
    || fail "subtree commit is missing git-subtree-split"
  [[ "$(git -C "${case_dir}/parent" show HEAD:child/README.md)" == "child" ]] \
    || fail "subtree content was not committed in parent"
}

test_subtree_wrapper_registration() {
  local case_dir="${TEST_ROOT}/subtree-wrappers"
  local output list_output
  make_parent "$case_dir"
  if ! add_subtree_wrappers "$case_dir"; then
    return 0
  fi
  output="$(run_make_repo "$case_dir" --yes --subtree | strip_color)"

  assert_contains "$output" "Parent remote configured: child"
  assert_contains "$output" "Wrapper registry updated: child|child|"
  assert_contains "$output" "pull-subtrees.sh uses the same registry"
  grep -qE '^  "child\|child\|[^|"]+"$' "${case_dir}/parent/push-subtrees.sh" \
    || fail "wrapper registry entry was not appended"
  [[ "$(git -C "${case_dir}/parent" remote get-url child)" == "${case_dir}/child.git" ]] \
    || fail "parent subtree remote was not configured"

  list_output="$(cd "${case_dir}/parent" && ./push-subtrees.sh child --list)"
  [[ "$list_output" == *"child"* ]] || fail "push wrapper cannot resolve appended subtree"
  list_output="$(cd "${case_dir}/parent" && ./pull-subtrees.sh child --list)"
  [[ "$list_output" == *"child"* ]] || fail "pull wrapper cannot resolve appended subtree"
}

test_submodule_integration() {
  local case_dir="${TEST_ROOT}/submodule"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --yes --submodule | strip_color)"

  assert_contains "$output" "Submodule registered"
  [[ -f "${case_dir}/parent/.gitmodules" ]] || fail "submodule did not create .gitmodules"
  git -C "${case_dir}/parent" config -f .gitmodules --get-regexp '^submodule\..*\.path$' \
    | grep -q ' child$' || fail "submodule path was not registered"
  [[ -f "${case_dir}/parent/child/.git" ]] || fail "submodule checkout has no .git file"
}

test_no_inherit_still_allows_integration() {
  local case_dir="${TEST_ROOT}/no-inherit"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --yes --no-inherit --subtree | strip_color)"

  assert_contains "$output" "Subtree registered"
  [[ ! -e "${case_dir}/parent/child/.git" ]] || fail "--no-inherit prevented subtree conversion"
}

test_yes_dry_run_reports_safe_default() {
  local case_dir="${TEST_ROOT}/dry-run"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --yes --dry-run | strip_color)"

  assert_contains "$output" "Parent:      no integration (--yes default)"
  [[ ! -e "${case_dir}/created" ]] || fail "dry run created a repository"
}

test_headless_flag_sets_org() {
  local case_dir="${TEST_ROOT}/headless"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --org my-org --headless --dry-run | strip_color)"

  assert_contains "$output" "Org:         my-org"
  assert_contains "$output" "Parent:      no integration (--yes default)"
  [[ ! -e "${case_dir}/created" ]] || fail "dry run created a repository"
}

test_conflicting_flags_fail() {
  local output
  if output="$("$MAKE_REPO" --subtree --submodule 2>&1 | strip_color)"; then
    fail "conflicting integration flags succeeded"
  fi
  assert_contains "$output" "Conflicting parent integration flags"
}

test_origin_on_non_git_creates() {
  local case_dir="${TEST_ROOT}/origin-nongit"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --origin --yes | strip_color)"

  assert_contains "$output" "Repo created"
  [[ -d "${case_dir}/parent/child/.git" ]] || fail "--origin on non-git did not init a repo"
  [[ -n "$(origin_url "${case_dir}/parent/child")" ]] || fail "--origin on non-git left origin unset"
  [[ ! -e "${case_dir}/parent/.gitmodules" ]] || fail "--origin created .gitmodules"
}

test_origin_add_on_existing_git() {
  local case_dir="${TEST_ROOT}/origin-add"
  local output head_before head_after
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  head_before="$(git -C "${case_dir}/parent/child" rev-parse HEAD)"
  output="$(run_make_repo "$case_dir" --origin --yes | strip_color)"

  head_after="$(git -C "${case_dir}/parent/child" rev-parse HEAD)"
  [[ "$head_before" == "$head_after" ]] || fail "--origin re-initialized an existing repo"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "--origin did not add github origin"
  [[ ! -e "${case_dir}/parent/.gitmodules" ]] || fail "--origin add created .gitmodules"
  assert_contains "$output" "origin → git@github.com:owner/child.git"
}

test_origin_yes_without_swap_refuses() {
  local case_dir="${TEST_ROOT}/origin-noswap"
  local output=""
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  if output="$(run_make_repo "$case_dir" --origin --yes 2>&1 | strip_color)"; then
    fail "--origin --yes swapped origin without --swap-origin"
  fi
  assert_contains "$output" "--swap-origin"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/old.git" ]] \
    || fail "origin was mutated without --swap-origin"
  [[ -z "$(git -C "${case_dir}/parent/child" remote get-url owner-origin 2>/dev/null || true)" ]] \
    || fail "parked remote was created without --swap-origin"
}

test_origin_swap() {
  local case_dir="${TEST_ROOT}/origin-swap"
  local output
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  output="$(run_make_repo "$case_dir" --origin --yes --swap-origin | strip_color)"

  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "swap did not set new origin"
  [[ "$(git -C "${case_dir}/parent/child" remote get-url owner-origin)" == "git@github.com:owner/old.git" ]] \
    || fail "swap did not park old origin as owner-origin"
  assert_contains "$output" "Renamed origin → owner-origin"
}

test_origin_swap_declined() {
  local case_dir="${TEST_ROOT}/origin-swap-no"
  local output=""
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  if output="$(printf 'y\nn\n' | run_make_repo "$case_dir" --origin 2>&1 | strip_color)"; then
    fail "declined swap exited 0"
  fi
  assert_contains "$output" "origin unchanged"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/old.git" ]] \
    || fail "declined swap still mutated origin"
}

test_origin_already_matches() {
  local case_dir="${TEST_ROOT}/origin-match"
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/child.git
  run_make_repo "$case_dir" --origin --yes >/dev/null
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "matching origin was rewritten"
  [[ -z "$(git -C "${case_dir}/parent/child" remote get-url owner-origin 2>/dev/null || true)" ]] \
    || fail "matching origin created a parked remote"
}

test_origin_parked_name_collision() {
  local case_dir="${TEST_ROOT}/origin-collision"
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  git -C "${case_dir}/parent/child" remote add owner-origin git@github.com:someone/else.git
  run_make_repo "$case_dir" --origin --yes --swap-origin >/dev/null
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "collision swap did not set new origin"
  [[ "$(git -C "${case_dir}/parent/child" remote get-url owner-origin)" == "git@github.com:someone/else.git" ]] \
    || fail "collision overwrote existing owner-origin"
  [[ "$(git -C "${case_dir}/parent/child" remote get-url owner-origin-2)" == "git@github.com:owner/old.git" ]] \
    || fail "collision did not park old origin as owner-origin-2"
}

test_origin_attaches_when_github_exists() {
  local case_dir="${TEST_ROOT}/origin-attach"
  local output
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  : >"${case_dir}/exists"
  output="$(FAKE_GH_EXISTS="${case_dir}/exists" run_make_repo "$case_dir" --origin --yes | strip_color)"
  assert_contains "$output" "GitHub repo exists"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "attach did not set origin"
  [[ ! -f "${case_dir}/created" ]] || fail "attach created a GitHub repo"
}

test_origin_submodule_swap_updates_gitmodules() {
  local case_dir="${TEST_ROOT}/origin-submodule"
  local gitdir_before gitdir_after gitlink_before gitlink_after
  make_parent "$case_dir"
  git init --bare -q "${case_dir}/old.git"
  git -C "${case_dir}/parent/child" init -q
  git -C "${case_dir}/parent/child" config user.name "$GIT_AUTHOR_NAME"
  git -C "${case_dir}/parent/child" config user.email "$GIT_AUTHOR_EMAIL"
  git -C "${case_dir}/parent/child" add README.md
  git -C "${case_dir}/parent/child" commit -qm "child initial"
  git -C "${case_dir}/parent/child" branch -M main
  git -C "${case_dir}/parent/child" remote add origin "${case_dir}/old.git"
  git -C "${case_dir}/parent/child" push -q origin main
  mv "${case_dir}/parent/child" "${case_dir}/child.bak"
  git -C "${case_dir}/parent" -c protocol.file.allow=always submodule add -q "${case_dir}/old.git" child
  git -C "${case_dir}/parent" commit -qm "add child submodule"
  rm -rf "${case_dir}/child.bak"

  gitdir_before="$(cat "${case_dir}/parent/child/.git")"
  gitlink_before="$(git -C "${case_dir}/parent" rev-parse HEAD:child)"
  run_make_repo "$case_dir" --origin --yes --swap-origin >/dev/null
  gitdir_after="$(cat "${case_dir}/parent/child/.git")"
  gitlink_after="$(git -C "${case_dir}/parent" rev-parse HEAD:child)"

  [[ -f "${case_dir}/parent/child/.git" ]] || fail "submodule --origin detached .git"
  [[ "$gitdir_before" == "$gitdir_after" ]] || fail "submodule --origin changed gitdir pointer"
  [[ "$gitlink_before" == "$gitlink_after" ]] || fail "submodule --origin changed gitlink SHA"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "submodule origin was not swapped"
  git -C "${case_dir}/parent" config -f .gitmodules --get-regexp '^submodule\..*\.url$' \
    | grep -q 'git@github.com:owner/child.git' \
    || fail "parent .gitmodules url was not updated"
  [[ ! -e "${case_dir}/parent/copy.child" ]] || fail "submodule --origin created convert backup"
}

test_origin_worktree_shares_remote() {
  local case_dir="${TEST_ROOT}/origin-worktree"
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  git -C "${case_dir}/parent/child" worktree add -q "${case_dir}/wt" -b feature
  run_make_repo_in "$case_dir" "${case_dir}/wt" --origin --yes --swap-origin >/dev/null
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/child.git" ]] \
    || fail "worktree swap did not update main checkout origin"
  [[ "$(origin_url "${case_dir}/wt")" == "git@github.com:owner/child.git" ]] \
    || fail "worktree swap did not update worktree origin"
  [[ "$(git -C "${case_dir}/parent/child" remote get-url owner-origin)" == "git@github.com:owner/old.git" ]] \
    || fail "worktree swap did not park origin on the shared config"
}

test_origin_dry_run_is_noop() {
  local case_dir="${TEST_ROOT}/origin-dry"
  local output
  make_parent "$case_dir"
  init_child_repo "$case_dir"
  git -C "${case_dir}/parent/child" remote add origin git@github.com:owner/old.git
  output="$(run_make_repo "$case_dir" --origin --yes --dry-run | strip_color)"
  assert_contains "$output" "Origin plan: swap (park as owner-origin)"
  assert_contains "$output" "owner-origin"
  [[ "$(origin_url "${case_dir}/parent/child")" == "git@github.com:owner/old.git" ]] \
    || fail "--origin --dry-run mutated origin"
  [[ ! -e "${case_dir}/created" ]] || fail "--origin --dry-run created a repository"
}

test_origin_skips_parent_integration_prompt() {
  local case_dir="${TEST_ROOT}/origin-no-integrate"
  local output
  make_parent "$case_dir"
  output="$(run_make_repo "$case_dir" --origin --yes | strip_color)"
  if [[ "$output" == *"Integrate with Parent Repo?"* ]]; then
    fail "--origin prompted for parent integration"
  fi
}

test_existing_github_without_origin_still_dies() {
  local case_dir="${TEST_ROOT}/exists-die"
  local output=""
  make_parent "$case_dir"
  : >"${case_dir}/exists"
  if output="$(FAKE_GH_EXISTS="${case_dir}/exists" run_make_repo "$case_dir" --yes 2>&1 | strip_color)"; then
    fail "existing GitHub repo without --origin succeeded"
  fi
  assert_contains "$output" "already exists on GitHub"
  assert_contains "$output" "--origin"
}

test_default_is_no_integration
test_subtree_integration
test_subtree_wrapper_registration
test_submodule_integration
test_no_inherit_still_allows_integration
test_yes_dry_run_reports_safe_default
test_headless_flag_sets_org
test_conflicting_flags_fail
test_origin_on_non_git_creates
test_origin_add_on_existing_git
test_origin_yes_without_swap_refuses
test_origin_swap
test_origin_swap_declined
test_origin_already_matches
test_origin_parked_name_collision
test_origin_attaches_when_github_exists
test_origin_submodule_swap_updates_gitmodules
test_origin_worktree_shares_remote
test_origin_dry_run_is_noop
test_origin_skips_parent_integration_prompt
test_existing_github_without_origin_still_dies

echo "PASS: make-repo parent integration + origin mode"
