# Notifications

Use `UI::ShowNotification` for a toast plus `trace` / `warn` for the log.

```angelscript
void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}
```

Signature: `ShowNotification(title, message)` or
`(title, message, vec4 color, int durationMs)`.

- Title = plugin name so toasts are attributable.
- Errors/warnings also go to the log (`warn`).
- Longer duration for errors (~10–15s). Default is fine for routine info.
- Safe from any callback, including `Render`.

Do not use notifications as the only evidence a map loaded or a task
succeeded — they are user feedback, not a completion gate.

## Sources

- `Notify` / `NotifyError` / `NotifyWarning` — [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Main.as` (same trio in most Max plugins)
