#!/usr/bin/env bash
# markdown_link_extractor.sh - extract links from Markdown source.
#
# Only inline links of the form [text](url) are recognized.  Reference
# definitions, autolinks, and bare URLs are deliberately ignored: supporting
# them would require a full CommonMark parser and a decision about which
# reference syntax to honour, and this library exists to do one thing well.
#
# Exported functions:
#   extract_links <file>
#       Print one link per line as "text<TAB>url".
#       Missing files are a hard error (exit 1).
#
#   count_links <file>
#       Print the number of links found.

set -euo pipefail

# extract_links FILE
#   Emit "text<TAB>url" for every inline Markdown link found in FILE.
#
#   We read the whole file into a bash string rather than streaming line by
#   line because a link may contain a newline inside its text, and because
#   Bash's regex engine is easier to reason about on a single buffer.
#   The regex is deliberately non-greedy for the text and URL parts so that
#   "[a](b) and [c](d)" yields two links, not one.
extract_links() {
    if [[ $# -ne 1 ]]; then
        printf 'usage: extract_links <file>\n' >&2
        return 2
    fi

    local file=$1
    if [[ ! -f $file ]]; then
        printf 'extract_links: no such file: %s\n' "$file" >&2
        return 1
    fi

    local content
    content=$(<"$file")

    # The regex captures the link text (group 1) and the destination (group 2).
    # BASH_REMATCH is used instead of sed/awk because we need to keep both
    # pieces and because coreutils-only environments may lack GNU sed's
    # extended regex flags.
    local regex='\[([^]]*)\]\(([^)]*)\)'
    while [[ $content =~ $regex ]]; do
        printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        content=${content#*"${BASH_REMATCH[0]}"}
    done
}

# count_links FILE
#   Print the number of inline links in FILE.
count_links() {
    if [[ $# -ne 1 ]]; then
        printf 'usage: count_links <file>\n' >&2
        return 2
    fi

    local n=0
    while IFS= read -r _; do
        n=$((n + 1))
    done < <(extract_links "$1")
    printf '%s\n' "$n"
}
