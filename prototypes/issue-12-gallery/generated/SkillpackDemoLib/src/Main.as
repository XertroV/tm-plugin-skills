namespace SkillpackDemoLib {
    string[] menuIds;
    string[] menuLabels;
    MenuIsOpen@[] menuIsOpen;
    MenuToggle@[] menuToggle;

    float ClampUnit(float value) { return Math::Clamp(value, 0.0f, 1.0f); }
    float PhaseFromFrame(int frame, int maxFrame) {
        if (maxFrame <= 0) return 0.0f;
        return ClampUnit(float(frame) / float(maxFrame));
    }

    void UnregisterMenuItem(const string &in id) {
        int index = menuIds.Find(id);
        if (index < 0) return;
        menuIds.RemoveAt(index); menuLabels.RemoveAt(index);
        menuIsOpen.RemoveAt(index); menuToggle.RemoveAt(index);
    }

    void RegisterMenuItem(const string &in id, const string &in label, MenuIsOpen@ isOpen, MenuToggle@ toggle) {
        UnregisterMenuItem(id);
        menuIds.InsertLast(id); menuLabels.InsertLast(label);
        menuIsOpen.InsertLast(isOpen); menuToggle.InsertLast(toggle);
    }
}

void RenderMenu() {
    if (!UI::BeginMenu("Skillpack Demos")) return;
    for (uint i = 0; i < SkillpackDemoLib::menuIds.Length; i++) {
        bool open = SkillpackDemoLib::menuIsOpen[i]();
        if (UI::MenuItem(SkillpackDemoLib::menuLabels[i] + "###" + SkillpackDemoLib::menuIds[i], "", open)) {
            SkillpackDemoLib::menuToggle[i]();
        }
    }
    UI::EndMenu();
}
