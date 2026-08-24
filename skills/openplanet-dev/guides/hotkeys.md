# Hotkeys

Use `OnKeyPress` plus a stored `VirtualKey`. Offer a “press to bind”
control. Default to **not** blocking the key.

## Callback

```angelscript
[Setting hidden]
VirtualKey S_Hotkey = VirtualKey::F8;

[Setting hidden]
bool S_HotkeyEnabled = false;

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (!down) return UI::InputBlocking::DoNothing;
    if (rebind) {
        FinishRebind(key);
        return UI::InputBlocking::Block; // only the bind capture
    }
    if (S_HotkeyEnabled && key == S_Hotkey) {
        ToggleFeature();
        return UI::InputBlocking::DoNothing;
    }
    return UI::InputBlocking::DoNothing;
}
```

## Press to bind

```angelscript
bool rebind;
VirtualKey pending;

void DrawBind(const string &in label) {
    UI::Text(label + "  " + tostring(S_Hotkey));
    UI::SameLine();
    if (UI::Button(rebind ? "Press a key…" : "Rebind")) rebind = true;
}

void FinishRebind(VirtualKey key) {
    if (key == VirtualKey::Escape) { rebind = false; return; }
    S_Hotkey = key;
    rebind = false;
}
```

Show “Press a key, Esc to cancel” while `rebind` is true. Store the key in
a `[Setting hidden]`.

## Blocking

`UI::InputBlocking::Block` swallows the key from the game.
`DoNothing` lets it through.

**While the player is driving, do not block keyboard keys.** Blocking a
keypress during KB driving can desync other keys and leave controls stuck
until every key is released — enough to kill a run. Prefer `DoNothing`
for gameplay binds. Block only for the rebind capture, or for keys that
cannot be driving input (and still think twice).

Mouse binds are a different path (`OnMouseButton`); the driving bug is
the keyboard one.

## Sources

- `OnKeyPress` + press-to-bind — [tm-skids-magician](https://github.com/XertroV/tm-skids-magician) `src/Hotkeys.as`
