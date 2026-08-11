// GENERATED COPY sha256=cf595a8e5ec0056c149df54bfdcb847a2404aa97ca81ebc3e47e1a88c5dfd99d source=recipes/DeterministicPulse.as
namespace RecipeDeterministicPulse {
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        return SkillpackDemoLib::PhaseFromFrame(captureFrame, 120);
    }

    void DrawPanel(int captureFrame) {
        lastCaptureFrame = captureFrame;
        float phase = Phase(captureFrame);
        UI::Text("animation-state frame = " + lastCaptureFrame);
        UI::ProgressBar(phase, vec2(-1, 0), Text::Format("phase %.3f", phase));
        UI::TextWrapped("The gallery owns the frame. No wall-clock time participates in screenshot state.");
    }
}
