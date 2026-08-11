namespace RecipeStableWidgetIds {
    int primaryClicks = 0;

    string ButtonId(const string &in visibleLabel, const string &in stableKey) {
        return "###stable-widget-" + stableKey;
    }

    void DrawPanel(int captureFrame) {
        bool alternateLabel = captureFrame >= 60;
        string primaryLabel = alternateLabel ? "Run again" : "Run";
        string primaryId = ButtonId(primaryLabel, "primary-action");
        string secondaryId = ButtonId("Run", "secondary-action");

        UI::TextWrapped("Visible labels may change while explicit IDs preserve widget identity.");
        if (UI::Button(primaryLabel + primaryId)) primaryClicks++;
        UI::SameLine();
        if (UI::Button("Run" + secondaryId)) primaryClicks += 10;
        UI::Text("Primary visible label: " + primaryLabel);
        UI::Text("Primary ID: " + primaryId);
        UI::Text("Secondary ID: " + secondaryId);
        UI::Text("Deterministic frame: " + captureFrame);
        UI::Text("Live click score: " + primaryClicks);
    }
}
