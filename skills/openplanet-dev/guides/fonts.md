# Fonts

Load once from `Main` (it can stall long enough to hit the script timeout).
Openplanet ships `DroidSans.ttf` and `DroidSansMono.ttf`. Plugin-bundled
`.ttf` files use a path relative to the plugin folder.

## ImGui

```angelscript
UI::Font@ f_Body;
UI::Font@ f_Mono;

void Main() {
    startnew(LoadFonts);
}

void LoadFonts() {
    @f_Body = UI::LoadFont("DroidSans.ttf", 16);
    @f_Mono = UI::LoadFont("DroidSansMono.ttf", 16);
    // plugin file: UI::LoadFont("fonts/MyFont.ttf", 20);
}

void Render() {
    if (f_Body is null) return;
    UI::PushFont(f_Body);
    UI::Text("hello");
    UI::PopFont();
}
```

Use `UI::LoadFont(path, size)` only. The old ranges/fallback overload is
deprecated (Openplanet 1.28). Prefer `UI::PushFont` / `UI::PushFontSize`
over loading many sizes of one face. Balance `PushFont` / `PopFont`.

## NVG

```angelscript
int g_nvgFont = -1;

void LoadFonts() {
    g_nvgFont = nvg::LoadFont("DroidSans.ttf", true, true);
    // or nvg::LoadFont("fonts/Oswald-Regular.ttf");
}

void DrawLabel(const string &in s, vec2 pos) {
    if (g_nvgFont < 0) return;
    nvg::FontFace(g_nvgFont);
    nvg::FontSize(18);
    nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);
    nvg::FillColor(vec4(1, 1, 1, 1));
    nvg::Text(pos, s);
}
```

Keep the font id (`int`) / `UI::Font@` for the plugin lifetime. Loading the
same file at several sizes is normal (one handle per size).

License: bundled fonts you ship need a compatible license; do not vendor a
font you cannot redistribute.

## Sources

- `UI::LoadFont` from `Main` / `startnew` — [tm-green-timer](https://github.com/XertroV/tm-green-timer) `src/Main.as`
- NVG `LoadFont` / `FontFace` — [tm-split-speeds](https://github.com/XertroV/tm-split-speeds) `src/GUI.as`
