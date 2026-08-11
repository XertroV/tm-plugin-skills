// GENERATED COPY sha256=b3805160658a4731656ea85d96c134be270b205a5fcea4526f9526f3f11019e8 source=recipes/NvgScissor.as
namespace RecipeNvgScissor {
    int scissorDepth = 0;

    int ScissorDepthAfterBalancedOperations(int initialDepth = 0) {
        int depth = initialDepth;
        depth++;
        depth--;
        return depth;
    }

    void DrawCanvas(int captureFrame) {
        vec2 topLeft = vec2(80, 140);
        vec2 size = vec2(220, 100);
        scissorDepth++;
        nvg::Scissor(topLeft.x, topLeft.y, size.x, size.y);
        nvg::BeginPath();
        nvg::Circle(topLeft + vec2(size.x, size.y) * 0.5, 82.0);
        nvg::FillColor(vec4(0.1, 0.8, 0.9, 0.75));
        nvg::Fill();
        nvg::ResetScissor();
        scissorDepth--;
        nvg::BeginPath();
        nvg::Rect(topLeft, size);
        nvg::StrokeColor(vec4(1));
        nvg::StrokeWidth(2.0);
        nvg::Stroke();
    }
}
