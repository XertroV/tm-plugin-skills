namespace RecipeThemeTable {
    int styleDepth = 0;

    int StyleDepthAfterBalancedOperations(int initialDepth = 0) {
        int depth = initialDepth;
        depth++;
        depth--;
        return depth;
    }

    void DrawPanel(int captureFrame) {
        UI::TextWrapped("This recipe uses ordinary widgets and inherits the active Openplanet theme.");
        if (UI::BeginTable("theme-table", 2, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Property");
            UI::TableSetupColumn("Value");
            UI::TableHeadersRow();
            UI::TableNextRow();
            UI::TableNextColumn(); UI::Text("Capture frame");
            UI::TableNextColumn(); UI::Text(tostring(captureFrame));
            UI::TableNextRow();
            UI::TableNextColumn(); UI::Text("Theme source");
            UI::TableNextColumn(); UI::Text("Active Openplanet theme");
            UI::EndTable();
        }
        UI::Text("style-depth = " + styleDepth);
    }
}
