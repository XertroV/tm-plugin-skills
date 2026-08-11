# Transport and envelopes

The optional semantic-control bridge is DEV-only, opt-in, loopback-only, fixed-route, bounded length-prefixed JSON. One request receives one response and closes. Probe/document Openplanet integer wire byte order; avoid `Write(string)` plus another length that accidentally double-frames. One writer owns complete framed responses.

Reference success:

```json
{"v":1,"id":"r1","ok":true,"result":{"component":"save","action":"click","performed":true,"forced":false,"render_epoch":42}}
```

Reference failure:

```json
{"v":1,"id":"r1","ok":false,"error":{"code":"not_drawn","message":"Component was not drawn in completed render epoch 42.","next":"Open the panel and retry, or pass force=true."}}
```

Failures use bounded `code`, immediate-cause `message`, and one actionable `next`; never stack traces. Required codes include `not_drawn`, `unknown_component`, `unknown_action`, `invalid_mouse_button`, `busy`, `stale_registration`, `frame_too_large`, `malformed_frame`, and `timeout`. Success must distinguish `performed`, `forced`, `accepted/pending`, and observed result; do not label semantic invocation as physical input.

Test exact framing under fragmented header/body, zero and oversized lengths, malformed JSON, trailing bytes, partial writes, read/write/execution timeouts, duplicate IDs, second-client mutation, stale generations, shutdown during request, and reload. Verify rejected/timeout requests do not mutate state; verify successful requests by state/log/pixels rather than envelope alone.
