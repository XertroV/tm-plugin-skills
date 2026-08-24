# Manialink UI

To move, hide, or restyle a stock HUD widget, find it on
`Network.ClientManiaAppPlayground.UILayers` and write the control properties.
This is playground manialink, not your ImGui window.

## Find a control

```angelscript
CGameManialinkFrame@ FindFrame(const string &in childId) {
    auto cmap = GetApp().Network.ClientManiaAppPlayground;
    if (cmap is null) return null;
    for (uint i = 0; i < cmap.UILayers.Length; i++) {
        auto layer = cmap.UILayers[i];
        if (!layer.IsLocalPageScriptRunning || !layer.IsVisible || layer.LocalPage is null) continue;
        auto frame = cast<CGameManialinkFrame>(layer.LocalPage.GetFirstChild(childId));
        if (frame !is null) return frame;
    }
    return null;
}
```

Layers appear a few frames after the playground starts — yield until
`UILayers.Length` is populated, then retry `GetFirstChild` for a short
budget. Drop handles when the map or mode changes (`map.Id.Value` /
`CurGameModeStr`); they go stale.

Example child ids: `Race_LapsCounter`, then inner
`frame-checkpoints-counter` / `label-checkpoints-counter`. Discover others
by walking `LocalPage` in the nod explorer.

## Write properties

```angelscript
void Apply(CGameManialinkFrame@ frame, CGameManialinkFrame@ inner, CGameManialinkLabel@ label) {
    inner.Visible = true;
    inner.RelativePosition_V3 = desiredPos - frame.RelativePosition_V3;
    inner.RelativeScale = 1.0;
    label.HorizontalAlign = CGameManialinkControl::EAlignHorizontal::HCenter;
    label.VerticalAlign = CGameManialinkControl::EAlignVertical::VCenter;
}
```

`Visible`, `RelativePosition_V3`, `RelativeScale`, alignment, and label
text are the usual knobs. The game script may overwrite them each tick —
apply from `Meta::StartWithRunContext(Meta::RunContext::AfterScripts, …)`
so your write wins the frame.

Injected pages (MLHook) are a different layer; use MLHook when you need
new ML, and this walk when you are editing Nadeo’s existing UI.

## Sources

- Layer walk + `GetFirstChild` + `AfterScripts` writes — [tm-customize-cp-counter](https://github.com/XertroV/tm-customize-cp-counter) `src/Monitor.as`
