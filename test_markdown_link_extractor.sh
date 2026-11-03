#!/usr/bin/env bash
# test_markdown_link_extractor.sh - TAP-like tests for the link extractor.
#
# Run with: bash test_markdown_link_extractor.sh
# The script sources the library under test and calls its exported functions.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=markdown_link_extractor.sh
source "$SCRIPT_DIR/markdown_link_extractor.sh"

# assert_eq EXPECTED ACTUAL LABEL
#   Compare two strings and emit a TAP-ish line.  Exits non-zero on the first
#   mismatch so that a broken run is obvious in CI logs.
assert_eq() {
    local expected=$1 actual=$2 label=$3
    if [[ $expected == "$actual" ]]; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label"
        printf '# expected: %q\n' "$expected" >&2
        printf '# actual:   %q\n' "$actual" >&2
        exit 1
    fi
}

# assert_status EXPECTED_STATUS LABEL COMMAND...
#   Run COMMAND and check its exit status.  Used for error paths.
assert_status() {
    local expected=$1 label=$2
    shift 2
    local status=0
    "$@" >/dev/null 2>&1 || status=$?
    if [[ $status -eq $expected ]]; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label"
        printf '# expected status: %s\n' "$expected" >&2
        printf '# actual status:   %s\n' "$status" >&2
        exit 1
    fi
}

# Fixtures are written under a temporary directory so the test suite leaves
# no residue and can run in a read-only source tree.
tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT

# --- happy path ---------------------------------------------------------

cat >"$tmpdir/simple.md" <<'EOF'
See [the docs](https://example.org/docs) and [issues](https://example.org/issues).
EOF

assert_eq $'the docs\thttps://example.org/docs\nissues\thttps://example.org/issues' \
    "$(extract_links "$tmpdir/simple.md")" \
    "extracts two inline links"

assert_eq '2' "$(count_links "$tmpdir/simple.md")" "counts two links"

# --- empty file ---------------------------------------------------------

: >"$tmpdir/empty.md"
assert_eq '' "$(extract_links "$tmpdir/empty.md")" "empty file yields no links"
assert_eq '0' "$(count_links "$tmpdir/empty.md")" "empty file counts zero"

# --- text containing brackets that are not links ------------------------

cat >"$tmpdir/brackets.md" <<'EOF'
This [is not a link] and neither is (this).
But [this is](https://example.org/yes).
EOF

assert_eq $'this is\thttps://example.org/yes' \
    "$(extract_links "$tmpdir/brackets.md")" \
    "ignores bracket pairs without a following paren"

# --- link text and URL may contain spaces -------------------------------

cat >"$tmpdir/spaces.md" <<'EOF'
[two words](https://example.org/a b)
EOF

assert_eq $'two words\thttps://example.org/a b' \
    "$(extract_links "$tmpdir/spaces.md")" \
    "preserves spaces inside text and URL"

# --- multiple links on one line -----------------------------------------

cat >"$tmpdir/multi.md" <<'EOF'
[a](u1) [b](u2) [c](u3)
EOF

assert_eq $'a\tu1\nb\tu2\nc\tu3' \
    "$(extract_links "$tmpdir/multi.md")" \
    "extracts every link on a line"

# --- missing file -------------------------------------------------------

assert_status 1 "missing file is an error" extract_links "$tmpdir/does-not-exist.md"

# --- wrong argument count ------------------------------------------------

assert_status 2 "extract_links rejects zero arguments" extract_links
assert_status 2 "count_links rejects two arguments" count_links a b

printf '1..%d\n' 10
