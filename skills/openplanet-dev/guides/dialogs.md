# Dialogs

Game dialogs live on `app.BasicDialogs` (`CGameDialogs`).
`app.Operation_InProgress` is often **false** while they are showing — poll
`Dialog` yourself.

## Detect

```angelscript
void WatchDialogs() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    CGameDialogs::EDialog last = CGameDialogs::EDialog::None;
    while (true) {
        yield();
        auto bd = app.BasicDialogs;
        if (bd.Dialog != last) {
            last = bd.Dialog;
            // new dialog type
        }
    }
}
```

Useful kinds: `WaitMessage` (download / “Updating data…”), yes/no asks, and
non-basic frames when `bd.Dialogs.CurrentFrame !is null`.

Read copy from the current kind, e.g. `WaitMessage_LabelText` /
`WaitMessage_ButtonText`.

## Drive

Match on type + label, then call the matching accept/cancel:

```angelscript
auto bd = app.BasicDialogs;
if (bd.Dialog == CGameDialogs::EDialog::WaitMessage
    && string(bd.WaitMessage_ButtonText) == "Cancel"
    && string(bd.WaitMessage_LabelText).StartsWith("Downloading ")) {
    bd.WaitMessage_Ok();
    yield();
    yield();
    bd.AskYesNo_Yes(); // confirm cancel
}
```

Two yields between the wait-message OK and the yes/no confirm are required
for that cancel flow.

Non-basic dialogs: walk `bd.Dialogs.CurrentFrame` children (`IdName`,
`CControlLabel.Label`, `CControlButton.OnAction()`). Guard every nod; the
tree changes between game builds.

Stay out of playground/editor if you only mean to cancel menu downloads
(`CurrentPlayground` / `Editor` non-null).

This is automation of the user’s UI. Only dismiss dialogs the task asked
to handle.

## Sources

- `BasicDialogs` / `WaitMessage_Ok` / yes-no confirm — [tm-autocancel-downloads](https://github.com/XertroV/tm-autocancel-downloads) `src/Main.as`
