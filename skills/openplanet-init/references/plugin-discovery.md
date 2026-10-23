# Search existing plugins first

Use this before scaffolding a new plugin or adding a capability not covered by
the initialization brief's previous search. Start with the intended behavior,
target game, common synonyms, and likely dependencies. Search broadly before
narrowing: plugin names alone often do not describe all their features.

## Bundled catalog helper

Run [plugin_catalog.py](../scripts/plugin_catalog.py) with Python 3.10+; it uses
only the standard library and works from an installed skill without this repo.
Resolve the script from this skill's directory, not the target plugin's working
directory. On Windows, `py -3` may replace `python`.

From the skill directory:

```sh
python scripts/plugin_catalog.py search ghost
python scripts/plugin_catalog.py search "racing line"
python scripts/plugin_catalog.py --offline search replay
python scripts/plugin_catalog.py status
```

Searches reuse the same user-level cache across repositories and skill installs.
A fresh cache needs no network request; `--offline` never contacts the API.
`status` is also local-only. Use `--json` before the command for machine-readable
results. Multiple search terms must all match; try synonyms in separate queries.
Inspect plausible matches through the returned site/source links to confirm
features, game support, maintenance status, and integration/license constraints.
Other Python tools can import `load_catalog`, `read_cache`, and `search_plugins`;
importing the module performs no I/O. `read_cache` is always local-only.

The default freshness window is 24 hours. Use `--max-age SECONDS` to change it or
`refresh` to request an explicit change check. A warm cache checks known plugin
versions and discovers new arrivals, then fetches only changed records.
Use `--full-refresh refresh` to force complete metadata reconciliation.
Keep ordinary searches local after fetching the catalog;
avoid forcing a refresh per keyword, installing dependencies just to search,
or fetching every plugin's detail page.

## Cache location and reuse

The platform defaults end in `openplanet/plugin-catalog`:

- Linux/Unix: `$XDG_CACHE_HOME/openplanet/plugin-catalog`, or
  `~/.cache/openplanet/plugin-catalog` when unset.
- macOS: `~/Library/Caches/openplanet/plugin-catalog`.
- Windows: `%LOCALAPPDATA%\openplanet\plugin-catalog`, falling back to
  `%USERPROFILE%\AppData\Local\openplanet\plugin-catalog`.

Pass `--cache-dir PATH` before the command for a shared/custom location.
`status` prints the resolved paths and catalog metadata. Keep the cache outside
plugin source and release packages. Record portable search evidence in the
brief; absolute cache paths belong in private local receipts.

`metadata.json` identifies the content-addressed `catalog-<sha256>.json` file,
source, schema version, completeness/count, and UTC fetch/check times. Data is
validated before the metadata pointer is replaced. Older snapshots remain so
concurrent readers can finish safely; the cache can be removed when no helper
is running. Concurrent refreshes share a lock and reuse the winner's result.
The raw catalog file is a JSON array retaining every plugin record's fields;
metadata also records scope, request counts, and the refresh strategy. The date
of the latest change check is separate from the last full metadata refresh:
checking versions does not make every description newly verified.
`checked_at` is the latest successful refresh, `delta_checked_at` the compact
change check, and `full_checked_at` the last complete metadata reconciliation.
Existing version-1 snapshots are readable and upgrade during the next refresh;
migration alone does not fetch the catalog again.

An unavailable or stale catalog is a discovery limitation. Read the warning and
metadata, retain useful old results, and report what could not be checked.
Failed refreshes enter a 15-minute cooldown (longer when `Retry-After` requires
it), recorded separately from the last good snapshot. `--refresh` explicitly
retries; normal searches avoid repeatedly contacting an unavailable server.
A zero-result text search is not proof that no equivalent exists: broaden terms
and inspect related plugins. Respect an intentional alternative after recording
the relevant overlap.

## API coverage and request budget

The source is
[`https://api.openplanet.dev/plugins?filterBroken=false&page=0`](https://api.openplanet.dev/plugins?filterBroken=false&page=0),
followed by the remaining zero-based pages. The
[official plugin manager](https://github.com/openplanet-nl/plugin-manager/blob/2d36477972e20876cc237608be873e2cf010288a/src/Interface/Tabs/PluginList.as)
uses this pagination; its
[installed-plugin query](https://github.com/openplanet-nl/plugin-manager/blob/2d36477972e20876cc237608be873e2cf010288a/src/Interface/Tabs/Installed.as)
establishes `filterBroken=false`. This includes broken, deprecated, unsigned,
and School entries across games. Preserve those flags when judging candidates.
Signing is not an approval-status field.

The initial full fetch observed 583 entries in 49 pages on 2026-10-23 Sydney
time; a later check that day reported 585. The default filter omitted broken
records. No working bulk endpoint or page-size override was established.
Cold caches therefore fetch every page once. Each request after the first waits
0.5 seconds after the preceding response; requests remain sequential.

For warm caches, the
[PluginManager update check](https://github.com/openplanet-nl/plugin-manager/blob/2d36477972e20876cc237608be873e2cf010288a/src/UpdateCheck.as)
uses `/versions?ids=...`, returning compact `{id, identifier, version}` records.
One live request covered all 583 cached IDs, including sampled broken and
unsigned plugins. Calling `/versions` without IDs returned `[]`; that empty
response is not a global inventory or evidence that the catalog is empty.
The
[newest listing](https://github.com/openplanet-nl/plugin-manager/blob/2d36477972e20876cc237608be873e2cf010288a/src/Interface/Tabs/Newest.as)
discovers additions, and `ids=...` listing requests batch changed records.
Version strings are compared for any difference, including rollback; a newer
semantic version is not required for discovery metadata to need refreshing.

Normal warm checks reuse unchanged records. Full metadata is reconciled every
seven days or with `--full-refresh`. Version checks cannot detect every change
to descriptions, source links, flags, or other metadata without a version bump;
the periodic reconciliation bounds that gap. The list already supplies full
descriptions, short descriptions, authors, games, and source links without
detail-page fan-out. It has no semantic category tags. Sampled responses supplied
no HTTP validators; real validators, when present, apply to their exact page.

At the observed size, an unchanged warm check needs two requests: one compact
version check for known IDs and one newest page. Changed IDs usually add one
batched listing request; larger changes or ID lists require more batches/pages.
Discovery scans the complete boundary page, including creation-time ties, rather
than stopping at the first known item. Result counts must agree with the global
listing. Missing version rows require targeted confirmation; an empty response
must never wipe a populated cache. Ambiguous counts, malformed data, or exceeded
delta limits preserve the old snapshot and suggest `--full-refresh`, instead of
silently starting a large crawl.

“Complete” means all records exposed by this public endpoint, with broken
filtering disabled. It does not cover private/unpublished, external-only, or
local-only plugins, historical versions, or full source/license contents.
Compare page metadata, unique IDs, and the final count before accepting a
refresh; inconsistent or partial pages must leave the previous snapshot intact.
The API offers no transactional snapshot guarantee while pages are fetched.
Incremental checks are scoped to known IDs and a recent creation prefix; count
equality cannot prove membership under equal-size churn or backdated entries.
The weekly full reconciliation covers those limitations as well as metadata
edits that retain the same version.

## Record the decision

In the tracked initialization brief, record search terms, catalog check date,
coverage/freshness limitations, linked candidates, and the concrete reason to
reuse, extend, or build separately. Reusing a library and creating a new UI can
both be appropriate. A plugin already implementing the feature is a candidate
to use or extend; its existence is not an automatic prohibition on alternatives.

## Runnable evidence

```sh
python scripts/plugin_catalog.py demo
```

The isolated demo exercises local discovery without contacting Openplanet or
changing the normal user cache. It prints request counts for a synthetic cold
fetch, fresh read, unchanged check, one older plugin's update, and explicit full
reconciliation. For a live check, search once, run `status`, then
repeat searches with `--offline` and verify the catalog check date stays the
same. Repository maintainers can run `python tests/test_plugin_catalog.py -v`
from the repository root for deterministic transport/cache/failure tests.

An in-game `Skillpack Demos` window and Openplanet compilation are not applicable:
this helper runs in the host Python interpreter, has no AngelScript or game
state, and is directly observable through its CLI, metadata, and request tests.
