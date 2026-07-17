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
    [[ -f "${FAKE_GH_STATE}" ]]
    ;;
  "repo create")
    git init --bare -q "${FAKE_GH_REMOTE}"
    git remote add origin "${FAKE_GH_REMOTE}"
    branch="$(git branch --show-current)"
    git push -q -u origin "$branch"
    touch "${FAKE_GH_STATE}"
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
  cp "${repo_root}/push-subtrees.sh" "${case_dir}/parent/push-subtrees.sh"
  cp "${repo_root}/pull-subtrees.sh" "${case_dir}/parent/pull-subtrees.sh"
  chmod +x "${case_dir}/parent/push-subtrees.sh" "${case_dir}/parent/pull-subtrees.sh"
  git -C "${case_dir}/parent" add push-subtrees.sh pull-subtrees.sh
  git -C "${case_dir}/parent" commit -qm "add subtree wrappers"
}

run_make_repo() {
  local case_dir="$1"
  shift
  (
    export PATH="${case_dir}/bin:${PATH}"
    export FAKE_GH_STATE="${case_dir}/created"
    export FAKE_GH_REMOTE="${case_dir}/child.git"
    export GIT_ALLOW_PROTOCOL="file"
    cd "${case_dir}/parent/child"
    "$MAKE_REPO" --repo child --description test "$@"
  )
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
  add_subtree_wrappers "$case_dir"
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

test_conflicting_flags_fail() {
  local output
  if output="$("$MAKE_REPO" --subtree --submodule 2>&1 | strip_color)"; then
    fail "conflicting integration flags succeeded"
  fi
  assert_contains "$output" "Conflicting parent integration flags"
}

test_default_is_no_integration
test_subtree_integration
test_subtree_wrapper_registration
test_submodule_integration
test_no_inherit_still_allows_integration
test_yes_dry_run_reports_safe_default
test_conflicting_flags_fail

echo "PASS: make-repo parent integration"
