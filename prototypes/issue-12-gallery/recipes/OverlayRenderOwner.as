namespace RecipeOverlayRenderOwner {
    string OwnerForOverlayState(bool overlayShown) {
        return overlayShown ? "RenderInterface" : "Render";
    }

    int SubmissionCount(bool overlayShown, bool renderInterfaceCalled, bool renderCalled) {
        int submissions = 0;
        if (overlayShown && renderInterfaceCalled) submissions++;
        if (!overlayShown && renderCalled) submissions++;
        return submissions;
    }

    void DrawPanel(int captureFrame) {
        bool overlayShown = captureFrame < 120;
        bool renderInterfaceCalled = overlayShown;
        bool renderCalled = !overlayShown;
        int submissions = SubmissionCount(overlayShown, renderInterfaceCalled, renderCalled);

        UI::TextWrapped("One callback owns the surface for each overlay state; IDs do not excuse duplicate submission.");
        UI::Text("Simulated overlay state: " + (overlayShown ? "shown" : "hidden"));
        UI::Text("Authoritative owner: " + OwnerForOverlayState(overlayShown));
        UI::Text("SubmissionCount = " + submissions);
        UI::ProgressBar(float(submissions), vec2(-1, 0), submissions == 1 ? "exactly one owner" : "ownership error");
    }
}
