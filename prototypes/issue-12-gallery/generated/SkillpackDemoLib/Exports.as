namespace SkillpackDemoLib {
    float ClampUnit(float value) { return Math::Clamp(value, 0.0f, 1.0f); }
    float PhaseFromFrame(int frame, int maxFrame) {
        if (maxFrame <= 0) return 0.0f;
        return ClampUnit(float(frame) / float(maxFrame));
    }
}
