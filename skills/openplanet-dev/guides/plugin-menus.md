# Plugin menus

Three menu surfaces, three callbacks. Use a checked `MenuItem` that shares
one `bool` with the window close button.

## Plugins menu (`RenderMenu`)

Openplanet → Plugins → your item.

```angelscript
[Setting hidden]
bool ShowWindow = false;

void RenderMenu() {
    if (UI::MenuItem("\\$3f3" + Icons::Clock + "\\$z My Plugin", "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}
```

The third argument is the check mark. The same `ShowWindow` goes to
`UI::Begin("title", ShowWindow)` so the window X stays in sync.

Submenus:

```angelscript
void RenderMenu() {
    if (UI::BeginMenu("My Plugin")) {
        if (UI::MenuItem("Open window", "", ShowWindow)) ShowWindow = !ShowWindow;
        UI::EndMenu();
    }
}
```

## Main menubar (`RenderMenuMain`)

The top-of-overlay bar (next to Openplanet’s own menus):

```angelscript
void RenderMenuMain() {
    if (!UI::BeginMenu("My Plugin")) return;
    if (UI::MenuItem("Do thing")) startnew(DoThing);
    UI::EndMenu();
}
```

## Window File / Edit bar

Pass `UI::WindowFlags::MenuBar` to `Begin`, then `BeginMenuBar` inside:

```angelscript
if (UI::Begin("My Plugin", ShowWindow, UI::WindowFlags::MenuBar)) {
    if (UI::BeginMenuBar()) {
        if (UI::BeginMenu("File")) {
            if (UI::MenuItem("Close")) ShowWindow = false;
            UI::EndMenu();
        }
        if (UI::BeginMenu("Edit")) {
            if (UI::MenuItem("Reset")) Reset();
            UI::EndMenu();
        }
        UI::EndMenuBar();
    }
}
UI::End();
```

Balance every `BeginMenu` / `BeginMenuBar` on all paths. Keep actions that
yield or load maps in `startnew`, not in the menu callback body.

Skillpack demo plugins register through `SkillpackDemoLib` instead of a
second `RenderMenu` owner — see the develop skill.

## Sources

- `RenderMenu` checked item — [tm-play-map](https://github.com/XertroV/tm-play-map) `src/Main.as`
- `RenderMenuMain` — [tm-archivist](https://github.com/XertroV/tm-archivist) `src/Main.as`
- Window `MenuBar` — same file, `DrawToolbar`
