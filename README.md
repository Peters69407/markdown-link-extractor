# markdown-link-extractor

Pulls all inline Markdown links from a file and prints each as a tab-separated
`text<TAB>url` pair.

```bash
source markdown_link_extractor.sh

printf 'See [docs](https://example.org/docs).\n' > page.md
extract_links page.md
# docs	https://example.org/docs
count_links page.md
# 1
```

## Why this exists

Markdown has several ways to write a link. This library deliberately supports
exactly one of them: the inline form `[text](url)`. Reference-style links
(`[text][id]` plus a `[id]: url` definition), autolinks (`<https://...>`), and
bare URLs are not recognized. A full parser would need to track reference
definitions across the document and decide which of several CommonMark
ambiguities to follow; that is a different, larger problem. The trade-off here
is coverage for predictability: the output is exactly the set of substrings
that match the inline pattern, in document order.

## The awkward edge

The link text and the destination may themselves contain spaces, and the
destination may contain parentheses as long as they are balanced in the
simple sense of not containing a closing paren. The extractor stops at the
first `)` it sees. If you need URLs with unbalanced parentheses, this is not
the tool for you.

## API

- `extract_links <file>` — print one `text<TAB>url` line per inline link.
  Returns 1 if the file does not exist, 2 on a usage error.
- `count_links <file>` — print the number of inline links found.
