// GENERATED COPY sha256=f89ca34c0c70a23f5ba9af5886b8e05cb3e5925d2f2a3a7754d5e34546d0e40b source=recipes/VisibilitySafeAction.as
namespace RecipeVisibilitySafeAction {
    string InvokeAction(bool drawnThisEpoch, bool force) {
        if (!drawnThisEpoch && !force) {
            return "not_drawn: no mutation; open/draw the component and retry, or use force=true";
        }
        if (force && !drawnThisEpoch) return "ok: forced semantic callback; no physical click claimed";
        return "ok: visible semantic callback";
    }

    int MutationDelta(bool drawnThisEpoch, bool force) {
        return drawnThisEpoch || force ? 1 : 0;
    }

    void DrawPanel(int captureFrame) {
        bool drawnThisEpoch = captureFrame >= 60 && captureFrame < 120;
        bool force = captureFrame >= 120;
        string result = InvokeAction(drawnThisEpoch, force);
        int delta = MutationDelta(drawnThisEpoch, force);

        UI::TextWrapped("Remote actions default to force=false and mutate only after current-epoch draw evidence.");
        UI::Text("drawn this epoch: " + (drawnThisEpoch ? "yes" : "no"));
        UI::Text("force requested: " + (force ? "yes" : "no"));
        UI::TextWrapped("result: " + result);
        UI::Text("mutation delta: " + delta);
    }
}
