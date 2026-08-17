# Render and frame performance

Instrument before optimizing. A plugin's `Render()` / `RenderInterface()` /
`Update()` should stay in the **low milliseconds** in steady state. The whole
game frame is ~16 ms at 60 Hz; a plugin that spends 5 ms already owns a third
of it.

Evidence: a tm-agent chat session (201 messages, 2026-08-17) ran ~100 ms/frame
because the header and toolbar each re-serialized the full history and rebuilt
~90 tool schemas. The virtual-scrolled message list was ~0.1–0.7 ms and was
never the problem. Fingerprint + version caches dropped the same session to
~1.8 ms/frame. A synchronous 200-row replay wedged the game ~8 s; applying
~12 rows/frame with `yield()` removed the hang.

`Time::Now` is milliseconds since the game started (`uint64 Time::get_Now()`).

## 1. Rolling per-section profiler

Bracket each render section. Accumulate into **stable** bucket labels. Report
averages every few seconds with `trace()`. Put counts in state, not in the
label — `header` stays one bucket; `header n=90` fragments into a new bucket
every frame.

```angelscript
class RenderProfiler {
    dictionary totals; // label -> int64 ms
    dictionary counts; // label -> int64 n
    uint64 markAt;
    string markLabel;
    uint64 reportedAt;
    bool warmup;

    void BeginFrame() {
        markAt = Time::Now;
        markLabel = "";
    }

    void Mark(const string &in label) {
        uint64 now = Time::Now;
        if (markLabel.Length > 0 && !warmup) {
            int64 total = 0;
            int64 n = 0;
            totals.Get(markLabel, total);
            counts.Get(markLabel, n);
            totals.Set(markLabel, total + int64(now - markAt));
            counts.Set(markLabel, n + 1);
        }
        markAt = now;
        markLabel = label;
    }

    void Reset() {
        totals.DeleteAll();
        counts.DeleteAll();
        reportedAt = Time::Now;
    }

    void MaybeReport() {
        if (Time::Now - reportedAt < 2000) return;
        reportedAt = Time::Now;
        array<string>@ keys = totals.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            int64 total = 0;
            int64 n = 0;
            totals.Get(keys[i], total);
            counts.Get(keys[i], n);
            if (n == 0) continue;
            trace(keys[i] + " avg=" + (total / n) + "ms n=" + n);
        }
    }
}
```

Gate noisy reporting `#if DEV`. Reset after a disruption before trusting the
next average.

## 2. No O(growing-data) work per frame

Two recurring violators:

**Per-frame serialization.** `Json::Write` / `Json::Parse` over all messages,
request-body rebuilds, and token counts are `O(history)`. Compute them behind a
**fingerprint cache** invalidated only on mutation. Watch paired UI sections
(header + toolbar) that each call the same helper — that is 2× the cost.

```angelscript
string g_statsFp;
string g_statsText;

const string@ ContextStats() {
    string fp = HistoryFingerprint(); // generation, length, last-id — not Json::Write
    if (fp != g_statsFp) {
        g_statsFp = fp;
        g_statsText = Json::Write(BuildStatsTree());
    }
    return g_statsText;
}
```

**Registry rebuilds.** Tool lists and schema tables that change only on
register/unregister use a **version-counter cache**. A hit is cheap even across
an ordinary-export / import boundary.

```angelscript
uint g_toolsVersion;
uint g_toolsCachedVersion;
Json::Value@ g_toolsCached;
uint g_toolsHits;
uint g_toolsMisses;

void RegisterTool() { g_toolsVersion++; }

Json::Value@ ToolSchema() {
    if (g_toolsCached is null || g_toolsCachedVersion != g_toolsVersion) {
        @g_toolsCached = RebuildToolSchema();
        g_toolsCachedVersion = g_toolsVersion;
        g_toolsMisses++;
    } else {
        g_toolsHits++;
    }
    return g_toolsCached;
}
```

Expose hit/miss counters. "Is the cache hitting?" is a lookup, not a guess.

## 3. Steady-state vs warmup

A `tail` of profiler output right after fixture load, window open, or texture
decode captures a one-time spike (hundreds of ms) and makes healthy code look
broken — or hides a real steady-state leak.

- set `warmup = true` across the disruption, then `Reset()` and clear the flag
- report only settled frames
- correlate a failing perf/test timestamp with the deploy/load timestamp
  before debugging; a stale build can fail on already-fixed code

## 4. Frame-batch bulk work

Any bulk job that would take more than a few milliseconds in `Update` or
`Render*` moves to `startnew(...)` and applies a bounded chunk per frame, then
`yield()`. Same total work, no visible hang. Use the [wait
primitives](wait-primitives.md): `yield()` is the per-frame wait; do not
`Dev::Sleep`.

```angelscript
void ReplayAll(array<string>@ rows) {
    startnew(CoroutineFuncUserdata(ReplayChunked), rows);
}

void ReplayChunked(ref@ data) {
    array<string>@ rows = cast<array<string>@>(data);
    if (rows is null) return;
    for (uint i = 0; i < rows.Length; i++) {
        ApplyRow(rows[i]);
        if (i % 12 == 11) yield();
    }
}
```

Revalidate generation/session after each yield. Cancel when the plugin unloads
or the fixture is replaced.

## 5. Measure against a real fixture

A near-empty session understates cost (a 2.3 ms "fix" was not the 201-message
reality). Keep a DEV-only replay that incrementally applies a real transcript
into live state.

```angelscript
#if DEV
void ReplaySessionFixture(const string &in path) {
    startnew(CoroutineFuncUserdataString(ReplayFixtureFile), path);
}
#endif
```

A `#if DEV` symbol referenced from an ungated file fails a non-DEV / release
compile. Gate the call sites and the helper's file, not only the definition.

Reviewed N/A for a bundled demo: this is a measurement discipline, not a visual
recipe. A `Dev::Sleep` or 8 s hang is not a gallery sample.
