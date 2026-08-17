# Wait primitives

Reach for `yield()` first. These calls suspend only the current coroutine.
Launch them from `startnew(...)`, never from a render callback.

| Call | Suspends until | Use |
| --- | --- | --- |
| `yield()` | next game tick (`yield(1)`) | default; per-frame work; next-frame plugin/game state |
| `yield(uint frames)` | N frames (framerate-dependent) | settle N frames after reload; animation cadence |
| `sleep(uint64 ms)` | wall-clock time (cooperative) | socket poll, backoff |
| `Dev::Sleep(uint ms)` | **blocks the main thread** | not normal plugin code |

Official `OpenplanetCore.json` details:

- `yield()` is `yield(1)` and resumes on the next game tick.
- `yield(0)` is a no-op; it does not yield.
- `yield(n)` is framerate-dependent; use `sleep()` for wall-clock time.
- `sleep()` yields the current coroutine. `sleep(0)` yields exactly one frame
  (backwards compatibility).
- `Dev::Sleep` has no yield description. It freezes the game and render.
  Leave it for a deliberate, named debug freeze only.

After a queued unload/reload, plugin handles are invalid on the next frame:
`yield()` then re-resolve by ID. Waiting for compile or log evidence across
that boundary can need `yield(n)` settle frames. `sleep()` is the wrong unit;
`Dev::Sleep` is forbidden.
