// GENERATED COPY sha256=bfd5ca2a09b96d84200029f84f4d0c5cc8cc0eb74ca4d2ab43a61a4f1d84c999 source=recipes/DrawListGradient.as
namespace RecipeDrawListGradient {
    int clipDepth = 0;

    int ClipDepthAfterBalancedOperations(int initialDepth = 0) {
        int depth = initialDepth;
        depth++;
        depth--;
        return depth;
    }

    void DrawPanel(int captureFrame) {
        vec2 pos = UI::GetCursorScreenPos();
        vec2 size = vec2(320, 90);
        auto drawList = UI::GetWindowDrawList();
        clipDepth++;
        drawList.PushClipRect(vec4(pos, size));
        drawList.AddRectFilledMultiColor(vec4(pos, size), vec4(0.1, 0.7, 1, 1), vec4(0.7, 0.2, 1, 1), vec4(0.1, 0.2, 0.5, 1), vec4(1, 0.4, 0.1, 1));
        drawList.PopClipRect();
        clipDepth--;
        UI::Dummy(size);
        UI::Text("clip-depth = " + clipDepth);
    }
}
