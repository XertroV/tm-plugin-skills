# Openplanet how-to guides

Common operations. Open the matching file; each is standalone.

The user can overrule a suggested library or API. Snippets are public domain.
Code guides cite the plugin files and public repos the pattern came from.

## Maps and servers

| Need | Guide |
| --- | --- |
| Create or replace dedicated server credentials | [dedicated-server-accounts.md](dedicated-server-accounts.md) |
| Join a club room / server | [join-a-server.md](join-a-server.md) |
| Play a local/URL map (`PlayMap`) | [play-a-map.md](play-a-map.md) |
| Leave a map / return to the main menu | [exit-a-map.md](exit-a-map.md) |

## Game and UI state

| Need | Guide |
| --- | --- |
| Menu vs playground vs editor, UI sequence, map change | [game-state.md](game-state.md) |
| Pause menu (and submenus), return to menu safely | [pause-menu.md](pause-menu.md) |
| Detect and drive `CGameDialogs` | [dialogs.md](dialogs.md) |
| Move/hide/scale stock manialink widgets | [manialink-ui.md](manialink-ui.md) |
| Plugin menu, main menubar, window File/Edit bar | [plugin-menus.md](plugin-menus.md) |

## Network and media

| Need | Guide |
| --- | --- |
| TCP listen / accept / connect | [sockets.md](sockets.md) |
| Download images, cache, draw in ImGui or NVG | [images-and-textures.md](images-and-textures.md) |
| Nadeo task wait + `TaskResult_Release` | [nadeo-tasks.md](nadeo-tasks.md) |

## Ghosts, scores, settings, input

| Need | Guide |
| --- | --- |
| Load, unload, and save ghosts; where files live | [ghosts.md](ghosts.md) |
| A player's record/score on a map | [player-score.md](player-score.md) |
| Spectate a live player or a ghost | [spectating.md](spectating.md) |
| Game / user-profile / hidden camera settings | [game-and-profile-settings.md](game-and-profile-settings.md) |
| Version-gate `Dev::` offsets | [dev-offset-version-gates.md](dev-offset-version-gates.md) |
| Hotkeys, press-to-bind, when to block | [hotkeys.md](hotkeys.md) |
| ImGui / NVG fonts | [fonts.md](fonts.md) |
| Toasts + log | [notifications.md](notifications.md) |
| `IO::FromStorageFolder` / user-game paths | [plugin-storage.md](plugin-storage.md) |
