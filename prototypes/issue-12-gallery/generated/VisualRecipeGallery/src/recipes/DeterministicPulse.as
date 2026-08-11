// GENERATED COPY sha256=0662ec64e68f728e54fca6fa2f0b8027338b5f55c24f6cbc56baa07f0054c5dd source=recipes/DeterministicPulse.as
namespace RecipeDeterministicPulse {
    int lastCaptureFrame = 0;

    float Phase(int captureFrame) {
        int clamped = Math::Clamp(captureFrame, 0, 120);
        return float(clamped) / 120.0;
    }

    void DrawPanel(int captureFrame) {
        lastCaptureFrame = captureFrame;
        float phase = Phase(captureFrame);
        UI::Text("animation-state frame = " + lastCaptureFrame);
        UI::ProgressBar(phase, vec2(-1, 0), Text::Format("phase %.3f", phase));
        UI::TextWrapped("The gallery owns the frame. No wall-clock time participates in screenshot state.");
    }
}
