# Openplanet policy snapshot

**Openplanet rejects plugins whose code is mostly AI generated** from its website
and plugin manager. Programming experience, directing the LLM, successful
in-game testing, and token spend do not create exceptions. Other AI use must be
disclosed during review; AI-generated plugin thumbnails are prohibited.

The [official Plugin terms of service](https://openplanet.dev/docs/plugin-tos)
remain authoritative. These files preserve a dated copy for offline use:

- [Original HTML response](openplanet-plugin-tos.html): the complete fetched page,
  saved byte for byte, including site navigation and the page-update stamp.
- [Readable policy text](openplanet-plugin-tos.txt): the complete policy body's
  wording, from its title through the final Usage paragraph. HTML markup is
  removed and block spacing normalized; no policy text is paraphrased or omitted.
- [Policy research brief](../research/issue-8-openplanet-store-policy.md): the
  skillpack's interpretation and development/publication boundaries.

The snapshots reproduce Openplanet's text; the repository's CC0/Unlicense
dedication does not assert a right to relicense that third-party material.
Keep commentary and repository guidance in Markdown, outside the snapshots.

## Retrieval record

| Field | Value |
| --- | --- |
| Source | https://openplanet.dev/docs/plugin-tos |
| Retrieved (UTC) | 2026-11-04T15:31:15Z |
| Upstream page updated | Tue, 03 Nov 2026 16:30:13 +0100 |
| Upstream author | Miss |
| Fetch | Public unauthenticated HTTPS GET; HTTP 200; UTF-8 HTML |
| HTML SHA-256 | `ccf7f34e42464f953c450524d375e926a6b7caa136fe5131157b954a3c9f15f5` |
| Text SHA-256 | `4060165de815498f6ea80d85c8deabd0bbf91de7330869e89c1ffa37ec255b52` |

## Refresh when the terms change

Recheck the live terms before preparing a submission and whenever an upstream
policy update is reported. This is a manual refresh; no scheduled check is
configured. Run these commands from the repository root:

```sh
curl --fail --location --silent --show-error \
  --output /tmp/openplanet-plugin-tos.current.html \
  https://openplanet.dev/docs/plugin-tos
diff -u docs/policies/openplanet-plugin-tos.html /tmp/openplanet-plugin-tos.current.html
```

`diff` returns 1 when files differ. Review the policy body and the absolute
`Page updated` timestamp in the HTML; navigation and relative-time labels can
change without a policy change. Confirm the response contains the actual terms
rather than an error or challenge page before replacing anything.

1. Copy the successful response unchanged to `openplanet-plugin-tos.html` in this
   directory. Keep response headers, including any session cookies, out of the
   repository.
2. Refresh `openplanet-plugin-tos.txt` from the policy body's visible text,
   preserving every heading, list item, paragraph, punctuation mark, and word.
   Exclude navigation, footer, and the separate update stamp. Compare the whole
   text with the HTML body, including Rules, AI policy, and Usage.
3. Update this retrieval record with the actual UTC retrieval time, upstream
   absolute update stamp/author, and both new hashes. Retain changes through Git
   history; do not edit an older upstream statement inside a snapshot.
4. Reconcile changed rules with the README warning, specification, initialization
   policy/brief, development guidance, and policy research brief. Preserve the
   dates of sources that were not rechecked. Run the quick validation gate.

```sh
sha256sum docs/policies/openplanet-plugin-tos.html docs/policies/openplanet-plugin-tos.txt
PYTHONDONTWRITEBYTECODE=1 python scripts/validate.py --profile quick
```
