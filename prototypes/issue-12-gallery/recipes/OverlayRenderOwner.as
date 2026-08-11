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

        UI::TextWrapped("Openplanet can call RenderInterface and Render for the same plugin. This recipe shows which callback is allowed to draw the shared window, so its contents appear once instead of twice.");
        UI::Separator();
        UI::Text("Simulated state selected by capture frame:");
        UI::Text("• " + (overlayShown ? "Openplanet overlay is shown" : "Openplanet overlay is hidden"));
        UI::Text("Callback decision:");
        UI::Text("• RenderInterface: " + (renderInterfaceCalled ? "DRAW" : "skip"));
        UI::Text("• Render: " + (renderCalled ? "DRAW" : "skip"));
        UI::Text("Result: " + OwnerForOverlayState(overlayShown) + " owns this surface");
        UI::Text("Shared-window submissions this frame: " + submissions + " (expected 1)");
        UI::ProgressBar(float(submissions), vec2(-1, 0), submissions == 1 ? "PASS: one copy" : "FAIL: duplicate/missing copy");
        UI::TextWrapped("Use frame 0 for overlay shown and frame 120 for overlay hidden. In both states, the result must stay at one submission.");
    }
}
