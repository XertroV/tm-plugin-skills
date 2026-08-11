// GENERATED prototype shell; do not edit. Canonical implementations live in recipes/*.as.
bool g_windowOpen = true;
int g_selectedRecipe = 7;
int g_captureFrame = 0;
bool g_animationPlaying = true;
uint64 g_lastAnimationTick = 0;
float g_animationFrameCarry = 0.0f;

void RenderMenu() {
    if (UI::BeginMenu("Skillpack Demos")) {
        if (UI::MenuItem("Visual Recipe Gallery PROTOTYPE", "", g_windowOpen)) g_windowOpen = !g_windowOpen;
        UI::EndMenu();
    }
}

void RenderInterface() {
    DrawGalleryWindow();
}

void Render() {
    // RenderInterface owns the normal Openplanet-overlay path. Only use Render for the
    // optional HUD-like path while the overlay is hidden; otherwise the same ImGui window
    // ID is submitted twice and its interior can appear duplicated.
    if (UI::IsOverlayShown()) return;
    DrawGalleryWindow();
}

void DrawGalleryWindow() {
    if (!g_windowOpen) return;
    UI::SetNextWindowSize(780, 560, UI::Cond::FirstUseEver);
    if (UI::Begin("Visual Recipe Gallery PROTOTYPE###skillpack-demo-gallery", g_windowOpen)) DrawGallery();
    UI::End();
}

void DrawGallery() {
    UI::TextWrapped("THROWAWAY / STATIC-ONLY: no recipe shown here is stable until live screenshot gates pass.");
    UI::Separator();
    if (UI::BeginTable("gallery-layout", 2, UI::TableFlags::SizingStretchProp | UI::TableFlags::BordersInnerV)) {
        UI::TableSetupColumn("Navigation", UI::TableColumnFlags::WidthFixed, 230);
        UI::TableSetupColumn("Recipe", UI::TableColumnFlags::WidthStretch);
        UI::TableNextRow();
        UI::TableNextColumn(); DrawNavigation();
        UI::TableNextColumn(); DrawSelectedRecipe();
        UI::EndTable();
    }
}

void DrawNavigation() {
    UI::BeginTabBar("gallery-curation-tabs");
        if (UI::BeginTabItem("Featured")) {
            DrawNavigationForCuration(true);
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Boring")) {
            DrawNavigationForCuration(false);
            UI::EndTabItem();
        }
    UI::EndTabBar();
}

void DrawNavigationForCuration(bool featured) {
    EnsureSelectionMatchesCuration(featured);
    GalleryTier lastTier = GalleryTier::Advanced;
    bool first = true;
    for (uint i = 0; i < g_recipes.Length; i++) {
        auto recipe = g_recipes[i];
        if (recipe.IsFeatured != featured) continue;
        if (first || recipe.Tier != lastTier) {
            UI::SeparatorText(TierName(recipe.Tier));
            lastTier = recipe.Tier; first = false;
        }
        if (UI::Selectable(recipe.Title + "###recipe-" + recipe.Id, int(i) == g_selectedRecipe)) g_selectedRecipe = int(i);
    }
}

void EnsureSelectionMatchesCuration(bool featured) {
    if (g_selectedRecipe >= 0 && g_selectedRecipe < int(g_recipes.Length)
            && g_recipes[g_selectedRecipe].IsFeatured == featured) return;
    for (uint i = 0; i < g_recipes.Length; i++) {
        if (g_recipes[i].IsFeatured == featured) {
            g_selectedRecipe = int(i);
            g_captureFrame = g_recipes[i].CaptureFrames[0];
            g_animationPlaying = true;
            g_lastAnimationTick = 0;
            return;
        }
    }
}

void DrawSelectedRecipe() {
    auto recipe = g_recipes[g_selectedRecipe];
    AdvanceAnimationFrame(recipe);
    UI::Text(recipe.Title);
    UI::TextDisabled(recipe.Id + " · " + recipe.Maturity);
    UI::TextWrapped("Expected: " + recipe.Expected);
    UI::TextWrapped("Provenance: " + recipe.Provenance);
    UI::SetNextItemWidth(260);
    int chosenFrame = UI::SliderInt("Deterministic capture frame", g_captureFrame, 0, 120);
    if (chosenFrame != g_captureFrame) {
        g_captureFrame = chosenFrame;
        g_animationPlaying = false;
    }
    if (recipe.IsAnimated) {
        UI::SameLine();
        if (UI::Button((g_animationPlaying ? "Pause animation" : "Play animation") + "###animation-play-state-" + recipe.Id)) {
            g_animationPlaying = !g_animationPlaying;
            g_lastAnimationTick = 0;
        }
    }
    UI::Text("Matrix frames:"); UI::SameLine();
    for (uint i = 0; i < recipe.CaptureFrames.Length; i++) {
        if (i > 0) UI::SameLine();
        int frame = recipe.CaptureFrames[i];
        if (UI::Button(tostring(frame) + "###capture-frame-" + recipe.Id + "-" + i)) {
            g_captureFrame = frame;
            g_animationPlaying = false;
        }
    }
    UI::SameLine();
    if (UI::Button("Return to frame 0###reset-state-" + recipe.Id)) {
        g_captureFrame = recipe.CaptureFrames[0];
        g_animationPlaying = recipe.IsAnimated;
        g_lastAnimationTick = 0;
    }
    UI::Separator();
    DrawRecipeByIndex(g_selectedRecipe, g_captureFrame);
}

void AdvanceAnimationFrame(RecipeMeta@ recipe) {
    if (!recipe.IsAnimated || !g_animationPlaying) {
        g_lastAnimationTick = 0;
        return;
    }
    uint64 now = Time::Now;
    if (g_lastAnimationTick == 0) {
        g_lastAnimationTick = now;
        return;
    }
    uint64 elapsed = now - g_lastAnimationTick;
    g_lastAnimationTick = now;
    g_animationFrameCarry += float(Math::Min(elapsed, uint64(250))) * 30.0f / 1000.0f;
    int wholeFrames = int(Math::Floor(g_animationFrameCarry));
    if (wholeFrames > 0) {
        g_captureFrame = (g_captureFrame + wholeFrames) % 121;
        g_animationFrameCarry -= float(wholeFrames);
    }
}

string TierName(GalleryTier tier) {
    if (tier == GalleryTier::DefaultImgui) return "1 · Theme-respecting default ImGui";
    if (tier == GalleryTier::Nvg) return "2 · NVG recipes";
    return "3 · Advanced composition (opt-in)";
}
